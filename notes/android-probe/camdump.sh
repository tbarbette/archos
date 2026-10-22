# Android side: dump SoC state relevant to the camera
R=/data/local/tmp/rk
echo "## grf iomux"; $R peek 0xff770000 41
echo "## grf soc_con"; $R peek 0xff770244 15
echo "## grf io_vsel"; $R peek 0xff770380 1
echo "## gpio0 gpio2"; $R peek 0xff750000 2; $R peek 0xff790000 2
echo "## cru clksel"; $R peek 0xff760060 43
echo "## cru clkgate"; $R peek 0xff760160 19
if [ "$1" = cam ]; then
	echo "## isp vi"; $R peek 0xff910000 16
	echo "## isp core"; $R peek 0xff910400 48
	echo "## isp mi"; $R peek 0xff911400 16
	echo "## ov5640"
	for r in 0x3008 0x300e 0x3017 0x3018 0x3034 0x3035 0x3036 0x3037 0x3108 0x3820 0x3821 0x3824 0x4300 0x4407 0x4740 0x4741 0x501f 0x460b 0x460c 0x3c00; do $R i2cget16 3 0x3c $r; done
	$R i2cget16 3 0x3c 0x300a 2
	$R i2cget16 3 0x3c 0x3808 4
fi
