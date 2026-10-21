#!/bin/sh
# Reboot the tablet into a mode U-Boot understands: recovery, loader
# (Rockchip USB, for rkdeveloptool), bootloader (fastboot), or nothing for a
# plain reboot.
. "$(dirname "$0")/env.sh"
if [ -n "$1" ]; then
	tsudo "systemctl reboot --reboot-argument=$1"
else
	tsudo "systemctl reboot"
fi
