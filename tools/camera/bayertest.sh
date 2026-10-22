#!/bin/sh
# Bayer pipeline test (as root): $1 = input selection forced while streaming ("" = driver's)
R=/home/user/rk
for m in /dev/media*; do media-ctl -d $m -p 2>/dev/null | grep -q "driver *rkisp1" && MD=$m; done
M="media-ctl -d $MD"
F=${F:-SBGGR8_1X8}; W=${W:-1280}; H=${H:-720}
$M -V "\"ov5640 3-003c\":0 [fmt:$F/${W}x${H}@1/${FPS:-15}]" &&
$M -V "\"rkisp1_isp\":0 [fmt:$F/${W}x${H} crop:(0,0)/${W}x${H}]" &&
$M -V "\"rkisp1_isp\":2 [fmt:YUYV8_2X8/${W}x${H} crop:(0,0)/${W}x${H}]" &&
$M -V "\"rkisp1_resizer_mainpath\":0 [fmt:YUYV8_2X8/${W}x${H} crop:(0,0)/${W}x${H}]" &&
$M -V "\"rkisp1_resizer_mainpath\":1 [fmt:YUYV8_2X8/${W}x${H}]" || exit 1
S=$($M -e "ov5640 3-003c")
v4l2-ctl -d $S --set-ctrl test_pattern=${TP:-0}
V=$($M -e rkisp1_mainpath)
v4l2-ctl -d $V --set-fmt-video=width=$W,height=$H,pixelformat=YUYV >/dev/null || exit 1
rm -f /home/user/t.yuv
(timeout ${T:-14} v4l2-ctl -d $V --stream-mmap --stream-count=${N:-40} --stream-to=/home/user/t.yuv >/dev/null 2>&1 &)
sleep 0.3
[ -n "$CTRLS" ] && v4l2-ctl -d $S --set-ctrl $CTRLS
[ -n "$POST" ] && sh -c "$POST"
sleep 0.7
if [ -n "$1" ]; then
	a=$($R peek 0xff910404 | cut -d" " -f2); c=$($R peek 0xff910400 | cut -d" " -f2)
	$R poke 0xff910400 $(( c & ~1 )) >/dev/null
	$R poke 0xff910404 $(( (a & ~(7 << 12)) | ($1 << 12) )) >/dev/null
	$R poke 0xff910400 $(( c | 1 | (3 << 9) )) >/dev/null
fi
echo "ctrl $($R peek 0xff910400 | cut -d" " -f2) acq $($R peek 0xff910404 | cut -d" " -f2)"
sleep 1
D=/sys/kernel/debug/ff910000.isp; echo "loss=$(cat $D/data_loss) size=$(cat $D/inform_size_error) frames=$(cat $D/complete_frames)"
wait_end() { while pgrep -x v4l2-ctl >/dev/null; do sleep 0.5; done; }; wait_end; ls -la /home/user/t.yuv
