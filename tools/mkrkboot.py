#!/usr/bin/env python3
"""Build a Rockchip legacy-loader boot.img: Android v0 header, kernel,
ramdisk, and an RSCE resource image (holding rk-kernel.dtb) as "second".

usage: mkrkboot.py STOCK_RESOURCE.img KERNEL INITRAMFS DTB OUT [CMDLINE]
"""
import hashlib
import struct
import sys

BLK = 512
PAGE = 16384
import os
KERNEL_ADDR = int(os.environ.get("KERNEL_ADDR", "0x60408000"), 0)
RAMDISK_ADDR = int(os.environ.get("RAMDISK_ADDR", "0x62000000"), 0)
SECOND_ADDR = 0x60F00000
TAGS_ADDR = 0x60088000


def read_rsce(data):
    assert data[:4] == b"RSCE", "not an RSCE image"
    hdr_blks, _tbl_off, ent_blks = data[8], data[9], data[10]
    (num,) = struct.unpack_from("<I", data, 12)
    files = []
    for i in range(num):
        e = data[(hdr_blks + i * ent_blks) * BLK:][:BLK]
        assert e[:4] == b"ENTR"
        name = e[4:260].split(b"\0")[0].decode()
        blk, size = struct.unpack_from("<II", e, 260)
        files.append((name, data[blk * BLK:blk * BLK + size]))
    return files


def write_rsce(files):
    n = len(files)
    hdr = bytearray(BLK)
    hdr[:4] = b"RSCE"
    hdr[8:11] = bytes([1, 1, 1])
    struct.pack_into("<I", hdr, 12, n)
    entries = bytearray()
    blobs = bytearray()
    blk = 1 + n
    for name, content in files:
        e = bytearray(BLK)
        e[:4] = b"ENTR"
        e[4:4 + len(name)] = name.encode()
        struct.pack_into("<II", e, 260, blk, len(content))
        entries += e
        padded = content + b"\0" * (-len(content) % BLK)
        blobs += padded
        blk += len(padded) // BLK
    return bytes(hdr + entries + blobs)


def pad(b):
    return b + b"\0" * (-len(b) % PAGE)


def main():
    stock_res, kernel, ramdisk, dtb, out = sys.argv[1:6]
    cmdline = sys.argv[6] if len(sys.argv) > 6 else ""
    files = read_rsce(open(stock_res, "rb").read())
    dtb_data = open(dtb, "rb").read()
    files = [(n, dtb_data if n == "rk-kernel.dtb" else c) for n, c in files]
    second = write_rsce(files)
    k = open(kernel, "rb").read()
    r = open(ramdisk, "rb").read()
    cmdline = cmdline.replace("@RDSIZE@", "0x%08x" % len(r))
    assert len(cmdline) < 512, "cmdline too long"

    sha = hashlib.sha1()
    for blob in (k, r, second):
        sha.update(blob)
        sha.update(struct.pack("<I", len(blob)))
    hdr = bytearray(PAGE)
    hdr[:8] = b"ANDROID!"
    struct.pack_into("<10I", hdr, 8, len(k), KERNEL_ADDR, len(r), RAMDISK_ADDR,
                     len(second), SECOND_ADDR, TAGS_ADDR, PAGE, 0, 0)
    hdr[64:64 + len(cmdline)] = cmdline.encode()
    hdr[576:576 + 20] = sha.digest()
    img = bytes(hdr) + pad(k) + pad(r) + pad(second)
    open(out, "wb").write(img)
    print(f"{out}: {len(img)} bytes, kernel {len(k)}, ramdisk {len(r)}, "
          f"second {len(second)}\ncmdline: {cmdline}")


if __name__ == "__main__":
    main()
