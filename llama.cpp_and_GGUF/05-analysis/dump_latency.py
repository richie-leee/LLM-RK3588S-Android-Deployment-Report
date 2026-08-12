import sqlite3, os, collections, statistics

p = os.path.join(os.path.dirname(__file__), 'logs', 'chat.db')
con = sqlite3.connect(p)
con.text_factory = lambda b: b.decode('utf-8', 'replace')
cur = con.cursor()

cur.execute("SELECT sessionId, modelId FROM Session")
smap = dict(cur.fetchall())

cur.execute("SELECT sessionId, time, type, text, imageUri FROM ChatData ORDER BY sessionId, time")
rows = cur.fetchall()

lat = collections.defaultdict(list)
imgq = collections.Counter()
txtlen = collections.defaultdict(list)
prev = {}

for sid, t, typ, text, img in rows:
    model = smap.get(sid, "?")
    if typ == 0:
        prev[sid] = (t, img)
        if img:
            imgq[model] += 1
    else:
        if sid in prev:
            t0, img0 = prev.pop(sid)
            d = (t - t0) / 1000.0
            if 0 < d < 900:
                lat[model].append((d, bool(img0)))
        if text:
            txtlen[model].append(len(text))

print("%-46s %5s %8s %8s %8s %6s" % ("MODEL", "N", "MED_s", "MIN_s", "MAX_s", "IMG"))
for m in sorted(lat):
    ds = [d for d, _ in lat[m]]
    if not ds:
        continue
    print("%-46s %5d %8.1f %8.1f %8.1f %6d" % (
        m.split("/")[-1][:46], len(ds), statistics.median(ds), min(ds), max(ds), imgq[m]))ess...[truncated 24 chars]