#!/bin/sh
# Build the release microSD image and boot.img in the container, without
# your SSH keys, into $SHARE/release.
# pmbootstrap's single-image mode needs loop partitions, which Docker Desktop
# doesn't create, so the boot and root images are built separately and
# assembled with sfdisk + dd.
. "$(dirname "$0")/env.sh"
set -e
docker exec -u pmos "$PMOS_CONTAINER" sh -c "cd; pmbootstrap config ssh_keys False; pmbootstrap -y install --split --password '$TABLET_PW'; pmbootstrap config ssh_keys True"
docker exec "$PMOS_CONTAINER" sh -c '
	set -e
	R=/work/chroot_native/home/pmos/rootfs; O=/share/release; img=$O/archos-oxygen101-phosh.img
	rm -rf $O; mkdir -p $O
	B=$(stat -c %s $R/archos-oxygen101-boot.img); RT=$(stat -c %s $R/archos-oxygen101-root.img)
	truncate -s $(( 1048576 + B + RT )) $img
	printf "label: dos\nstart=2048, size=$((B/512)), type=83, bootable\nstart=$((2048 + B/512)), size=$((RT/512)), type=83\n" | sfdisk -q $img
	dd if=$R/archos-oxygen101-boot.img of=$img bs=1M seek=1 conv=notrunc status=none
	dd if=$R/archos-oxygen101-root.img of=$img bs=512 seek=$((2048 + B/512)) conv=notrunc status=none
	cp /work/chroot_rootfs_archos-oxygen101/boot/boot.img $O/
	xz -T0 -6 $img
	cd $O && sha256sum * > SHA256SUMS && cat SHA256SUMS'
echo "Write it with: xz -dc archos-oxygen101-phosh.img.xz | sudo dd of=/dev/rdiskN bs=4m"
