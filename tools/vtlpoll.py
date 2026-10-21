#!/usr/bin/env python3
"""Reset the CT36x (hw, hw+sw, or none) then poll address 0x01 without the irq line."""
import fcntl, os, struct, sys, time

GPIO_GET_LINEHANDLE, GET, SET = 0xC16CB403, 0xC040B408, 0xC040B409


def line(chip, offset, flags, value=0):
    req = struct.pack("<64I I 64B 32s I i", *([offset] + [0] * 63), flags,
                      *([value] + [0] * 63), b"vtlpoll", 1, 0)
    fd = os.open(chip, os.O_RDONLY)
    res = fcntl.ioctl(fd, GPIO_GET_LINEHANDLE, req)
    os.close(fd)
    return struct.unpack_from("<i", res, len(res) - 4)[0]


def i2c(addr):
    fd = os.open("/dev/i2c-4", os.O_RDWR)
    fcntl.ioctl(fd, 0x0706, addr)
    return fd


mode, secs = sys.argv[1], float(sys.argv[2])
irq = line("/dev/gpiochip7", 6, 1)
if "hw" in mode:
    rst = line("/dev/gpiochip7", 5, 2, 1)
    fcntl.ioctl(rst, SET, bytes([0]) + bytes(63)); time.sleep(0.05)
    fcntl.ioctl(rst, SET, bytes([1]) + bytes(63)); time.sleep(0.01)
if "sw" in mode:
    f = i2c(0x7f); os.write(f, b"\x00\x5a"); os.close(f)
time.sleep(0.3)
dev = i2c(0x01)
last, end, errs = None, time.time() + secs, 0
while time.time() < end:
    lvl = fcntl.ioctl(irq, GET, bytes(64))[0]
    try:
        d = os.read(dev, 60)
    except OSError as e:
        errs += 1
        if errs < 3: print("read err", e, flush=True)
        time.sleep(0.2); continue
    if d != last:
        print(round(time.time() % 1000, 2), "irq", lvl, d[:24].hex(), flush=True)
        last = d
    time.sleep(0.02)
print("errors", errs)
