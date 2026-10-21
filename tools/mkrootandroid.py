"""Add a root shell service and /sbin/rk to a (debug) Android boot image.
usage: mkrootandroid.py IN.img OUT.img rk-binary"""
import gzip, struct, sys
sys.path.insert(0, __import__("os").path.dirname(__file__))
from mkrkupdate import cpio_entries, cpio_build

src, dst, rk = sys.argv[1:4]
d = bytearray(open(src, "rb").read())
ks, ka, rs, ra, ss, sa, ta, ps = struct.unpack_from("<8I", d, 8)
up = lambda x: (x + ps - 1) // ps * ps
roff = ps + up(ks)
entries = list(cpio_entries(gzip.decompress(bytes(d[roff:roff + rs]))))
RC = b"""
on early-init
    setenforce 0

service rkserve /sbin/rk serve 2323
    class core
    user root
    group root
"""
out = []
for f, name, content in entries:
    if name == "init.rc":
        content = content + RC
    if name == "TRAILER!!!":
        tmpl = next(e[0] for e in entries if e[1] == "sbin/adbd")
        out.append((tmpl, "sbin/rk", open(rk, "rb").read()))
    out.append((f, name, content))
rd = gzip.compress(cpio_build(out), 9)
hdr = bytearray(d[:ps])
struct.pack_into("<I", hdr, 16, len(rd))
pad = lambda b: b + b"\0" * (-len(b) % ps)
img = bytes(hdr) + pad(bytes(d[ps:ps + ks])) + pad(rd) + pad(bytes(d[roff + up(rs):roff + up(rs) + ss]))
open(dst, "wb").write(img)
print(dst, len(img))
