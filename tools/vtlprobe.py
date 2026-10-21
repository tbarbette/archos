#!/usr/bin/env python3
"""Hardware-reset the VTL CT36x touch controller and dump touch frames."""
import fcntl, os, struct, sys, time

GPIO_GET_LINEHANDLE = 0xC16CB403
GPIOHANDLE_GET_VALUES = 0xC040B408
GPIOHANDLE_SET_VALUES = 0xC040B409
REQ_INPUT, REQ_OUTPUT = 1, 2
I2C_SLAVE_FORCE = 0x0706


def line(chip, offset, flags, value=0):
    req = struct.pack("<64I I 64B 32s I i", *([offset] + [0] * 63), flags,
                      *([value] + [0] * 63), b"vtlprobe", 1, 0)
    fd = os.open(chip, os.O_RDONLY)
    res = fcntl.ioctl(fd, GPIO_GET_LINEHANDLE, req)
    os.close(fd)
    return struct.unpack_from("<i", res, len(res) - 4)[0]


def setv(h, v):
    fcntl.ioctl(h, GPIOHANDLE_SET_VALUES, bytes([v]) + bytes(63))


def getv(h):
    return fcntl.ioctl(h, GPIOHANDLE_GET_VALUES, bytes(64))[0]


def i2c(addr):
    fd = os.open("/dev/i2c-4", os.O_RDWR)
    fcntl.ioctl(fd, I2C_SLAVE_FORCE, addr)
    return fd


rst = line("/dev/gpiochip7", 5, REQ_OUTPUT, 1)
irq = line("/dev/gpiochip7", 6, REQ_INPUT)
setv(rst, 0); time.sleep(0.05); setv(rst, 1); time.sleep(0.01)
print("irq level after reset:", getv(irq))
try:
    f = i2c(0x7f); os.write(f, b"\x00\x5a"); os.close(f)
    print("soft reset sent")
except OSError as e:
    print("soft reset failed:", e)
time.sleep(0.3)
dev = i2c(0x01)
end = time.time() + float(sys.argv[1] if len(sys.argv) > 1 else 3)
n = 0
while time.time() < end:
    if getv(irq) == 0:
        try:
            d = os.read(dev, 60)
        except OSError as e:
            print("read err", e); time.sleep(0.1); continue
        n += 1
        pts = []
        for i in range(10):
            xhi, yhi, lo, sid, area, pr = d[i * 6:i * 6 + 6]
            st, pid = sid & 7, sid >> 3
            if st in (1, 2) and xhi != 0xff:
                pts.append((pid, st, (xhi << 4) | (lo >> 4), (yhi << 4) | (lo & 15), area, pr))
        if n <= 3 or pts:
            print(round(time.time() % 100, 2), d[:12].hex(), pts, flush=True)
    time.sleep(0.005)
print("frames:", n, "irq now:", getv(irq))
