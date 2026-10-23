#!/bin/sh
# A/B the libcamera tuning (stock vs adapted), with the sensor's own AEC on and off.
S=$(grep -l ov5640 /sys/class/video4linux/v4l-subdev*/name | sed "s,/sys/class/video4linux/\(.*\)/name,/dev/\1,")
for aec in auto manual; do
	if [ $aec = auto ]; then v4l2-ctl -d $S --set-ctrl auto_exposure=0,gain_automatic=1
	else v4l2-ctl -d $S --set-ctrl auto_exposure=1,gain_automatic=0; fi
	for t in stock archos; do
		if [ $t = stock ]; then unset LIBCAMERA_RKISP1_TUNING_FILE
		else export LIBCAMERA_RKISP1_TUNING_FILE=/home/user/ov5640-archos.yaml; fi
		printf "%-6s %-7s " $aec $t; sh /home/user/camstat.sh
	done
done
v4l2-ctl -d $S --set-ctrl auto_exposure=0,gain_automatic=1
