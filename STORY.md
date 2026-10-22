# Saving an Archos 101 Oxygen from the bin

*How a 2015 Android 4.4 tablet ended up running postmarketOS with mainline
Linux 6.12, Phosh and a current Firefox: one long afternoon to boot it
(20 October 2026), and a morning to make it usable (21 October).*

## The problem

The tablet is an **Archos 101 Oxygen**: a 10" 1920×1200 tablet built around a
Rockchip **RK3288** with 2 GB of RAM and 16 GB of eMMC. It shipped with
Android 4.4.4 and never got anything newer.

By 2026 it was a brick with a nice screen. Google Play no longer talks to
KitKat. The last Firefox that runs on it is 68.11 (2020) and the last Chrome
is 81. Most of the web is out of reach. The first attempt was the obvious one:
side-load the newest browser that still supports Android 4.4. Firefox 68.11
was installed with `adb` (the package manager crashed on the first try). It
works, but it's a 2020 browser with no security updates and still prevent accessing many websites because of stale certificates.

The search for a newer Android ROM went nowhere. LineageOS and CyanogenMod
never supported this tablet. The one developer who looked at it on the
ArcTablet forum in 2016 gave up because "there is no selinux kernel for that
tab". The only community ROM is a rooted 4.4.4.

So I launched Claude Opus 5.6 on it with this line : *"The tablet is unusable anyway so you can brick it if
need be. I'll throw it to the bin if you can't succeed."*

The following is entierly AI-done. I do understand what it *means* and you can judge my prompts below.

## Why postmarketOS had a chance

No Android ROM, then, but the RK3288 is one of the best-supported 32-bit ARM
chips in mainline Linux, thanks to the Chromebooks that use it
(`google-veyron-*`). postmarketOS already ships a mainline 6.12 kernel for
those Chromebooks (`linux-google-veyron`). So the SoC side was solved. The
open questions were all board-specific:

- how the stock bootloader boots a kernel, and whether it checks signatures;
- what the display, touchscreen, PMIC and WiFi are, and how they are wired;
- how to get in and out of the tablet safely without a working key combo
  for the Rockchip loader mode.

## Reconnaissance

With USB debugging enabled, Android gave up most of what was needed:

- `/proc/cpuinfo`, `dmesg` and `/sys` identified the PMIC (Ricoh RC5T619), two
  Silergy SYR82x buck converters for the CPU and GPU, a BCM43362 WiFi chip on
  SDIO (`02d0:a962`), and a touchscreen on I²C bus 4 at address `0x01`.
- `adb reboot bootloader` drops the tablet into the Rockchip **loader**
  (rockusb) mode, where `rkdeveloptool` (built natively on macOS) can read and
  write the eMMC. Docker on macOS can't reach USB, so this tool ran on the
  host while pmbootstrap ran in a privileged Linux container.
- The first 16 KiB of the eMMC holds the Rockchip **parameter** block: no GPT,
  just a kernel command line with an `mtdparts=` list
  (`boot` at 0x16000, `recovery` at 0x26000, etc.).
- The `resource` partition is a Rockchip **RSCE** container holding the boot
  logo, the charging animation and **`rk-kernel.dtb`**: the vendor device
  tree, which describes every chip and GPIO on the board.

The whole eMMC (15.8 GB) was backed up through the loader before anything
else was written.

## The signature question

The first real experiment was a one-byte change: the stock recovery image,
with one capital letter in a comment changed, written into the **boot**
partition. If the bootloader verified images, the tablet would refuse to boot
it. It booted straight into Android recovery ("No command"). The bootloader
doesn't check signatures.

It also created the first scare. With a recovery image in *both* boot slots,
every boot ended up on "No command", and none of the Volume+/Volume−/both key
combinations reached the loader. The way back was the stock recovery's
"update rkimage from external storage" menu entry. Reading Rockchip's KitKat
recovery source showed it only checks a CRC (Rockchip's CRC32,
polynomial `0x04C10DB7`), not an RSA signature. So a hand-made RKAF
`update.img` on a FAT32 microSD restored the original boot image and installed
a recovery with `adb` enabled, without touching the loader. The tool written
for that, `tools/mkrkupdate.py`, deliberately leaves out the bootloader, so the
update ends with "can't find bootloader, Failed(-2)" after the partitions are
written.

