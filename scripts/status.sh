#!/bin/sh
# "Why is it slow? Is the GPU on? Is it charging?" One look at the running
# system.
. "$(dirname "$0")/env.sh"
tsudo '
echo "== kernel"; uname -v; uptime
echo "== battery"; cd /sys/class/power_supply
for p in rn5t618-battery rn5t618-adp rn5t618-usb; do
	[ -d $p ] && echo "$p: $(cat $p/status 2>/dev/null) online=$(cat $p/online 2>/dev/null) capacity=$(cat $p/capacity 2>/dev/null) current_now=$(cat $p/current_now 2>/dev/null) input_limit=$(cat $p/input_current_limit 2>/dev/null)"
done
echo "== cpu"; cd /sys/devices/system/cpu/cpufreq/policy0 2>/dev/null &&
	echo "$(cat scaling_governor) $(cat scaling_cur_freq) kHz ($(cat scaling_min_freq)-$(cat scaling_max_freq))"
echo "== temperature"; cat /sys/class/thermal/thermal_zone*/temp
echo "== gpu"; lsmod | grep -E "^panfrost" || echo "panfrost not loaded"
journalctl -b --no-pager | grep -m2 -E "EGL driver name|GL_RENDERER|pixman"
echo "== top"; top -b -n1 | head -12
echo "== input devices"; grep -h "N: Name" /proc/bus/input/devices
echo "== eMMC errors"; dmesg | grep -c "I/O error"
'
