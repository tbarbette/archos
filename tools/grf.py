import mmap, os, struct, sys
# RK3288 GRF_IO_VSEL (0xff770380): 1 = 1.8 V. Upper 16 bits are write enables.
fd = os.open("/dev/mem", os.O_RDWR | os.O_SYNC)
m = mmap.mmap(fd, 0x1000, offset=0xff770000)
off = 0x380
if len(sys.argv) > 1:
    bit = int(sys.argv[1]); val = int(sys.argv[2])
    m[off:off+4] = struct.pack("<I", (1 << (bit + 16)) | (val << bit))
v = struct.unpack("<I", m[off:off+4])[0]
names = ["lcdc", "dvp", "flash0", "flash1", "wifi", "bb", "audio", "sdcard"]
print(hex(v), " ".join("%s=%s" % (n, "1.8" if v >> i & 1 else "3.3") for i, n in enumerate(names)))