## A device tree from scratch

The vendor device tree (Rockchip 3.10 kernel) was decompiled and translated
into a mainline one, `rk3288-archos-oxygen101.dts`:

- RC5T619 regulators (`DCDC1–5`, `LDO1–10`) with the stock voltages;
- eMMC, SD card and SDIO WiFi (with its power sequence);
- the MIPI DSI panel (4 lanes, 1920×1200 at 150 MHz pixel clock) with a new
  `panel-simple` entry built from the stock timings, plus PWM backlight;
- USB OTG in peripheral mode for pmOS's USB network and SSH;
- the lid hall sensor.

The kernel package `linux-archos-oxygen101` is a copy of the veyron one with
this device tree and a patch for the panel.

## Why it didn't boot, and the fix

The first pmOS image went into the **recovery** partition, so Android stayed
the default boot and `adb reboot recovery` became the way into pmOS. It showed
nothing. No USB network, no SSH, just a dead screen.

The answer was in Rockchip's U-Boot source (`rkdevelop` branch) and in the
parameter block:

- U-Boot **ignores** the load addresses in the Android boot image header. The
  kernel always goes to `0x02000000`, the ramdisk to a buffer U-Boot picks.
- It takes the **device tree from the "second" section** of the boot image,
  which must be an RSCE container with `rk-kernel.dtb` inside, falling back to
  the `resource` partition. It then patches `memory`, `initrd-start/end` and
  `bootargs` itself.
- `bootargs` come from the **parameter block**, not from the boot image
  header.

The first image carried a device tree appended to the zImage, with
`/chosen/linux,initrd-start` pointing where *I* had put the ramdisk. The
kernel picked the appended DTB, looked for its initramfs in the wrong place
and died before any output. Disabling `ARM_APPENDED_DTB`, putting the DTB in
the RSCE "second" section and appending pmOS's options with
`CONFIG_CMDLINE_EXTEND` fixed it. The next boot came up as a USB network
device, SSH answered, and Phosh was running on the panel.

## Touch: writing a driver

The touchscreen is a **VTL CT36x** (CT365): a controller with a vendor driver
in Rockchip's 3.10 tree but nothing in mainline. Before writing a driver, the
protocol was confirmed from userspace on the running pmOS:

- `i2cdetect` saw nothing at `0x01` until the chip was **hardware-reset**
  through GPIO7_A5 (low for 50 ms, then 200 ms for the firmware to start).
  The vendor's software reset (writing `00 5a` to `0x7f`) made it vanish
  instead.
- A raw I²C read of 60 bytes returns 10 records of 6 bytes:
  `X[11:4], Y[11:4], X[3:0]<<4|Y[3:0], id<<3|status, area, pressure`.
- The owner touched the corners and swiped while a script polled the chip.
  The coordinates map 1:1 to the 1920×1200 panel, with no swap or inversion.

The resulting driver, `drivers/input/touchscreen/vtl-ct36x.c`, is about 230
lines: threaded IRQ on the falling edge of GPIO7_A6, multitouch type B with
10 slots, standard `touchscreen-*` properties, reset GPIO and power handling.
It worked on its first boot. The first swipe arrived at 60 Hz with clean
release events.

## WiFi

The BCM43362 is supported by `brcmfmac` with firmware from linux-firmware,
but it needs the board's NVRAM (calibration) file. That came from the Android
system partition (`/system/etc/firmware/nvram_RK901.txt`), installed as
`brcmfmac43362-sdio.archos,oxygen101.txt`. The chip loaded firmware 5.90.254
and scanned the neighbourhood.

## Making it stick

The tablet then got the comforts of a normal device:

- **Power and volume keys.** The volume keys share SARADC channel 1 (≈0 V
  for up, ≈0.3 V for down), which is mainline's `adc-keys`. The power key was
  described as a plain GPIO (GPIO0_A5, active low). That turned out to be
  wrong (see the next chapter).
- **Boot pmOS by default.** The pmOS image is written into the `boot`
  partition. If it fails to load, U-Boot falls back to `recovery`, so a broken
  kernel can't brick the tablet.
