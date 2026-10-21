#!/bin/sh
# Back up the eMMC through the Rockchip loader. Get there with
# "adb reboot bootloader" from Android or ./reboot-mode.sh loader from pmOS.
#   emmc-head.bin: parameter, loader, resource, kernel, boot, recovery,
#                  backup (sectors 0-0x50000, 160 MB)
#   emmc-rest.bin: everything after (system, cache, userdata, ~15 GB),
#                  only with "full"
# Addresses are relative to the parameter block (physical = +0x2000).
. "$(dirname "$0")/env.sh"
set -e
out=${OUT:-backup}; mkdir -p "$out"
"$RKDEV" ld
"$RKDEV" rl 0 0x50000 "$out/emmc-head.bin"
# boot (0x16000) and recovery (0x26000) on their own, for easy restores
dd if="$out/emmc-head.bin" of="$out/boot.img" bs=512 skip=$((0x18000)) count=$((0x10000))
dd if="$out/emmc-head.bin" of="$out/recovery.img" bs=512 skip=$((0x28000)) count=$((0x10000))
if [ "$1" = full ]; then
	# 31252480 sectors is the size of this tablet's 16 GB eMMC
	"$RKDEV" rl 0x50000 $((31252480 - 0x50000)) "$out/emmc-rest.bin"
fi
