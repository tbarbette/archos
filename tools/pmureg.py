import mmap, os, struct, sys
# RK3288 PMU_SYS_REG0 (0xff730094): reboot mode flag read by the loader
fd = os.open("/dev/mem", os.O_RDWR | os.O_SYNC)
m = mmap.mmap(fd, 0x1000, offset=0xff730000)
if len(sys.argv) > 1:
    m[0x94:0x98] = struct.pack("<I", int(sys.argv[1], 0))
print(hex(struct.unpack("<I", m[0x94:0x98])[0]))
