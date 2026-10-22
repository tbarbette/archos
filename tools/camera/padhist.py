import mmap, os, struct, sys, collections
# Histogram of the camera data pads (D0..D11) while href is high
fd = os.open("/dev/mem", os.O_RDONLY | os.O_SYNC)
m = mmap.mmap(fd, 0x1000, mmap.MAP_SHARED, mmap.PROT_READ, offset=0xff790000)
h = collections.Counter()
for _ in range(int(sys.argv[1])):
    v = struct.unpack_from("<I", m, 0x50)[0]
    if not (v >> 9) & 1:          # B1 = href
        continue
    d = ((v >> 12) & 3) | ((v & 0xff) << 2) | (((v >> 14) & 3) << 10)
    h[d] += 1
for d, c in h.most_common(24):
    print("D11..D0=%s  D9..D2=0x%02x  D7..D0=0x%02x  count=%d" % (format(d, "012b"), (d >> 2) & 0xff, d & 0xff, c))
