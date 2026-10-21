#!/system/bin/sh
# Dump RK3288 GPIO, pinmux and pull registers with peek
P=${P:-./rk peek}
for base in 0xff750000 0xff780000 0xff790000 0xff7a0000 0xff7b0000 0xff7c0000 0xff7d0000 0xff7e0000 0xff7f0000; do
	$P $base 2; $P $((base + 0x50)) 1
done
$P 0xff770000 41     # GRF iomux GPIO1A..GPIO8B
$P 0xff770140 37     # GRF pulls
$P 0xff730064 3      # PMU GPIO0 pulls
$P 0xff730084 3      # PMU GPIO0 iomux
$P 0xff770380 1      # GRF_IO_VSEL
