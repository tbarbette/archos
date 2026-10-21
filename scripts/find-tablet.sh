#!/bin/sh
# "Is the tablet there, and in which mode?" Checks, in order: USB (Android,
# Rockchip loader, pmOS USB network) and WiFi.
#
# For WiFi, set TABLET to a guess, or TABLET_MAC to look it up in the ARP
# table after a ping sweep of SUBNET (e.g. SUBNET=192.168.1). If the tablet
# is on an access point you can log into, AP_SSH="ssh user@ap" lists its
# stations instead (that's how it was found on the lab network).
. "$(dirname "$0")/env.sh"

echo "== USB devices (vendor 0x2207 = 8711: Rockchip loader, or the pmOS gadget)"
ioreg -p IOUSB -w0 -l | grep -E '"USB Product Name"|"idVendor"|"idProduct"' | paste - - - |
	grep -iE "archos|rockchip|postmarket|= 8711" | tr -s ' \t|' ' '

echo "== Android (adb)"
command -v adb >/dev/null && adb devices -l | tail -n +2

echo "== Rockchip loader (rkdeveloptool)"
# pmOS's USB gadget also uses 2207:d001, which rkdeveloptool reports as
# "Maskrom": only "Loader" means the tablet is in the loader.
command -v "$RKDEV" >/dev/null && "$RKDEV" ld 2>&1

echo "== pmOS USB network (172.16.42.1)"
ping -c1 -t2 172.16.42.1 >/dev/null 2>&1 && echo "up: ssh user@172.16.42.1" || echo "no answer"

echo "== WiFi"
if [ -n "$AP_SSH" ]; then
	# Stations of a Linux hostapd AP, then their addresses on its bridge
	$AP_SSH 'for d in $(iw dev | sed -n "s/.*Interface //p"); do iw dev $d station dump | grep -E "^Station|connected time"; done; ip neigh'
fi
if [ -n "$TABLET_MAC" ] && [ -n "$SUBNET" ]; then
	for i in $(seq 1 254); do ping -c1 -t1 "$SUBNET.$i" >/dev/null 2>&1 & done; wait
	arp -a | grep -i "$TABLET_MAC"
fi
if [ "$TABLET" != 172.16.42.1 ]; then
	ping -c1 -t2 "$TABLET" >/dev/null 2>&1 && echo "$TABLET is up" || echo "$TABLET: no answer"
fi
# On the tablet itself: nmcli -f IP4.ADDRESS dev show wlan0