- **Reboot modes.** The mainline `syscon-reboot-mode` values for RK3288 match
  what this old U-Boot expects (`0x5242C303` recovery, `0x5242C309`
  fastboot, `0x5242C301` loader), so `reboot recovery` and `reboot loader`
  should have worked from pmOS. They didn't (see the next chapter).
- **The postmarketOS way.** Instead of hand-built images, the device package
  now uses boot-deploy: `deviceinfo_bootimg_dtb_second` puts the DTB in
  "second", and a `mkinitfs_postprocess` hook (`rockchip-rsce-second.sh`)
  wraps it into the RSCE container U-Boot wants. On the tablet, the same hook
  writes every newly generated image to the eMMC `boot` partition. It finds
  that partition through a `blkdevparts=` copy of the parameter table in the
  kernel command line, because boot-deploy's own flashing needs GPT labels.
  So `apk upgrade` keeps the kernel on flash and the modules on disk in sync.

## The morning after: from "it boots" to "it's usable"

The owner (that's how Claude calls me :) ) used the tablet overnight and came back with three complaints:
the power button didn't wake the screen, the battery always read 0%, and
everything was slow. *"Is it just old or something is hooking up the CPU?
And is the GPU support enabled?"*

### Finding the tablet

The tablet was no longer on USB but on a lab WiFi network, and Phosh's WiFi
panel didn't show its address (note here how Claude went around the fact I forgot the cable at home...). The access point's station list gave its MAC
address; a ping sweep and the ARP table gave its IP. From then on all the
work went over SSH on WiFi. The owner also unplugged the USB cable, so the
tablet was on the wall charger only.

### Battery at 0%, and a tablet that switched itself off

NDLR : I had not even noticed the tablet was turning off by itself...

The mainline `rn5t618-power` driver supports the RC5T619 charger and fuel
gauge, and it was enabled. But it depends on the PMIC's ADC driver, which was
not, so it waited for it forever and no battery was ever registered.

Enabling the ADC fixed the reading, and created a new problem: the tablet
powered off a minute after every boot. The battery really was at about 2%,
and UPower did what it is supposed to do at its critical level. Its critical
action was set to "ignore" for the time it took to understand why the battery
was empty in the first place.

The tablet was discharging while plugged in. At power-on the RC5T619 limits
the adapter input to **500 mA**, less than the tablet draws with the screen
on. Android raised it; mainline Linux leaves it alone. Writing 2 A (the stock
adapter's rating) to `input_current_limit` and 1.5 A to the charge limit took
the battery current from −169 mA to +1.28 A. A udev rule in the device
package now does that at boot, and UPower got its defaults back.

Three hours later, while testing the new scripts, the tablet was
discharging again at 80%: the limit was back at 500 mA. The PMIC restores
its default when it re-detects the adapter. The charger interrupt makes the
kernel send a `change` uevent, so the rule now applies the limits on every
`change` too.

### The power key wasn't a GPIO

Nothing happened on GPIO0_A5 when the key was pressed. The PMIC's registers
told the real story: the "power on" interrupt bit (PWRIRQ bit 0) was latched.
The key is wired to the RC5T619's **PWRON pin**, and the PMIC reports it
through its system interrupt. Mainline has no power-key driver for this PMIC.

The new driver, `rn5t618-pwrkey`, is about 120 lines. It asks for an
interrupt on both edges, clears the latch and reports `KEY_POWER` from the
key-level bit (PWRMON bit 0). The first version registered nothing: the MFD
core adds its child devices *before* it sets up the interrupt chip, so the
driver now defers its probe until the interrupt chip exists. The owner
pressed the key: *"I pressed it and it works."*

### Why it was slow

Nothing was hogging the CPU. Two shortcuts from the first day were the cause:

- **The CPU was stuck at 600 MHz.** The CPU supply, a Silergy SYR827 on I²C
  bus 0, wasn't described, so the device tree had dropped the CPU's
  operating points. The SYR827 (CPU) and SYR828 (GPU) are the same parts,
  at the same addresses, as on the veyron Chromebooks, which the `fan53555`
  driver already supports. With them described, the CPU scales from 126 MHz to
  1.6 GHz. Reading the regulator back over I²C confirmed the voltages
  (0.9 V at 600 MHz, 1.35 V at 1.6 GHz). Four cores at 1.6 GHz under
  `stress` stayed stable at 50 °C.
- **The GPU was off.** Phosh's compositor fell back to pixman, so every frame
  was drawn by the CPU. With `vdd_gpu` described, the Mali-T764 runs on
  Panfrost and phoc reports `EGL driver name: panfrost`, OpenGL ES 3.1
  (Mesa 26.1.6).

### A self-inflicted eMMC bug

Since the second kernel build, the eMMC threw I/O errors seven seconds into
every boot. The root filesystem is on the microSD, so nothing seemed broken,
but the hook that writes new kernels to the eMMC `boot` partition failed
silently. Kernel updates weren't reaching flash.

The device tree told the io-domain driver that the flash pins ran at 3.3 V.
The eMMC runs at 1.8 V, so the driver switched the pins to the wrong
voltage as soon as it loaded. Writing the right value into the GRF
(`GRF_IO_VSEL`) by hand and rebinding the MMC driver brought the eMMC back,
which confirmed it. The fix is one line in the device tree.

### Reboot into recovery

`systemctl reboot --reboot-argument=recovery` came back up from `boot`. The
reboot-mode flag was written correctly, but U-Boot never saw it. The
RC5T619's restart handler takes priority because the PMIC is the system power
controller, and it restarts the board by power-cycling it through the PMIC.
That clears the SoC register that holds the flag.

A small patch skips the PMIC restart when a reboot command is given, and
the SoC's warm reset keeps the flag. U-Boot acknowledges the flag by rewriting
it (`0xC3524203` for recovery), and the tablet came up from `recovery`.
A plain `reboot` still does the full PMIC power cycle.

## The afternoon: sound and sensors

*"Try to add support for accelerometers, camera and audio."*

The stock device tree promised an MPU-6050 motion sensor and an RT3261 codec,
but under mainline the MPU didn't answer on I²C and the codec's bus was
empty. The supplies all matched the stock ones, so something the stock
kernel did wasn't written in its device tree.

### Asking the stock kernel

The way to find out was to run the stock kernel again and look. The day-one
debug recovery never brought up adb, so this time the stock **Android** boot
image went into the `recovery` slot, with its ramdisk edited: SELinux
permissive and a root shell service. The service is a 121-line static
helper (`tools/rk.c`) that also reads physical memory and talks I²C, reached
from the Mac through `adb forward`. Android booted from `recovery`, every
vendor driver bound, and the I²C scan showed the MPU at 0x68 and the codec at
0x1c.

Dumping every GPIO, pin-mux and pull register under both kernels and
diffing them gave a short list, and testing each entry live on pmOS settled
it:

- the codec needs **GPIO7_B0** high (its LDO1 enable; the stock DTS calls the
  pin "3G modem power") **and** the audio IO domain at **1.8 V**, the same
  kind of mistake as the eMMC one;
- the MPU needs **GPIO0_B4** low (called `otg_drv` in the stock DTS) **and**
  the SoC's internal **pull-ups** on I²C1.

The ID registers did the rest. The "RT3224/RT3261" reports Realtek's RT5640
ID, so mainline's `rt5640` driver works as is. The MPU's bypass bit is set,
with an AK8963 magnetometer next to it. Opening the camera app made the HAL
power up an **OV5640** on I²C3.

### Getting sound out

With the device tree fixed, the card came up and a hand-run sequence
played a tone on the speaker. To find the microphone, the speaker played a
1 kHz tone while each codec input recorded, and a Goertzel filter measured
the tone: IN1 heard it, IN2 and IN3 didn't. The owner confirmed from the
other side: *"I heard a bip bip!"*

Two more fixes made it work in the desktop:

- **A clock flag.** The codec asks for its master clock to change with the
  sample rate. On RK3288 that clock output can't pass the request on to the
  fractional divider behind it, so moving from 48 kHz to 44.1 kHz failed
  with `-EINVAL`. One flag (`CLK_SET_RATE_PARENT`, as RK3399 already has)
  fixed it.
- **A UCM profile.** PulseAudio needs to know the codec's paths. Ubuntu's
  Bay Trail tablets use the same codec, so the profile reuses their RT5640
  sequences, adds the jack name simple-audio-card uses, and pins both
  directions to 48 kHz because playback and capture share one I²S clock.

The final check went through PulseAudio itself: playing on the speaker
while recording from the microphone, the tone shows up exactly when it is
played. *"One longer bip?"* asked the owner, and then: *"Should I tell you
or you're toying with me?"*

### Sensors and camera

The MPU-6050 and the AK8963 came up with mainline's IIO drivers, and
`iio-sensor-proxy` picked up the accelerometer. Screen rotation needed a
mount matrix. I tried one live with a udev rule, and the owner reported the
Y axis reversed ("if I look at my screen vertical it becomes flipped
vertically"). The second try was right, and it went into the device tree
(r13).

The camera looked like it stopped at the SoC. Mainline has an OV5640 driver,
but no driver for RK3288's camera input: `rkisp1` knows RK3399, PX30 and
i.MX8MP only. That turned out to be the smaller problem.

## The camera

*"Go for the camera !"* That was the evening of the second day. It took
the night and eight kernel builds (r14–r21).

### The ISP is already in mainline, under another name

RK3288's camera block is an ISP of the same generation (V10) as RK3399's,
which `rkisp1` drives. Adding it took a compatible string, its clocks
(including a second core clock, `sclk_isp_jpe`, that I left off in the first
builds) and leaving out the MIPI receiver, which needs a D-PHY driver this
board doesn't use. The OV5640 sits on a parallel (DVP) bus. The device tree
got the ISP, its IOMMU, the sensor on I2C3, and the 2.8 V camera supply that
the stock kernel calls "pwen".

The first capture worked in the plumbing sense: frames arrived, no data lost.
The colour-bar test pattern came through with the right hues. Real frames
were nearly flat, and every input mode of the ISP gave the same picture.

### The bus is wired to the wrong end

The ISP's parallel input is MSB aligned: an 8-bit sensor is read on the top
8 of its 12 data lines. On this board the OV5640's 8 lines go to D7–D0, the
bottom ones. I found it by sampling the GPIO input register of the camera
pads while streaming and seeing which lines toggled (`tools/camera/padsample.py`,
`padhist.py`), then muxing lines off one at a time.

The fix reads the full 12-bit bus with the four unused top lines at zero, so
the 8 real bits land as a value 16 times too small. The ISP's sensor de-gamma
stage, a 17-point curve, scales them back by 16 by default. Userspace
parameters can still replace that curve.

The colour bars had been no help here. Each bar is all ones or all zeros
per channel, so any bit order shows the same colours. OV5640's *gradual*
bars (register 0x503d = 0x88, written while streaming) are a ramp, and they
proved the bit order right.

### Is the camera even alive?

Real frames were still featureless: the same flat field whether the tablet
lay on the table or stood facing the room, with gain only amplifying an
offset. Before going further I asked whether the camera had ever worked. The
owner didn't know, so I rebooted into the stock Android (still in the
`recovery` slot, rooted), and they opened the Camera app. It showed a
picture. The hardware was fine.

With Android previewing, I dumped every OV5640 register block over I2C
(`notes/android-probe/ov5640-android-preview.txt`) and compared it with the
same dump under pmOS (`ov5640-pmos-lowclock.txt`).

### The clock was too slow

Mainline's `ov5640` computes its PLL from the pixel rate the mode needs.
For 8-bit raw at 1280×720 and 15 fps, that's a system clock of about 84 MHz.
At that rate the sensor's black level calibration reads garbage: its result
registers (0x402c–0x4033) sit at 0x1ff8 instead of around 0x0700. Every pixel
is then pulled to black until the gain is high enough to clip, and auto
exposure hunts. At 30 fps (170 MHz) the same mode showed the room.

Patch 0013 keeps the parallel clock above 40 MHz: for slow modes the PLL
runs at an integer multiple of the needed rate and the frame gets taller
(VTS) by the same factor. The frame rate stays the one requested, and
longer exposures become possible as a bonus. At 15 fps the calibration then
reads 0x05b5 and exposure is stable.

### libcamera and the 64 KiB segments

The raw pipeline worked with `v4l2-ctl`. libcamera, which Snapshot (the
GNOME camera app) uses, failed with "contiguous chunk is too small". It
allocates frames as dmabufs and imports them into the ISP. On 32-bit ARM the
ISP goes through the legacy ARM IOMMU code, which splits a mapping into
chunks of the device's maximum segment size (64 KiB by default) placed
anywhere in its address space. `vb2-dma-contig` then refuses the buffer. One
line in the ISP's probe, `dma_set_max_seg_size(dev, UINT_MAX)`, fixed it.

On the way I also enabled the DMA-BUF heaps (CMA, 128 MB) and gave the
`video` group access to them with a udev rule. The default CMA heap is
called `reserved`, not `linux,cma`, which cost a rebuild.

With libcamera 0.7 and its `ov5640.yaml` tuning, Snapshot showed a preview
and took photos. *"It works! Just mirrored horizontally."* The sensor isn't
mirrored, as the raw frames match Android's. Snapshot mirrors the preview of
any camera not known to face backwards, so the device tree now says so:
`orientation = <1>` (back), `rotation = <0>`.

Every test frame from that night shows the owner's home. None of them is in
the repository.

## What it took

- One stock U-Boot left untouched; nothing was ever written to the loader.
- About six hours on the first day, from "find me a browser" to Phosh with
  touch and WiFi, with the tablet on a USB cable the whole time. The owner's
  part was a few minutes of hands-on work: replugging, picking a recovery menu
  entry, moving the microSD card, and touching the corners.
- About four hours on the second day, entirely over SSH on WiFi, to fix the
  power key, the battery and charging, the CPU and GPU, the eMMC and the
  reboot modes.
- A night for the camera, mostly over WiFi, with one trip into Android.
- Twenty-two kernel package builds (r0–r21) and thirteen kernel patches: the
  device tree, the panel, the keys, the io-domains and touch supply, the
  power-key driver, the eMMC voltage fix, reboot-mode preservation, the
  CPU/GPU supplies, audio and motion sensors, an RK3288 clock flag, RK3288
  and low-wired parallel sensors in `rkisp1`, the camera device tree, and the
  OV5640 clock floor. Two new input drivers (touchscreen, power key), one
  boot-deploy hook, a few udev rules, and small Python tools for Rockchip
  image formats, register poking and raw frames. About 540 shell commands on the Mac, all in
  `scripts/history/commands.md`.

## Still to do

- Headphone and headset mic test.
- Camera: libcamera tuning for this module (a backlit room comes out dark),
  and the front camera (OV2659).
- USB networking doesn't always come back after a reboot; WiFi does.
- The second USB host controller (`dwc2` at `ff540000`) times out on reset.
- Light sensor (US5151) driver; test the lid sensor.
- Upstreaming: the touchscreen and power-key drivers, the RC5T619 patches,
  the `rkisp1` and `ov5640` patches and the device tree to the kernel, and
  the device to pmaports.

## Appendix: the owner's prompts

The whole port was driven by these messages, in order (lightly trimmed; short
acknowledgements like "Ok now" and "done" left out).

**13 October**

1. *"Attached to USB is an old tablet. Force install a recent browser apk
   (Firefox or chrome) as I can't even connect to playstore anymore and there
   is no newer rom"* → Firefox 68.11, the last version for Android 4.4,
   side-loaded with `adb`.
2. *"Then, can you find a newer (maybe AOSP or similar hobbyist) ROM?"* → none
   exists.

**20 October**

3. *"Try to find a postmarket OS version to install on the tablet, I guess one
   with the same SOC. The tablet is unusable anyway so you can brick it if
   need be. I'll throw it to the bin if you can't succeed…"* → the port.
4. *"It's plugged in but the mac does not detect. A permission problem?"* →
   not a permission problem: the tablet wasn't on the USB bus at all; it
   appeared after replugging.
5. *"Will you still be able to access the tablet and build a driver? If you
   reboot without even trying to enable an untested reverse engineered driver
   I'll be stuck, no?"* → the plan changed to keep Android bootable, back up
   the whole eMMC first, and do driver work over SSH on USB.
6. *"It says 'no command'"*, *"Whatever I do I only get to 'no command'"* → the
   first scare: both boot slots held a recovery image and no key combo reached
   the loader.
7. *"Can't I just select 'flash from adb' and you deal with it?"* → no: adb
   sideload checks Archos's release key. Instead, an unsigned `update.img` on
   microSD.
8. *"Nope. I put the SD in this mac"* and *"It said … E:can't find bootloader
   Failed(-2) update failed"* → expected: the partitions were written and the
   loader deliberately left out. The tablet was back.
9. *"Rebooted on android now"* → back to the boot investigation and the RSCE
   "second" section fix.
10. *"done"* (the corner-touching session) → the touchscreen protocol and the
    `vtl-ct36x` driver.
11. *"screen is black"* and *"I could type a pin but it's wrong, what is the
    correct one?"* → the PIN is 147147; autologin into Phosh.
12. *"Make it reboot always to pm and then fix buttons"* → pmOS in `boot`,
    `recovery` as fallback, key nodes in the device tree.
13. *"Move all important files into ~/workspace/archos/ write a story of this
    rewrite. Prepare stuff to publish online the postmarket way and a useable
    ROM in the postmarket way so someone else can try use it."* → this
    folder, this story, the pmaports packages and the boot-deploy hook.

**21 October**

14. *"Did you flash the version with button support? I think right now the
    screen is off but the button does not wake it up. Also the battery seems
    to be always 0%"* → the ADC dependency, then the charger limit.
15. *"The volume is working but the power I don't think so"* → the key is on
    the PMIC's PWRON pin; the `rn5t618-pwrkey` driver.
16. *"Also, how can I connect to SSH like you"* → `ssh user@<tablet-ip>`,
    password 147147 (or `user@172.16.42.1` over USB).
17. *"Look at the same time why the tablet is so slow. Is it just old or
    something is hooking up the CPU? And is the GPU support enabled?"* → CPU
    DVFS and Panfrost.
18. *"The tablet is connected on [machine]'s wifi. Can you find its address? the
    postmarket wifi button leads to nothing, I can't see details"* → found
    through the access point's station list.
19. *"There was both cables. I removed the USB so now it's only the wall
    plug"* → the charger input limit, found because the battery still drained.
20. *"What is the ssh command to login?"* → as above. --> Yeah, sorry...
21. *"I pressed it and it works"* → the power key.
22. *"Update the repo with the current state and update the story with a
    summary of all my prompts"* → this appendix, a git repository for this
    folder, the release image and the pmaports patch in `upstream/`.
23. *"Add in the archos folder in a scripts folder all the commands you tried
    on my mac such as 'is the device on wifi?' etc."* → `scripts/`, and the
    full log in `scripts/history/commands.md`. Testing the scripts found the
    charger limit regression.
24. *"Also, how do I change the user password so SSH is not open?"* →
    `passwd` on the tablet, or `scripts/secure-ssh.sh` (`passwd`,
    `keys-only`, `off`). --> I did it, no need to try 147147 :)
25. *"Try to add support for accelerometers, camera and audio"* → the rooted
    stock Android, the register diff, the RT5640 and MPU-6050 device tree,
    the clock flag and the UCM profile.
26. *"The problem is I have some USB cables that are power only. Is the
    tablet on the macos list now? Or should I try another cable."* → it
    was; the cable carries data.
27. *"I heard a bip bip!"*, *"One longer bip?"*, *"Should I tell you or
    you're toying with me?"* → the speaker and loopback tests.
28. *"The Y axis of the gyroscope is reversed. If I look at my screen
    vertical it becomes flipped vertically"* → a second mount matrix, then
    *"Good now. Wait before updating the kernel though. We'll batch with
    something else."* → r13 built and held back.
29. *"Why don't I have anything when I hit wifi settings?"*, *"Launch
    again"*, *"Nope"* → the Settings app missed `XDG_CURRENT_DESKTOP`; still
    to confirm.
30. *"Go for the camera !"* → the camera chapter. The owner gave me the new
    sudo password (kept in an environment variable, never in a file).
31. *"I was on the normal pm as far as I can tell. Rebooted now and on PM"*,
    *"It's holding vertical now"* → the flat frames weren't the table.
32. *"I don't know indeed, you can reboot to android"* → the camera works in
    Android, and the register dump that found the clock.
33. *"It works! Just mirrored horizontally."* → `orientation = <1>`.
34. *"free my CPU, i need to work right now"*, then *"Ok continue, but using
    low CPU priority"* → the last build ran on 3 cores at nice 19.
