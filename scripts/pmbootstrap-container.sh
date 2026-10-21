#!/bin/sh
# Create the Linux container pmbootstrap runs in (Docker Desktop on macOS).
# It is privileged for loop devices and binfmt; /work persists in a volume,
# and $SHARE is shared with the Mac as /share.
. "$(dirname "$0")/env.sh"
set -e
mkdir -p "$SHARE/keys"
docker volume create pmos-work >/dev/null
docker run -d --name "$PMOS_CONTAINER" --privileged -v pmos-work:/work -v "$SHARE":/share alpine:3.22 sleep infinity
docker exec "$PMOS_CONTAINER" sh -c '
	apk add -q git python3 py3-pip sudo openssl coreutils procps multipath-tools losetup dtc make gcc musl-dev bash xz file sfdisk e2fsprogs
	adduser -D -u 1000 pmos
	echo "pmos ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/pmos
	chown pmos /work
	su pmos -c "git clone -q --depth 1 https://gitlab.postmarketos.org/postmarketOS/pmbootstrap.git ~/pmbootstrap"
	ln -s /home/pmos/pmbootstrap/pmbootstrap.py /usr/local/bin/pmbootstrap'
echo "Now: docker exec -it -u pmos $PMOS_CONTAINER pmbootstrap --work /work init"
echo "  (device archos-oxygen101 after copying ../pmaports/device/testing/* into the aports;"
echo "   ssh_key_glob /share/keys/*.pub to log in without a password)"
