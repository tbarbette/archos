# postmarketOS on the Archos 101 Oxygen (`archos-oxygen101`)

Mainline Linux 6.12 + postmarketOS (Phosh, Firefox ESR) for the Archos 101
Oxygen tablet (Rockchip RK3288, 2015, stock Android 4.4.4). The stock
bootloader is kept; postmarketOS lives on a microSD card and its kernel in
the eMMC `boot` (and optionally `recovery`) partition.

See [STORY.md](STORY.md) for how this port came to be.

## Status

| Component | Status | Notes |
|---|---|---|
| Boot (stock U-Boot) | ✅ | boot.img with DTB in an RSCE "second" section |
| Display (MIPI DSI 1920×1200) | ✅ | `panel-simple` entry, PWM backlight |
| Touchscreen (VTL CT365) | ✅ | new driver `vtl-ct36x`, 10 points |
| WiFi (BCM43362) | ✅ | `brcmfmac` + stock NVRAM (`firmware-archos-oxygen101`) |
| USB OTG (gadget) | ✅ | USB network + SSH |
| microSD, eMMC | ✅ | rootfs on microSD |
| Power key | ✅ | PMIC PWRON pin, new driver `rn5t618-pwrkey` |
| Volume keys | ✅ | `adc-keys` (SARADC ch1) |
| Battery, charging | ✅ | `rn5t618-power`; udev raises the 500 mA limits to 2 A (adapter) and 1.4 A (USB charger) |
| CPU DVFS (126 MHz–1.6 GHz) | ✅ | SYR827 `vdd_cpu` |
| GPU (Mali-T764, Panfrost) | ✅ | SYR828 `vdd_gpu`; Phosh renders with GLES |
| Reboot to recovery/loader | ✅ | `syscon-reboot-mode`; PMIC re-power skipped for mode reboots |
| Audio: speaker, internal mic | ✅ | RT5640 (`rt5640` + `simple-audio-card`), UCM profile in the device package |
| Audio: headphones | 🧪 | jack sense on GPIO7_A7 |
| Accelerometer, gyroscope (MPU-6050) | ✅ | `inv_mpu6050` with mount matrix; screen rotation works |
| Magnetometer (AK8963) | ✅ | `ak8975` |
| Lid (hall sensor) | 🧪 | `SW_LID` on GPIO0_A6 |
| Back camera (OV5640, parallel) | ✅ | `rkisp1` with RK3288 support + `ov5640` clock fix; libcamera (tuning file in the device package), Snapshot |
| Front camera (OV2659) | ❌ | held in power-down; shares the parallel bus |
| Ambient light (US5151) | ❌ | no mainline driver |
| USB host (`dwc2` ff540000) | ❌ | soft reset timeout |

✅ tested, 🧪 in the image but not tested yet, ❌ not working.

## Layout of this folder

