#!/bin/sh
# Install .apk files on the running tablet and check that the device
# package's hook wrote the new kernel to the eMMC boot partition.
#   ./install-packages.sh $SHARE/apks/linux-archos-oxygen101-6.12.90-r9.apk ...
. "$(dirname "$0")/env.sh"
set -e
tscp "$@" "user@$TABLET:/tmp/"
names=""; for f in "$@"; do names="$names /tmp/$(basename "$f")"; done
tsudo "apk add --allow-untrusted $names; sync
n=\$(stat -c %s /boot/boot.img)
echo boot partition: \$(dd if=/dev/mmcblk0p5 bs=1M count=32 2>/dev/null | head -c \$n | md5sum)
echo /boot/boot.img: \$(md5sum < /boot/boot.img)"
echo "Reboot with ./reboot-mode.sh when both sums match."
