import mmap, os, struct, sys
# Sample GPIO2's input register: which camera pads toggle while streaming
fd = os.open("/dev/mem", os.O_RDONLY | os.O_SYNC)
m = mmap.mmap(fd, 0x1000, mmap.MAP_SHARED, mmap.PROT_READ, offset=0xff790000)
n = int(sys.argv[1]) if len(sys.argv) > 1 else 200000
ones = [0] * 16
anded, ored = 0xffff, 0
for _ in range(n):
    v = struct.unpack_from("<I", m, 0x50)[0] & 0xffff
    anded &= v; ored |= v
    for b in range(16):
        if v >> b & 1: ones[b] += 1
names = ["A%d D%d" % (i, i + 2) for i in range(8)] + ["B0 vsync", "B1 href", "B2 pclk", "B3 xclk", "B4 D0", "B5 D1", "B6 D10", "B7 D11"]
for b in range(16):
    print("%-9s high %5.1f%%" % (names[b], 100.0 * ones[b] / n))
