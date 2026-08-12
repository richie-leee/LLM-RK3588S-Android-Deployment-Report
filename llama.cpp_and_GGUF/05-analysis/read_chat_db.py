import sqlite3, os
p = os.path.join(os.path.dirname(__file__), 'logs', 'chat.db')
con = sqlite3.connect(p)
cur = con.cursor()
cur.execute("SELECT name FROM sqlite_master WHERE type='table'")
tables = [r[0] for r in cur.fetchall()]
print('TABLES:', tables)
for t in tables:
    if t.startswith('sqlite_') or t.startswith('android_'):
        continue
    cur.execute('PRAGMA table_info(%s)' % t)
    cols = [c[1] for c in cur.fetchall()]
    cur.execute('SELECT COUNT(*) FROM %s' % t)
    n = cur.fetchone()[0]
    print('\n== %s  rows=%d' % (t, n))
    print('   cols:', cols)
con.close()
