#!/usr/bin/env python3
"""Tap a key through a throwaway uinput device to wake the screen."""
import fcntl, os, struct, time

UI_SET_EVBIT, UI_SET_KEYBIT, UI_DEV_CREATE, UI_DEV_DESTROY = 0x40045564, 0x40045565, 0x5501, 0x5502
EV_SYN, EV_KEY, KEY_LEFTSHIFT = 0, 1, 42

fd = os.open("/dev/uinput", os.O_WRONLY)
fcntl.ioctl(fd, UI_SET_EVBIT, EV_KEY)
fcntl.ioctl(fd, UI_SET_KEYBIT, KEY_LEFTSHIFT)
os.write(fd, struct.pack("<80sHHHHi", b"wake", 3, 1, 1, 1, 0) + bytes(4 * 64 * 4))
fcntl.ioctl(fd, UI_DEV_CREATE)
time.sleep(1)
for v in (1, 0):
    os.write(fd, struct.pack("<llHHi", 0, 0, EV_KEY, KEY_LEFTSHIFT, v))
    os.write(fd, struct.pack("<llHHi", 0, 0, EV_SYN, 0, 0))
time.sleep(0.5)
fcntl.ioctl(fd, UI_DEV_DESTROY)
