#!/usr/bin/env python3
"""Check that a bound method's declared return type matches its Procedure suffix.

For a ZERO-argument method the dispatch shape follows from the return type
alone, so the two must agree: #INT means the framework calls it as an Integer,
#FLOAT as a double, and anything else comes back through *out. A mismatch
compiles and returns whatever happens to be in the register - the failure this
exists to catch. GDTicker_get_mark_count was bound #INT and declared Procedure.d.

    tools/check-returns.py
"""
import glob, io, os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(ROOT)
WANT = {"#INT": ("i", "l"), "#FLOAT": ("d",)}
NOT_OUT = {"#VOID"}          # void returns no value, so no suffix either way

files = [f for f in glob.glob("*.pbi") + glob.glob("*.pb")
         + glob.glob("skeleton/*.pb") + glob.glob("selftest/*.pb")
         if not f.startswith("generated/")]

bad, checked = [], 0
for f in files:
    s = io.open(f, encoding="utf-8", errors="replace").read()
    pat = r'bind_method\(D_METHOD\("([^"]+)"\)\s*,\s*@([A-Za-z0-9_]+)\(\)\s*,\s*(#[A-Z0-9_]+)\)'
    for m in re.finditer(pat, s):
        name, proc, ret = m.groups()
        checked += 1
        pm = re.search(r'Procedure(\.[a-z])?\s+' + re.escape(proc) + r'\s*\(', s)
        if not pm:
            bad.append((f, name, proc, ret, "procedure not declared"))
            continue
        suffix = (pm.group(1) or "")[1:]
        if ret in WANT:
            if suffix not in WANT[ret]:
                bad.append((f, name, proc, ret, "declared ." + (suffix or "none")))
        elif ret not in NOT_OUT and suffix:
            bad.append((f, name, proc, ret, "declared ." + suffix + ", expected *out"))

for b in bad:
    print("%s: %s -> %s bound %s, %s" % b, file=sys.stderr)
if bad:
    print("return-type check FAILED: %d of %d" % (len(bad), checked), file=sys.stderr)
    sys.exit(1)
print("return types: all %d zero-argument bindings match their declaration" % checked)
