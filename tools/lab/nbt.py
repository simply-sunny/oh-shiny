# Minimal NBT reader/writer (big-endian, gzip), enough to read and edit level.dat.
import gzip, struct, sys, json
class Tag:
    def __init__(s, t, v): s.t, s.v = t, v
def rd(b, i, t):
    if t == 1: return struct.unpack_from('>b', b, i)[0], i + 1
    if t == 2: return struct.unpack_from('>h', b, i)[0], i + 2
    if t == 3: return struct.unpack_from('>i', b, i)[0], i + 4
    if t == 4: return struct.unpack_from('>q', b, i)[0], i + 8
    if t == 5: return struct.unpack_from('>f', b, i)[0], i + 4
    if t == 6: return struct.unpack_from('>d', b, i)[0], i + 8
    if t == 7:
        n = struct.unpack_from('>i', b, i)[0]; return bytes(b[i+4:i+4+n]), i + 4 + n
    if t == 8:
        n = struct.unpack_from('>H', b, i)[0]; return b[i+2:i+2+n].decode('utf-8', 'replace'), i + 2 + n
    if t == 9:
        et = b[i]; n = struct.unpack_from('>i', b, i+1)[0]; i += 5; out = []
        for _ in range(n):
            v, i = rd(b, i, et); out.append(Tag(et, v))
        return (et, out), i
    if t == 10:
        d = {}
        while True:
            et = b[i]; i += 1
            if et == 0: return d, i
            n = struct.unpack_from('>H', b, i)[0]; name = b[i+2:i+2+n].decode(); i += 2 + n
            v, i = rd(b, i, et); d[name] = Tag(et, v)
    if t == 11:
        n = struct.unpack_from('>i', b, i)[0]; return list(struct.unpack_from('>%di' % n, b, i+4)), i + 4 + 4*n
    if t == 12:
        n = struct.unpack_from('>i', b, i)[0]; return list(struct.unpack_from('>%dq' % n, b, i+4)), i + 4 + 8*n
    raise ValueError(t)
def wr(t, v):
    if t == 1: return struct.pack('>b', v)
    if t == 2: return struct.pack('>h', v)
    if t == 3: return struct.pack('>i', v)
    if t == 4: return struct.pack('>q', v)
    if t == 5: return struct.pack('>f', v)
    if t == 6: return struct.pack('>d', v)
    if t == 7: return struct.pack('>i', len(v)) + v
    if t == 8: e = v.encode(); return struct.pack('>H', len(e)) + e
    if t == 9:
        et, items = v; return bytes([et]) + struct.pack('>i', len(items)) + b''.join(wr(et, x.v) for x in items)
    if t == 10:
        out = b''
        for k, x in v.items():
            e = k.encode(); out += bytes([x.t]) + struct.pack('>H', len(e)) + e + wr(x.t, x.v)
        return out + b'\0'
    if t == 11: return struct.pack('>i', len(v)) + struct.pack('>%di' % len(v), *v)
    if t == 12: return struct.pack('>i', len(v)) + struct.pack('>%dq' % len(v), *v)
def load(p):
    b = gzip.open(p).read(); assert b[0] == 10
    n = struct.unpack_from('>H', b, 1)[0]; v, _ = rd(b, 3 + n, 10); return v
def save(p, root):
    gzip.open(p, 'wb').write(b'\x0a\x00\x00' + wr(10, root))
def plain(x):
    if isinstance(x, Tag): x = x.v
    if isinstance(x, dict): return {k: plain(v) for k, v in x.items()}
    if isinstance(x, tuple): return [plain(i) for i in x[1]]
    if isinstance(x, bytes): return '<%d bytes>' % len(x)
    if isinstance(x, list) and len(x) > 16: return '<%d ints>' % len(x)
    return x
if __name__ == '__main__':
    print(json.dumps(plain(load(sys.argv[1])), indent=1, default=str)[:int(sys.argv[2]) if len(sys.argv) > 2 else 6000])
