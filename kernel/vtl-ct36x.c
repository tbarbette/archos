// SPDX-License-Identifier: GPL-2.0-only
/*
 * Driver for VTL CT36x (CT362/CT363/CT365/CT368/CT369) capacitive touchscreen
 * controllers, as found in some Rockchip based tablets.
 *
 * The controller firmware reports up to 10 contacts as a plain I2C read of
 * 6-byte records, signalled by a falling edge on its interrupt line:
 *
 *   byte 0: X[11:4]
 *   byte 1: Y[11:4]
 *   byte 2: X[3:0] << 4 | Y[3:0]
 *   byte 3: contact id (1..10) << 3 | status (1 = down, 2 = move, 3 = up)
 *   byte 4: area
 *   byte 5: pressure
 *
 * Unused records have X[11:4] = 0xff.
 *
 * Based on the protocol of the vendor "vtl_ts" driver.
 */

#include <linux/delay.h>
#include <linux/gpio/consumer.h>
#include <linux/i2c.h>
#include <linux/input.h>
#include <linux/input/mt.h>
#include <linux/input/touchscreen.h>
#include <linux/interrupt.h>
#include <linux/module.h>
#include <linux/of.h>
#include <linux/regulator/consumer.h>

#define CT36X_MAX_CONTACTS	10
#define CT36X_RECORD_SIZE	6
#define CT36X_STATUS_DOWN	1
#define CT36X_STATUS_MOVE	2

struct ct36x_data {
	struct i2c_client *client;
	struct input_dev *input;
	struct gpio_desc *reset_gpio;
	struct regulator *vdd;
	struct touchscreen_properties prop;
	u8 buf[CT36X_MAX_CONTACTS * CT36X_RECORD_SIZE];
};

static void ct36x_reset(struct ct36x_data *ts)
{
	if (!ts->reset_gpio)
		return;

	gpiod_set_value_cansleep(ts->reset_gpio, 1);
	msleep(50);
	gpiod_set_value_cansleep(ts->reset_gpio, 0);
	/* Firmware needs some time to start answering on its address */
	msleep(200);
}

static irqreturn_t ct36x_irq(int irq, void *dev_id)
{
	struct ct36x_data *ts = dev_id;
	struct input_dev *input = ts->input;
	int i, ret;

	ret = i2c_master_recv(ts->client, ts->buf, sizeof(ts->buf));
	if (ret != sizeof(ts->buf)) {
		dev_err_ratelimited(&ts->client->dev,
				    "failed to read contacts: %d\n", ret);
		return IRQ_HANDLED;
	}

	for (i = 0; i < CT36X_MAX_CONTACTS; i++) {
		const u8 *rec = &ts->buf[i * CT36X_RECORD_SIZE];
		unsigned int status = rec[3] & 0x07;
		unsigned int id = rec[3] >> 3;
		unsigned int x, y;

		if (rec[0] == 0xff || rec[1] == 0xff)
			continue;
		if (status != CT36X_STATUS_DOWN && status != CT36X_STATUS_MOVE)
			continue;
		if (id < 1 || id > CT36X_MAX_CONTACTS)
			continue;

		x = (rec[0] << 4) | (rec[2] >> 4);
		y = (rec[1] << 4) | (rec[2] & 0x0f);

		input_mt_slot(input, id - 1);
		input_mt_report_slot_state(input, MT_TOOL_FINGER, true);
		touchscreen_report_pos(input, &ts->prop, x, y, true);
		input_report_abs(input, ABS_MT_TOUCH_MAJOR, rec[4]);
		input_report_abs(input, ABS_MT_PRESSURE, rec[5]);
	}

	input_mt_sync_frame(input);
	input_sync(input);

	return IRQ_HANDLED;
}

static void ct36x_power_off(void *data)
{
	struct ct36x_data *ts = data;

	if (ts->reset_gpio)
		gpiod_set_value_cansleep(ts->reset_gpio, 1);
	regulator_disable(ts->vdd);
}

