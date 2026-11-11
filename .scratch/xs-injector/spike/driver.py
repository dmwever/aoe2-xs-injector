import json
import os
import shutil
import struct
import subprocess
import sys
import time
from pathlib import Path

PROFILE = Path(r"C:\Users\dmwev\Games\Age of Empires 2 DE\76561199655318799\profile")
KIT = r"C:\Users\dmwev\Documents\GitHub\aoe2kit\bin\kit.exe"
HERE = Path(__file__).resolve().parent
CANDIDATES = ["XsTesting", "default1", "default0"]
MAGIC = 20261110
HOLD_STEPS = {7, 8, 9, 10, 11}
SLOW_STEPS = {13, 14, 15, 16, 17}
STEPS = list(range(1, 19)) + [99]

events = []
t_start = time.time()


def note(kind, **kw):
    row = {"t": round(time.time() - t_start, 3), "wall": time.strftime("%H:%M:%S"), "kind": kind, **kw}
    events.append(row)
    print(json.dumps(row), flush=True)


def i32(*vals):
    return b"".join(struct.pack("<i", v) for v in vals)


def f32(*vals):
    return b"".join(struct.pack("<f", v) for v in vals)


def s(b):
    if isinstance(b, str):
        b = b.encode("utf-8")
    return struct.pack("<I", len(b)) + b


def put(name, data):
    (PROFILE / f"{name}.xsdat").write_bytes(data)


def fixtures():
    (HERE / "run").mkdir(exist_ok=True)
    (HERE / "run" / "setup.json").write_text(json.dumps({"setup_time": time.time()}))
    put("spike_ctl", i32(0))
    put("spike_pos", i32(7) + f32(1.5) + s("abc") + f32(1.0, 2.0, 3.0) + i32(9))
    put("spike_eof", i32(7))
    put("spike_empty", b"")
    put("spike_a", i32(101, 102))
    put("spike_b", i32(201, 202))
    for k in (7, 8, 9, 10):
        put(f"spike_hold{k}", i32(k * 100 + 1, k * 100 + 2))
    put("spike_str", s("hello") + s("\u00e9") + s("\u65e5\u672c") + s("%d%s%%") + s(b"\xe9")
        + s("a" * 255) + s("b" * 4096) + s("c" * 65536))
    put("spike_bigstr", s("x" * 1_000_000))
    put("spike_big100k", i32(*range(100_000)))
    put("spike_big400k", i32(*range(400_000)))
    put("spike_badstr", i32(0x7FFFFFF0) + b"abc")
    for c in CANDIDATES:
        p = PROFILE / f"{c}.xsdat"
        if p.exists():
            st = p.stat()
            note("candidate_before", name=c, size=st.st_size, mtime=st.st_mtime)


def write_ctl(step):
    tmp = PROFILE / "spike_ctl.tmp"
    for attempt in range(40):
        try:
            tmp.write_bytes(i32(step))
            os.replace(tmp, PROFILE / "spike_ctl.xsdat")
            note("ctl", step=step, attempts=attempt + 1)
            return
        except OSError as ex:
            last = repr(ex)
            time.sleep(0.05)
    note("ctl_failed", step=step, error=last)


def kit_values(path, types):
    r = subprocess.run([KIT, "xsdat", "decode", str(path), "--types", types, "--json"],
                       capture_output=True, text=True)
    try:
        return json.loads(r.stdout)
    except json.JSONDecodeError:
        return {"ok": False, "error": (r.stderr or r.stdout)[:300]}


def decode_log(path):
    head = kit_values(path, "int,int")
    vals = head.get("decode", {}).get("values", [])
    if len(vals) < 2 or vals[0].get("int") != MAGIC:
        return None, head.get("error")
    n = vals[1]["int"]
    full = kit_values(path, ",".join(["int", "int"] + ["string", "int", "string"] * n + ["int"]))
    v = full.get("decode", {}).get("values", [])
    rows = []
    for k in range(n):
        base = 2 + 3 * k
        if base + 2 >= len(v):
            break
        rows.append((v[base].get("string"), v[base + 1].get("int"), v[base + 2].get("string")))
    return {"ok": full.get("ok"), "rows": rows, "remaining": full.get("decode", {}).get("remaining_bytes")}, None


def find_log(since):
    for c in CANDIDATES:
        p = PROFILE / f"{c}.xsdat"
        try:
            st = p.stat()
        except OSError:
            continue
        if st.st_mtime < since:
            continue
        log, err = decode_log(p)
        if log:
            return c, log
    return None, None


