#!/bin/sh
# Camera capture test on the tablet (as root): configure the pipeline,
# optionally ungate sclk_isp_jpe, capture, print the ISP error counters.
R=/home/user/rk
D=/sys/kernel/debug/ff910000.isp
M="media-ctl -d /dev/media0"
W=${W:-640}; H=${H:-480}; FPS=${FPS:-15}
c() { echo "$1 loss=$(cat $D/data_loss) size=$(cat $D/inform_size_error) frames=$(cat $D/complete_frames) irq=$(awk '/rkisp1/ {print $2}' /proc/interrupts)"; }
$M -V "\"ov5640 3-003c\":0 [fmt:UYVY8_2X8/${W}x${H}@1/$FPS]" &&
$M -V "\"rkisp1_isp\":0 [fmt:UYVY8_2X8/${W}x${H} crop:(0,0)/${W}x${H}]" &&
$M -V "\"rkisp1_isp\":2 [fmt:YUYV8_2X8/${W}x${H} crop:(0,0)/${W}x${H}]" &&
$M -V "\"rkisp1_resizer_mainpath\":0 [fmt:YUYV8_2X8/${W}x${H} crop:(0,0)/${W}x${H}]" &&
$M -V "\"rkisp1_resizer_mainpath\":1 [fmt:YUYV8_2X8/${W}x${H}]" || exit 1
V=$($M -e rkisp1_mainpath)
v4l2-ctl -d $V --set-fmt-video=width=$W,height=$H,pixelformat=YUYV || exit 1
c before
rm -f /home/user/frames.yuv
(timeout ${T:-12} v4l2-ctl -d $V --stream-mmap --stream-count=${N:-10} --stream-to=/home/user/frames.yuv > /home/user/v4l.log 2>&1 &)
sleep 0.3
[ -n "$JPE" ] && $R poke 0xff76016c 0x80000000 >/dev/null
for i in 1 2 3 4; do sleep 3; c "t=$((i * 3))s"; done
tail -c 300 /home/user/v4l.log; echo
ls -la /home/user/frames.yuv
