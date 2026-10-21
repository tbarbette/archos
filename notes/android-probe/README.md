# What the stock kernel sets that mainline didn't

Collected on 21 October 2026 by booting the stock Android boot image from
the `recovery` slot with a root shell added (`tools/mkrootandroid.py`, `rk
serve` behind `adb forward tcp:2323 tcp:2323`), then comparing registers
with pmOS (`tools/regdump.sh`; `regs-android.txt` and `regs-pmos.txt`).

## Chips found under Android

| Bus | Address | Chip | Notes |
|---|---|---|---|
| I²C1 | 0x68 | InvenSense MPU-6050 | WHO_AM_I 0x68, INT_PIN_CFG 0x12 (bypass on) |
| I²C1 | 0x0d | AKM AK8963 | WIA 0x48 |
| I²C2 | 0x1c | Realtek RT5640 | ID 0x10ec/0x6231; Rockchip calls it RT3224/RT3261 |
| I²C3 | 0x3c | OmniVision OV5640 | back camera, parallel (DVP), autofocus |
| I²C4 | 0x10 | UPI US5151 | ambient light, no mainline driver |

The RT5623 node in the stock DTS has no chip behind it.

## What had to change

| What | Stock | Mainline before | Effect |
|---|---|---|---|
| GPIO7_B0 | output high | input | codec LDO1_EN: the RT5640 doesn't answer without it |
| GRF_IO_VSEL audio (bit 6) | 1.8 V | 3.3 V | I²C2 and I2S pins; the codec doesn't answer at 3.3 V |
| GPIO0_B4 ("otg_drv") | output low | input | the MPU-6050 doesn't answer otherwise |
| GPIO8_A4/A5 pulls (I²C1) | pull-up | none | the MPU-6050 doesn't answer without them |
| GPIO6_B1/B2 pulls (I²C2) | pull-up | none | mirrored, not proven necessary |

Camera power, from `cam_board.xml` and the GPIO state with the camera app
open: GPIO0_C1 high = camera power, GPIO2_B7 = OV5640 power-down (active
high), GPIO2_B6 = OV2659 power-down (active high).

The internal microphone is on RT5640 IN1: with the speaker playing a 1 kHz
tone, IN1 records it (Goertzel power 2742), IN2 and IN3 don't
(`tools/audiotest.sh`).
