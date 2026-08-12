import sqlite3, collections, json, re, os
os.chdir(os.path.dirname(os.path.abspath(__file__)))
con = sqlite3.connect('logs/chat_debug.db')
con.text_factory = lambda b: b.decode('utf-8', 'replace')
cur = con.cursor()
cur.execute("SELECT sessionId, modelId FROM Session")
smap = dict(cur.fetchall())
cur.execute("SELECT sessionId, type, text, imageUri FROM ChatData ORDER BY _id")
rows = cur.fetchall()

def short(m):
    return m.split('/')[-1].replace('-MNN', '')

def garbled(t):
    if not t:
        return False
    t = t.strip()
    if len(t) < 8:
        return False
    for unit in ['图像', '图片', '的', '是', 'the ', 'image']:
        if t.count(unit) >= 8 and len(set(t)) < 12:
            return True
    if len(set(t)) <= 4:
        return True
    return False

st = collections.defaultdict(lambda: {'sess': set(), 'user': 0, 'asst': 0,
                                      'img': 0, 'garb': 0, 'empty': 0, 'turns': []})
per_sess = collections.defaultdict(int)
for sid, typ, text, iuri in rows:
    m = short(smap.get(sid, 'UNKNOWN'))
    d = st[m]
    d['sess'].add(sid)
    if typ == 2:
        d['user'] += 1
        per_sess[sid] += 1
        if iuri:
            d['img'] += 1
    else:
        d['asst'] += 1
        if not text or not text.strip():
            d['empty'] += 1
        elif garbled(text):
            d['garb'] += 1

for sid, n in per_sess.items():
    st[short(smap.get(sid, 'UNKNOWN'))]['turns'].append(n)

print('%-46s %4s %5s %5s %5s %5s %6s %5s' % ('MODEL', 'SESS', 'USER', 'ASST', 'IMG', 'GARB', 'GARB%', 'MAXT'))
out = {}
for m in sorted(st):
    d = st[m]
    tot = d['asst']
    bad = d['garb'] + d['empty']
    pct = (bad * 100.0 / tot) if tot else 0
    mx = max(d['turns']) if d['turns'] else 0
    print('%-46s %4d %5d %5d %5d %5d %5.1f%% %5d' % (m[:46], len(d['sess']), d['user'], tot, d['img'], bad, pct, mx))
    out[m] = {'sess': len(d['sess']), 'user': d['user'], 'asst': tot,
              'img': d['img'], 'bad': bad, 'bad_pct': round(pct, 1), 'max_turn': mx}
json.dump(out, open('logs/mnn_stats_debug.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
print('\nsaved logs/mnn_stats_debug.json')
