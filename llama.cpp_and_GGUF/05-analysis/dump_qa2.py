import sqlite3, os, io, json
os.chdir(os.path.dirname(os.path.abspath(__file__)))
con = sqlite3.connect('logs/chat_debug.db')
con.text_factory = lambda b: b.decode('utf-8', 'replace')
cur = con.cursor()
cur.execute("SELECT sessionId, modelId FROM Session")
SM = dict(cur.fetchall())
cur.execute("SELECT sessionId, type, text, imageUri FROM ChatData ORDER BY _id")
out = io.open('logs/qa_debug.md', 'w', encoding='utf-8')
cur_s = None
for sid, typ, text, img in cur.fetchall():
    if sid != cur_s:
        cur_s = sid
        m = SM.get(sid, '?').split('/')[-1]
        out.write('\n\n## [%s] %s\n' % (m, sid[-13:]))
    role = 'USER' if typ == 2 else 'ASST'
    tag = ' [IMG]' if img else ''
    t = (text or '').replace('\n', ' ')[:400]
    out.write('- **%s**%s: %s\n' % (role, tag, t))
out.close()
print('ok')
