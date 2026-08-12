import sqlite3, os, collections, json, re

BASE = os.path.dirname(os.path.abspath(__file__))
con = sqlite3.connect(os.path.join(BASE, 'logs', 'chat.db'))
con.text_factory = lambda b: b.decode('utf-8', 'replace')
cur = con.cursor()

cur.execute("SELECT sessionId, modelId FROM Session")
smap = dict(cur.fetchall())

cur.execute("SELECT sessionId, time, type, text, imageUri FROM ChatData ORDER BY _id")
rows = cur.fetchall()

def short(m):
    return m.split('/')[-1].replace('-MNN', '')

def i...[truncated 24 chars]...[truncated 24 chars]