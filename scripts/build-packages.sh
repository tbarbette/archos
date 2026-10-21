#!/bin/sh
# Copy this folder's packages into the container's pmaports, rebuild them
# and put the .apk files in $SHARE/apks.
#   ./build-packages.sh [linux|device|firmware ...]   (default: linux device)
. "$(dirname "$0")/env.sh"
set -e
here=$(cd "$(dirname "$0")/.." && pwd)
aports=$(docker exec -u pmos "$PMOS_CONTAINER" sh -c 'cd; pmbootstrap config aports')
mkdir -p "$SHARE/apks"
for p in ${*:-linux device}; do
	pkg=$p-archos-oxygen101
	docker cp "$here/pmaports/device/testing/$pkg" "$PMOS_CONTAINER:$aports/device/testing/"
	docker exec "$PMOS_CONTAINER" chown -R pmos "$aports/device/testing/$pkg"
	docker exec -u pmos "$PMOS_CONTAINER" sh -c "cd; pmbootstrap checksum $pkg >/dev/null && pmbootstrap -y build --force --arch armv7 $pkg"
	# Keep the updated checksums
	docker cp "$PMOS_CONTAINER:$aports/device/testing/$pkg/APKBUILD" "$here/pmaports/device/testing/$pkg/APKBUILD"
done
docker exec "$PMOS_CONTAINER" sh -c 'cp -p /work/packages/*/armv7/*archos-oxygen101*.apk /share/apks/; ls -t /share/apks | head -4'
