# Scripts

The commands used on the Mac during the port, turned into reusable scripts.
They read their settings from `env.sh` (`TABLET` address, `TABLET_PW`,
`RKDEV`, `SHARE`), so `TABLET=192.168.1.42 ./status.sh` works on WiFi.
Every command actually run, in order, is in
[`history/commands.md`](history/commands.md).

| Question | Script |
|---|---|
| Is the tablet there? On USB, in the loader, on WiFi? What's its address? | `find-tablet.sh` |
| How do I log in? | `ssh.sh` (= `ssh user@$TABLET`, password 147147) |
| Is it back up after a reboot? | `wait-for-tablet.sh` |
| Why is it slow? Is the GPU on? Is it charging? | `status.sh` |
| How do I change the password, or close SSH? | `secure-ssh.sh passwd`, `keys-only`, `off` |
| Reboot into recovery or the Rockchip loader | `reboot-mode.sh recovery` / `loader` |
| Back up the eMMC | `backup-emmc.sh [full]` (tablet in the loader) |
| Write a boot image to `boot` or `recovery` | `flash-boot.sh boot.img [boot\|recovery]` |
| Get `rkdeveloptool` on macOS | `build-rkdeveloptool.sh` |
| Set up pmbootstrap on macOS | `pmbootstrap-container.sh` |
| Rebuild the kernel or device package | `build-packages.sh linux device` |
| Install new packages on the tablet | `install-packages.sh *.apk` |
| Build the downloadable microSD image | `make-sd-image.sh` |

Lower-level tools (boot image and update.img packers, register pokers, touch
probes) are in [`../tools`](../tools).
