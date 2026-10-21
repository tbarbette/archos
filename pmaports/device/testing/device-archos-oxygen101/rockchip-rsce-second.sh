#!/bin/sh
# The legacy Rockchip U-Boot (2014.04, "rkdevelop") on this tablet does not
# use a raw DTB from the boot.img "second" section: it expects a Rockchip
# resource image (RSCE) there, holding the device tree as "rk-kernel.dtb".
# boot-deploy puts the raw DTB in "second" (deviceinfo_bootimg_dtb_second),
# this hook wraps it in a single-entry RSCE container and fixes up the header.
#
# When running on the tablet itself (kernel or initramfs upgrade), it then
# writes the image to the eMMC "boot" partition. boot-deploy cannot do that
# because the partitions come from the Rockchip parameter block, which the
# kernel only learns through blkdevparts= (no GPT labels for findfs).
#
# $1 is the path to the generated initramfs, boot.img sits next to it.
set -e

bootimg="$(dirname "$1")/boot.img"
[ -f "$bootimg" ] || exit 0

rd32() {
	od -An -tu4 -j "$2" -N4 "$1" | tr -d ' '
}

le32() {
	printf "$(printf '\\%03o\\%03o\\%03o\\%03o' \
		$(($1 & 255)) $(($1 >> 8 & 255)) $(($1 >> 16 & 255)) $(($1 >> 24 & 255)))"
}

zeros() {
	[ "$1" -gt 0 ] && head -c "$1" /dev/zero
	return 0
}

ksize=$(rd32 "$bootimg" 8)
rsize=$(rd32 "$bootimg" 16)
ssize=$(rd32 "$bootimg" 24)
page=$(rd32 "$bootimg" 36)

npages() {
	echo $((($1 + page - 1) / page))
}

soff=$(((1 + $(npages "$ksize") + $(npages "$rsize")) * page))

if [ "$ssize" -eq 0 ]; then
	echo "rockchip-rsce-second: no DTB in boot.img second section" >&2
	exit 1
fi

flash_boot() {
	# Not from pmbootstrap: only on the running tablet
	[ "$(stat -c %d:%i /)" = "$(stat -c %d:%i /proc/1/root/.)" ] || return 0
	grep -q "archos,oxygen101" /proc/device-tree/compatible 2>/dev/null || return 0

	local part name dev
	for part in /sys/block/mmcblk*/mmcblk*p*; do
		# eMMC only, never the SD card
		[ "$(cat "$part/../device/type" 2>/dev/null)" = "MMC" ] || continue
		name=$(sed -n 's/^PARTNAME=//p' "$part/uevent")
		[ "$name" = "boot" ] || [ "$name" = "recovery" ] || continue
		dev="/dev/$(basename "$part")"
		# Only replace a postmarketOS image, keep Android's boot/recovery
		dd if="$dev" bs=512 skip=0 count=2 2>/dev/null | \
			tail -c +65 | head -c 512 | grep -q "pmos_" || continue
		if [ "$(wc -c < "$bootimg")" -gt "$(blockdev --getsize64 "$dev")" ]; then
			echo "rockchip-rsce-second: boot.img does not fit in $name" >&2
			return 1
		fi
		echo "rockchip-rsce-second: writing boot.img to $name ($dev)"
		dd if="$bootimg" of="$dev" bs=1M conv=fsync 2>/dev/null
	done
}

if [ "$(dd if="$bootimg" bs=1 skip="$soff" count=4 2>/dev/null)" = "RSCE" ]; then
	flash_boot
	exit 0
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

dd if="$bootimg" of="$tmp/dtb" bs="$page" skip=$((soff / page)) 2>/dev/null
head -c "$ssize" "$tmp/dtb" > "$tmp/dtb.raw"

name="rk-kernel.dtb"
{
	# Header: magic, version, header/table/entry sizes in blocks, count
	printf 'RSCE'
	zeros 4
	printf '\001\001\001\000'
	le32 1
	zeros $((512 - 16))
	# Single entry: name, data block offset, size
	printf 'ENTR%s' "$name"
	zeros $((256 - ${#name}))
	le32 2
	le32 "$ssize"
	zeros $((512 - 4 - 256 - 8))
	cat "$tmp/dtb.raw"
	zeros $(((512 - ssize % 512) % 512))
} > "$tmp/rsce"

rsce_size=$(wc -c < "$tmp/rsce")
{
	head -c "$soff" "$bootimg"
	cat "$tmp/rsce"
	zeros $(((page - rsce_size % page) % page))
} > "$tmp/boot.img"
le32 "$rsce_size" | dd of="$tmp/boot.img" bs=1 seek=24 conv=notrunc 2>/dev/null

cat "$tmp/boot.img" > "$bootimg"

flash_boot
