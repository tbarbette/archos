#!/usr/bin/env python3
"""Build a Rockchip RKAF update.img for the KitKat RK recovery
("update rkimage from external storage"), plus helpers.

usage:
  mkrkupdate.py crccheck PARAMETER_BLOCK
  mkrkupdate.py debugrecovery STOCK_RECOVERY.img OUT.img
  mkrkupdate.py rkaf OUT MODEL name=file [name=file ...]
"""
import gzip
import struct
import sys

# Rockchip CRC32: poly 0x04C10DB7, MSB first, init 0, no final xor.
_TABLE = []
for i in range(256):
    c = i << 24
    for _ in range(8):
        c = ((c << 1) ^ 0x04C10DB7) if c & 0x80000000 else (c << 1)
    _TABLE.append(c & 0xFFFFFFFF)


def rkcrc(data, crc=0):
    t = _TABLE
    for b in data:
        crc = ((crc << 8) & 0xFFFFFFFF) ^ t[(crc >> 24) ^ b]
    return crc


def crccheck(path):
    d = open(path, "rb").read()
    assert d[:4] == b"PARM"
    (n,) = struct.unpack_from("<I", d, 4)
    (stored,) = struct.unpack_from("<I", d, 8 + n)
    calc = rkcrc(d[8:8 + n])
    print(f"stored {stored:08x} computed {calc:08x} ->",
          "OK" if stored == calc else "MISMATCH")
    return stored == calc


# --- newc cpio editing -------------------------------------------------------

def cpio_entries(data):
    off = 0
    while True:
        hdr = data[off:off + 110]
        assert hdr[:6] == b"070701", hdr[:6]
        f = [int(hdr[6 + 8 * i:14 + 8 * i], 16) for i in range(13)]
        namesize, filesize = f[11], f[6]
        name = data[off + 110:off + 110 + namesize - 1].decode()
        doff = (off + 110 + namesize + 3) & ~3
        content = data[doff:doff + filesize]
        yield f, name, content
        off = (doff + filesize + 3) & ~3
        if name == "TRAILER!!!":
            return


def cpio_build(entries):
    out = bytearray()
    for f, name, content in entries:
        f = list(f)
        f[6] = len(content)
        f[11] = len(name) + 1
        out += b"070701" + b"".join(b"%08X" % v for v in f)
        out += name.encode() + b"\0"
        out += b"\0" * (-len(out) % 4)
        out += content
        out += b"\0" * (-len(out) % 4)
    out += b"\0" * (-len(out) % 512)
    return bytes(out)


def debugrecovery(src, dst):
    d = bytearray(open(src, "rb").read())
    ks, ka, rs, ra, ss, sa, ta, ps = struct.unpack_from("<8I", d, 8)
    up = lambda x: (x + ps - 1) // ps * ps
    roff = ps + up(ks)
    ramdisk = gzip.decompress(bytes(d[roff:roff + rs]))
    entries = []
    for f, name, content in cpio_entries(ramdisk):
        if name == "default.prop":
            text = content.decode()
            for k, v in (("ro.secure", "0"), ("ro.debuggable", "1"),
                         ("ro.adb.secure", "0"),
                         ("persist.sys.usb.config", "adb")):
                lines = [l for l in text.split("\n")
                         if not l.replace(" ", "").startswith(k + "=")]
                text = "\n".join(lines)
                text += f"\n{k}={v}"
            content = (text + "\n").encode()
        entries.append((f, name, content))
    new_rd = gzip.compress(cpio_build(entries), 9)
    k = bytes(d[ps:ps + ks])
    second = bytes(d[roff + up(rs):roff + up(rs) + ss])
    hdr = bytearray(d[:ps])
    struct.pack_into("<I", hdr, 16, len(new_rd))
    pad = lambda b: b + b"\0" * (-len(b) % ps)
    img = bytes(hdr) + pad(k) + pad(new_rd) + pad(second)
    open(dst, "wb").write(img)
    print(f"{dst}: {len(img)} bytes (ramdisk {rs} -> {len(new_rd)})")


# --- RKAF package ------------------------------------------------------------

def rkaf(out, model, items):
    n = len(items)
    assert n <= 16
    hdr_size = 4 + 4 + 64 + 60 + 4 + 4 + 16 * 112
    blobs = []
    off = (hdr_size + 2047) & ~2047
    table = bytearray()
    for name, path in items:
        data = open(path, "rb").read()
        use = (len(data) + 2047) // 2048
        table += struct.pack("<32s64sIIII", name.encode(), path.split("/")[-1].encode(),
                             off, 0xFFFFFFFF, use, len(data))
        blobs.append((off, data))
        off += use * 2048
    table += b"\0" * (16 * 112 - len(table))
    total = off
    hdr = struct.pack("<4sI64s60sII", b"RKAF", total, model.encode(),
                      b"RK30SDK", 0x01000000, n) + table
    img = bytearray(total)
    img[:len(hdr)] = hdr
    for o, data in blobs:
        img[o:o + len(data)] = data
    crc = rkcrc(img)
    img += struct.pack("<I", crc)
    open(out, "wb").write(img)
    print(f"{out}: {len(img)} bytes, {n} items, crc {crc:08x}")


if __name__ == "__main__":
    cmd = sys.argv[1]
    if cmd == "crccheck":
        sys.exit(0 if crccheck(sys.argv[2]) else 1)
    elif cmd == "debugrecovery":
        debugrecovery(sys.argv[2], sys.argv[3])
    elif cmd == "rkaf":
        rkaf(sys.argv[2], sys.argv[3],
             [a.split("=", 1) for a in sys.argv[4:]])
