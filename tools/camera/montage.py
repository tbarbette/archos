import sys
# montage.py FILE W H OUT.pgm i0 i1 ...: luma of the given frames, 1/4 size, 2 columns
d = open(sys.argv[1], "rb").read(); W, H = int(sys.argv[2]), int(sys.argv[3]); fs = W * H * 2
idx = [int(a) for a in sys.argv[5:]]; w, h = W // 4, H // 4; cols = 2; rows = (len(idx) + 1) // 2
img = bytearray(w * cols * h * rows)
for k, n in enumerate(idx):
    f = d[n * fs:(n + 1) * fs]; ox, oy = (k % cols) * w, (k // cols) * h
    for y in range(h):
        r = f[(y * 4) * W * 2:(y * 4 + 1) * W * 2]
        img[(oy + y) * w * cols + ox:(oy + y) * w * cols + ox + w] = r[0:W * 2:8]
open(sys.argv[4], "wb").write(b"P5 %d %d 255\n" % (w * cols, h * rows) + img)