| Path | What |
|---|---|
| `pmaports/device/testing/` | the three packages to submit to pmaports: `device-`, `linux-`, `firmware-archos-oxygen101` |
| `firmware-archos-oxygen101/` | separate git repo with the WiFi NVRAM, to publish (the firmware package downloads from it) |
| `kernel/` | the device tree and touchscreen driver as plain files (also in the kernel patches) |
| `scripts/` | the commands used on the Mac as reusable scripts (find the tablet, status, flash, build, secure SSH), and the full command log |
| `tools/` | `mkrkboot.py` (Rockchip boot.img), `mkrkupdate.py` (RKAF update.img / RK CRC32), register and touch debug scripts, `camera/` capture and OV5640 register-dump scripts |
| `release/` | prebuilt images (see below; not in git, published as release files) |
| `wiki/` | draft page for wiki.postmarketos.org |
| `upstream/` | pmaports merge request patch and checklist |
| `notes/` | stock DTS, parameter block, Rockchip U-Boot source excerpts, vendor VTL driver, `android-probe/` (what the stock kernel sets) |
| `backup/` | **private**: full eMMC backup of this tablet (contains the owner's Android data, never publish) |

## Installing

**Read this first.** This replaces Android's kernel in the `boot` partition.
Android will no longer start unless you restore `boot` (see *Going back*).
Nothing touches the bootloader, so the tablet can always be recovered over
USB. Make a backup (step 2), it costs 10 minutes.

You need: the tablet with USB debugging enabled in Android, a microSD card
(4 GB or more), a computer with `adb`, `rkdeveloptool` and `xz`.

1. **Write the system to the microSD card** (replace `sdX`):

   ```sh
   xz -dc archos-oxygen101-phosh.img.xz | sudo dd of=/dev/sdX bs=4M conv=fsync
   ```

   Put the card in the tablet. On first boot the root partition grows to the
   whole card.

2. **Enter the Rockchip loader** from Android and back up the eMMC:

   ```sh
   adb reboot bootloader
   rkdeveloptool ld                       # shows "Loader"
   rkdeveloptool rl 0 0x50000 emmc-head.bin   # parameter, loader, boot, recovery
   ```

   (A full backup is `rkdeveloptool rl 0 $(( 31252480 )) emmc-full.bin`,
   16 GB.)

3. **Write the kernel** to the `boot` partition and reboot:

   ```sh
   rkdeveloptool wl 0x16000 boot.img
   rkdeveloptool rd
   ```

   `rkdeveloptool` addresses are relative to the parameter block: `boot` is
   at 0x16000, `recovery` at 0x26000 (see `notes/parameter.txt`).

The tablet boots into Phosh. User `user`, PIN/password **147147**. SSH is
open with that password on USB and WiFi: change it with `passwd` (it is also
the unlock PIN, so use digits), or see `scripts/secure-ssh.sh`.

### Dual boot instead

Write `boot.img` to **recovery** (`rkdeveloptool wl 0x26000 boot.img`)
and leave `boot` alone. Android stays the default; `adb reboot recovery`
starts postmarketOS, and a cold boot goes back to Android. From pmOS,
`sudo systemctl reboot --reboot-argument=recovery` boots it again.

### Updates

`apk upgrade` regenerates the boot image; the device package's hook writes it
to whichever of `boot`/`recovery` already holds a postmarketOS image
(identified by `pmos_` in its header). If a new image fails to load, U-Boot
falls back to the `recovery` partition.

### Going back to Android

```sh
# from pmOS: sudo systemctl reboot --reboot-argument=loader
# from Android: adb reboot bootloader
rkdeveloptool wl 0x16000 boot-android.img   # the stock boot partition from your backup
rkdeveloptool rd
```

`boot-android.img` is `dd if=emmc-head.bin bs=512 skip=$((0x18000)) count=$((0x10000))`
(physical sector = parameter-relative sector + 0x2000).

## Building it yourself

```sh
pmbootstrap init                  # device: archos-oxygen101, UI: phosh
cp -r pmaports/device/testing/* "$(pmbootstrap config aports)"/device/testing/
pmbootstrap checksum firmware-archos-oxygen101 device-archos-oxygen101 linux-archos-oxygen101
pmbootstrap install --split       # or: pmbootstrap install --sdcard=/dev/sdX
pmbootstrap export                # boot.img is in the export folder
```

Until `firmware-archos-oxygen101` is published, place the tarball produced
by `git -C firmware-archos-oxygen101 archive --prefix=firmware-archos-oxygen101-<commit>/ -o <pmbootstrap work>/cache_distfiles/firmware-archos-oxygen101-<commit>.tar.gz <commit>`
in pmbootstrap's distfiles cache.

## How booting works

The stock loader is Rockchip's U-Boot 2014.04 (`rkdevelop`). For both
`boot` and `recovery` it:

- ignores the load addresses in the Android image header (kernel at
  `0x02000000`, ramdisk in its own buffer);
- loads the device tree from the "second" section, which must be a Rockchip
  RSCE resource image containing `rk-kernel.dtb`, and fixes up `memory`,
  `initrd-*` and `bootargs` in it;
- takes `bootargs` from the parameter block, not from the image header, so
  the kernel appends its own options (`CONFIG_CMDLINE_EXTEND`), including a
  `blkdevparts=` copy of the partition table;
- falls back to `recovery` if `boot` can't be loaded, and to `backup` after
  that.

It doesn't check signatures. `deviceinfo_bootimg_dtb_second` plus
`rockchip-rsce-second.sh` (a `mkinitfs_postprocess` hook) produce that format
from standard boot-deploy output.

## The owner's tablet, as left

- `boot`: postmarketOS (kernel r21, device package 2-r7), with autologin
  into Phosh (`/etc/phrog/greetd-config.toml`, `[initial_session]`).
- `recovery`: still the **rooted stock Android** boot image used for the
  register comparisons, with a root shell service (`rk serve`, port 2323,
  reachable through `adb forward`). Replace it with the pmOS `boot.img`
  (`rkdeveloptool wl 0x26000 boot.img`) or the original recovery from the
  backup.
- Test leftovers in `/home/user`: `rk/`, `*.sh`, `ov5640-archos.yaml`, and
  raw camera captures (`*.yuv`, `raw.bin`) that show the room. Delete them
  with `rm -rf ~/rk ~/*.yuv ~/raw.bin ~/ov*.txt ~/ov5640-archos.yaml
  ~/bayertest.sh ~/ovdump*.sh ~/camstat.sh ~/camab.sh`.
- USB networking may not come back after a reboot; SSH works over WiFi.

