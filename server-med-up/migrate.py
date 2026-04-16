import psycopg2
conn = psycopg2.connect('postgresql://medintel:medintel@103.252.136.113:5435/medintel_orm')
cur = conn.cursor()
try:
    cur.execute("ALTER TABLE public.care_group_patients ADD COLUMN consent_status VARCHAR(64) DEFAULT 'granted';")
    conn.commit()
    print('Migration successful')
except Exception as e:
    print('Migration failed:', e)
finally:
    cur.close()
    conn.close()
