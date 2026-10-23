# Upstreaming

## pmaports merge request

`0001-archos-oxygen101-new-device.patch` adds the three packages of
`../pmaports/device/testing/` to pmaports:
`git am --whitespace=nowarn` on a current master. The kernel patches it
carries have context lines that start with a space and a tab; a git set to
`apply.whitespace=fix` would "fix" them and break the kernel build.

The patch resets the versions for a new package (device 1-r0, linux r0);
the local packages are at 2-r7 and r21 so the tablet keeps upgrading.
Before opening the merge request on gitlab.postmarketos.org:

- [ ] Publish `../firmware-archos-oxygen101` (a separate git repository) and
      point `url`/`source` of `firmware-archos-oxygen101/APKBUILD` to it.
      Update `_commit`, then run `pmbootstrap checksum firmware-archos-oxygen101`
      (the APKBUILD has no checksum until then).
- [ ] `pmbootstrap lint device-archos-oxygen101 linux-archos-oxygen101 firmware-archos-oxygen101`
- [ ] `pmbootstrap kconfig check linux-archos-oxygen101`
- [ ] Rebuild all three and boot the result from a fresh `pmbootstrap install`.
- [ ] Decide on the `rn5t618` patches (0005 power key, 0007 reboot mode):
      pmaports prefers patches that are on their way upstream, so send them
      to the kernel first and reference the threads in the APKBUILD.
- [ ] Create the wiki page from `../wiki/` and link it in the MR.
- [ ] `v4l-utils` in the device package's `depends` (for the OV5640 udev
      rule): reviewers may prefer it elsewhere, e.g. a kernel default or a
      libcamera change (see below).
- [ ] Regenerate this patch if the packages change: commit them in a
      pmaports clone with the versions reset, and run `git format-patch -1`.

## Kernel

Candidates for the Linux mailing lists, from the kernel patches:

| Patch | Subsystem | Notes |
|---|---|---|
| 0002 `vtl-ct36x` touchscreen driver | input | needs a DT binding (`vtl,ct365`) |
| 0005 `rn5t618-pwrkey` | input + mfd | new MFD cell for RC5T619 |
| 0007 keep reboot mode on RC5T619 restart | mfd | small, self-contained |
| 0001/0003/0004/0006/0008 device tree | arm/rockchip | squash into one `rk3288-archos-oxygen101.dts` |
| 0001 panel timings | drm/panel | `panel-simple` DSI entry, needs a compatible |
| 0009/0012 device tree | arm/rockchip | audio, IMU, camera: same squash |
| 0010 RK3288 `i2s0_clkout` `CLK_SET_RATE_PARENT` | clk/rockchip | one line |
| 0011 `rkisp1`: RK3288, low-wired parallel sensors, DMA segment size | media | split in three; RK3288 needs a DT binding compatible and an `isp` node in `rk3288.dtsi`; the data-shift handling needs discussion (`data-shift` endpoint property vs. bus-width 12) |
| 0013 `ov5640`: DVP clock floor | media | standalone; tested at 8-bit raw only |

## libcamera

The device package ships `ov5640.yaml` adapted to the board (×16 sensor
de-gamma curve, black level for the low lines, gamma 2.2). Two things are
worth reporting upstream:

- the stock `ov5640.yaml` has no `GammaOutCorrection`, so every OV5640 on
  rkisp1 gets a linear, dark picture;
- libcamera leaves the sensor's own `auto_exposure`/`gain_automatic` on,
  so two exposure loops fight. The device package turns them off with udev.
  The black level from the tuning file is deprecated in libcamera; once it
  is removed, the low-wired data needs either kernel-side handling or a
  per-board override of the sensor helper's level.
