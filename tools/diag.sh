#!/bin/sh
# Run as root on the tablet: state before kernel r3/r4
echo "== kernel"; uname -v
echo "== load / top"; uptime; top -b -n1 | head -15
echo "== cpu clock"
cat /sys/kernel/debug/clk/armclk/clk_rate 2>/dev/null || \
	grep -E "^ *(armclk|aclk_gpu|apll|gpll|cpll)\b" /sys/kernel/debug/clk/clk_summary
ls /sys/devices/system/cpu/cpufreq/ 2>&1
echo "== thermal"; cat /sys/class/thermal/thermal_zone*/temp
echo "== gl renderer"; grep -h -i "renderer\|llvmpipe" /proc/*/maps 2>/dev/null | sort -u | head -3
echo "== SYR827 (cpu, 0x40) / SYR828 (gpu, 0x41): VSEL0 VSEL1 CTRL ID1 ID2"
for a in 0x40 0x41; do
	printf '%s:' $a
	for r in 0x00 0x01 0x02 0x03 0x04; do printf ' %s' "$(i2cget -y -f 0 $a $r 2>&1)"; done
	echo
done
echo "== RC5T619 PWRIREN PWRIRQ PWRMON PWRIRSEL (0x12-0x15), SOC 0xe1, CONTROL 0xb0"
for r in 0x12 0x13 0x14 0x15 0xe1 0xb0; do printf ' %s=%s' $r "$(i2cget -y -f 0 0x32 $r 2>&1)"; done
echo
echo "== evtest logs"
for f in /home/user/keys-event*.log; do echo "-- $f"; grep -E "EV_KEY|EV_SW" "$f" | grep -v "Event code\|Event type" | head -8; done