static int ct36x_probe(struct i2c_client *client)
{
	struct device *dev = &client->dev;
	struct ct36x_data *ts;
	struct input_dev *input;
	int error;

	if (!client->irq)
		return dev_err_probe(dev, -EINVAL, "missing interrupt\n");

	ts = devm_kzalloc(dev, sizeof(*ts), GFP_KERNEL);
	if (!ts)
		return -ENOMEM;

	ts->client = client;
	i2c_set_clientdata(client, ts);

	ts->vdd = devm_regulator_get(dev, "vdd");
	if (IS_ERR(ts->vdd))
		return dev_err_probe(dev, PTR_ERR(ts->vdd),
				     "failed to get vdd supply\n");

	ts->reset_gpio = devm_gpiod_get_optional(dev, "reset", GPIOD_OUT_HIGH);
	if (IS_ERR(ts->reset_gpio))
		return dev_err_probe(dev, PTR_ERR(ts->reset_gpio),
				     "failed to get reset gpio\n");

	error = regulator_enable(ts->vdd);
	if (error)
		return error;

	error = devm_add_action_or_reset(dev, ct36x_power_off, ts);
	if (error)
		return error;

	ct36x_reset(ts);

	error = i2c_master_recv(client, ts->buf, sizeof(ts->buf));
	if (error < 0)
		return dev_err_probe(dev, error, "controller not responding\n");

	input = devm_input_allocate_device(dev);
	if (!input)
		return -ENOMEM;

	ts->input = input;
	input->name = "VTL CT36x Touchscreen";
	input->id.bustype = BUS_I2C;

	input_set_abs_params(input, ABS_MT_POSITION_X, 0, 4095, 0, 0);
	input_set_abs_params(input, ABS_MT_POSITION_Y, 0, 4095, 0, 0);
	input_set_abs_params(input, ABS_MT_TOUCH_MAJOR, 0, 255, 0, 0);
	input_set_abs_params(input, ABS_MT_PRESSURE, 0, 255, 0, 0);
	touchscreen_parse_properties(input, true, &ts->prop);

	error = input_mt_init_slots(input, CT36X_MAX_CONTACTS,
				    INPUT_MT_DIRECT | INPUT_MT_DROP_UNUSED);
	if (error)
		return error;

	error = input_register_device(input);
	if (error)
		return error;

	error = devm_request_threaded_irq(dev, client->irq, NULL, ct36x_irq,
					  IRQF_ONESHOT, client->name, ts);
	if (error)
		return dev_err_probe(dev, error, "failed to request irq\n");

	return 0;
}

static int ct36x_suspend(struct device *dev)
{
	struct ct36x_data *ts = i2c_get_clientdata(to_i2c_client(dev));

	disable_irq(ts->client->irq);
	if (ts->reset_gpio)
		gpiod_set_value_cansleep(ts->reset_gpio, 1);

	return 0;
}

static int ct36x_resume(struct device *dev)
{
	struct ct36x_data *ts = i2c_get_clientdata(to_i2c_client(dev));

	ct36x_reset(ts);
	enable_irq(ts->client->irq);

	return 0;
}

static DEFINE_SIMPLE_DEV_PM_OPS(ct36x_pm_ops, ct36x_suspend, ct36x_resume);

static const struct of_device_id ct36x_of_match[] = {
	{ .compatible = "vtl,ct365" },
	{ }
};
MODULE_DEVICE_TABLE(of, ct36x_of_match);

static const struct i2c_device_id ct36x_id[] = {
	{ "ct365" },
	{ }
};
MODULE_DEVICE_TABLE(i2c, ct36x_id);

static struct i2c_driver ct36x_driver = {
	.driver = {
		.name = "vtl-ct36x",
		.of_match_table = ct36x_of_match,
		.pm = pm_sleep_ptr(&ct36x_pm_ops),
	},
	.probe = ct36x_probe,
	.id_table = ct36x_id,
};
module_i2c_driver(ct36x_driver);

MODULE_DESCRIPTION("VTL CT36x touchscreen driver");
MODULE_LICENSE("GPL");
