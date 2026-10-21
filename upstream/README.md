# Upstreaming

## pmaports merge request

`0001-archos-oxygen101-new-device.patch` adds the three packages of
`../pmaports/device/testing/` to pmaports (`git am` on a current master).
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
- [ ] Regenerate this patch from the final packages:
      commit them in a pmaports clone and run `git format-patch -1`.

## Kernel

Candidates for the Linux mailing lists, from the kernel patches:

| Patch | Subsystem | Notes |
|---|---|---|
| 0002 `vtl-ct36x` touchscreen driver | input | needs a DT binding (`vtl,ct365`) |
| 0005 `rn5t618-pwrkey` | input + mfd | new MFD cell for RC5T619 |
| 0007 keep reboot mode on RC5T619 restart | mfd | small, self-contained |
| 0001/0003/0004/0006/0008 device tree | arm/rockchip | squash into one `rk3288-archos-oxygen101.dts` |
| 0001 panel timings | drm/panel | `panel-simple` DSI entry, needs a compatible |