def snapshot(tag):
    out = HERE / "run" / tag
    out.mkdir(parents=True, exist_ok=True)
    for c in CANDIDATES:
        p = PROFILE / f"{c}.xsdat"
        if not p.exists():
            continue
        try:
            data = p.read_bytes()
            (out / f"{c}.xsdat").write_bytes(data)
            note("snapshot", tag=tag, name=c, size=len(data), mtime=p.stat().st_mtime)
        except OSError as ex:
            note("snapshot_failed", tag=tag, name=c, error=repr(ex))


def wait_row(label, value, timeout, since):
    end = time.time() + timeout
    while time.time() < end:
        name, log = find_log(since)
        if log and any(r[0] == label and r[1] == value for r in log["rows"]):
            note("ack", label=label, value=value, file=name, rows=len(log["rows"]))
            return name
        time.sleep(0.25)
    note("no_ack", label=label, value=value, timeout=timeout)
    return None


def attempt(op, fn):
    try:
        res = fn()
        note("op", op=op, ok=True, result=res)
    except OSError as ex:
        note("op", op=op, ok=False, error=repr(ex))


def read_info(p):
    data = p.read_bytes()
    return {"size": len(data), "head_hex": data[:24].hex()}


def append_ints(p, *vals):
    with open(p, "ab") as f:
        f.write(i32(*vals))
    return p.stat().st_size


def overwrite_head(p, *vals):
    with open(p, "r+b") as f:
        f.write(i32(*vals))
    return p.stat().st_size


def replace_with(p, data):
    tmp = p.with_suffix(".tmp")
    tmp.write_bytes(data)
    os.replace(tmp, p)
    return p.stat().st_size


def hold_op(step, own):
    if step == 11:
        if own:
            attempt("hw.read_own", lambda: read_info(PROFILE / f"{own}.xsdat"))
        else:
            for c in CANDIDATES:
                attempt(f"hw.read_{c}", lambda c=c: read_info(PROFILE / f"{c}.xsdat"))
        return
    p = PROFILE / f"spike_hold{step}.xsdat"
    if step == 7:
        attempt("hold7.read", lambda: read_info(p))
        attempt("hold7.append", lambda: append_ints(p, 703, 704))
    if step == 8:
        attempt("hold8.overwrite", lambda: overwrite_head(p, 801, 802))
    if step == 9:
        attempt("hold9.replace", lambda: replace_with(p, i32(901, 902, 903, 904)))
    if step == 10:
        attempt("hold10.remove", lambda: os.remove(p))


def external_rewrite(own):
    targets = [own] if own else CANDIDATES
    for c in targets:
        p = PROFILE / f"{c}.xsdat"
        attempt(f"ext.rewrite_{c}", lambda p=p: (p.write_bytes(i32(900, 901)), p.stat().st_size)[1])


def run():
    since = json.loads((HERE / "run" / "setup.json").read_text())["setup_time"]
    own = None
    name, log = None, None
    end = time.time() + 20
    while log is None and time.time() < end:
        name, log = find_log(since)
        time.sleep(0.5)
    if log:
        own = name
        note("boot_seen", file=name, rows=log["rows"][:2])
    else:
        note("boot_not_visible")
    for step in STEPS:
        write_ctl(step)
        if step in HOLD_STEPS:
            time.sleep(2.5)
            hold_op(step, own)
            got = wait_row("release", step, 30, since)
            if got is None:
                time.sleep(2)
        elif step == 5:
            time.sleep(3)
            snapshot("step05_before_rewrite")
            external_rewrite(own)
        else:
            got = wait_row("step", step, 40 if step in SLOW_STEPS else 10, since)
            if got:
                own = got
            elif step in SLOW_STEPS:
                time.sleep(20)
            else:
                time.sleep(4)
        snapshot(f"step{step:02d}")
    (HERE / "run").mkdir(exist_ok=True)
    (HERE / "run" / "driver_log.json").write_text(json.dumps(events, indent=1), encoding="utf-8")


def final():
    out = {}
    for c in CANDIDATES:
        p = PROFILE / f"{c}.xsdat"
        if p.exists() and p.stat().st_mtime > (HERE / "run" / "driver_log.json").stat().st_mtime - 3600:
            log, err = decode_log(p)
            if log:
                shutil.copy2(p, HERE / "run" / f"final_{c}.xsdat")
                out[c] = log
    (HERE / "run" / "final_log.json").write_text(json.dumps(out, indent=1), encoding="utf-8")
    print(json.dumps({k: {"ok": v["ok"], "rows": len(v["rows"]), "remaining": v["remaining"]} for k, v in out.items()}))


if __name__ == "__main__":
    cmd = sys.argv[1]
    if cmd == "setup":
        fixtures()
    elif cmd == "run":
        run()
    elif cmd == "final":
        final()
