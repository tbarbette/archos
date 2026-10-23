#!/bin/sh
# Capture N (40) frames with libcamera and print luma stats of the last one (no image kept)
rm -f /tmp/cs-*.yuv
LIBCAMERA_LOG_LEVELS=${LOG:-*:ERROR} cam -c 1 -C${N:-40} -s width=1280,height=720,pixelformat=YUYV -F/tmp/cs-#.yuv >/tmp/cs.log 2>&1
f=$(ls /tmp/cs-*.yuv | sort -V | tail -1)
python3 - "$f" <<'P'
import sys
d=open(sys.argv[1],"rb").read()
y=sorted(d[0::2]); n=len(y)
print("mean %.1f p50 %d p95 %d p99 %d max %d  clip>=234: %.2f%%" % (sum(y)/n, y[n//2], y[int(n*.95)], y[int(n*.99)], y[-1], 100*sum(1 for v in y if v>=234)/n))
P
rm -f /tmp/cs-*.yuv
