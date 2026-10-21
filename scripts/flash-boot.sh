#!/bin/sh
# Write a boot image to the eMMC.
#   ./flash-boot.sh boot.img [boot|recovery]
# With the tablet in the Rockchip loader this uses rkdeveloptool. With pmOS
# running (TABLET reachable) it copies the image over and writes it with dd.
. "$(dirname "$0")/env.sh"
set -e
img=$1; part=${2:-boot}
case $part in
	boot) addr=0x16000 dev=/dev/mmcblk0p5 ;;
	recovery) addr=0x26000 dev=/dev/mmcblk0p6 ;;
	*) echo "partition: boot or recovery" >&2; exit 1 ;;
esac
if "$RKDEV" ld 2>/dev/null | grep -q Loader; then
	"$RKDEV" wl $addr "$img"
	"$RKDEV" rd
else
	tscp "$img" "user@$TABLET:/tmp/flash.img"
	tsudo "dd if=/tmp/flash.img of=$dev bs=1M conv=fsync && n=\$(stat -c %s /tmp/flash.img) && dd if=$dev bs=1M count=32 2>/dev/null | head -c \$n | md5sum && md5sum /tmp/flash.img"
fi
