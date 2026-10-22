import sys
# yuv2png.py FILE W H OUT.ppm: last YUYV frame to PPM, and a row of samples
d = open(sys.argv[1], "rb").read(); W, H = int(sys.argv[2]), int(sys.argv[3]); fs = W * H * 2; n = len(d) // fs
f = d[fs * (n - 1):fs * n]
row = f[W * 2 * (H // 2):W * 2 * (H // 2 + 1)]
print("frames", n, "Y", [row[x * 2] for x in range(W // 16, W, W // 8)], "UV", [row[x * 2 + 1] for x in range(W // 16, W, W // 8)])
clip = lambda v: 0 if v < 0 else 255 if v > 255 else int(v)
out = bytearray()
for i in range(0, len(f), 4):
    y0, u, y1, v = f[i], f[i + 1], f[i + 2], f[i + 3]
    for y in (y0, y1):
        c = y - 16; e = v - 128; dd = u - 128
        out += bytes((clip(1.164 * c + 1.596 * e), clip(1.164 * c - 0.392 * dd - 0.813 * e), clip(1.164 * c + 2.017 * dd)))
open(sys.argv[4], "wb").write(b"P6 %d %d 255\n" % (W, H) + out)
