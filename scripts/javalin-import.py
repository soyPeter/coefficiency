#!/usr/bin/env python3
"""
One-shot import: decrypt Javalin database and export Jooby-compatible SQL dump.
Usage: python3 javalin-import.py <password>
"""

import sys
import json
import hashlib
import hmac
from pathlib import Path

JAVALIN_DATA = Path("/Users/peter/projects/javalin-coef-calc/data")
OUTPUT = Path("/tmp/javalin-import.sql")

def read_key_file():
    content = JAVALIN_DATA.joinpath(".db-key").read_text().strip()
    parts = content.split(":")
    salt = bytes.fromhex(parts[0])
    verifier = bytes.fromhex(parts[1])
    return salt, verifier

def derive_key(password, salt):
    return hashlib.pbkdf2_hmac("sha256", password.encode(), salt, 100000, dklen=32)

def decrypt_file(password):
    from cryptography.hazmat.primitives.ciphers.aead import AESGCM
    salt, _ = read_key_file()
    key = derive_key(password, salt)
    data = JAVALIN_DATA.joinpath("app.db.enc").read_bytes()
    # salt (16) + iv (12) + ciphertext
    iv = data[:12]
    ct = data[12:]
    aesgcm = AESGCM(key)
    return aesgcm.decrypt(iv, ct, None)

def dump_database(db_path, output_path):
    import sqlite3
    conn = sqlite3.connect(str(db_path))
    
    tables = ["users", "settings", "cost_concepts", "consultants", 
              "tenure_bonuses", "quarterly_bonuses", "bonus_breakdown_cache"]
    
    with open(output_path, "w") as f:
        f.write("PRAGMA foreign_keys = OFF;\nBEGIN TRANSACTION;\n")
        
        for table in tables:
            try:
                rows = conn.execute(f"SELECT * FROM \"{table}\"").fetchall()
                if not rows:
                    continue
                columns = [desc[0] for desc in conn.execute(f"SELECT * FROM \"{table}\" LIMIT 0").description]
                
                col_names = ", ".join(f'"{c}"' for c in columns)
                placeholders = ", ".join("?" for _ in columns)
                insert_sql = f'INSERT INTO "{table}" ({col_names}) VALUES ({placeholders});'
                
                for row in rows:
                    # Convert row to SQL literal values
                    vals = []
                    for v in row:
                        if v is None:
                            vals.append("NULL")
                        elif isinstance(v, (int, float)):
                            vals.append(str(v))
                        else:
                            s = str(v).replace("'", "''")
                            vals.append(f"'{s}'")
                    f.write(f'INSERT INTO "{table}" ({col_names}) VALUES ({', '.join(vals)});\n')
                    
            except Exception as e:
                print(f"  Skipping {table}: {e}", file=sys.stderr)
        
        f.write("COMMIT;\nPRAGMA foreign_keys = ON;\n")
    
    conn.close()

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 javalin-import.py <password>")
        sys.exit(1)
    
    password = sys.argv[1]
    print(f"Decrypting Javalin database with password '{password}'...")
    
    try:
        decrypted = decrypt_file(password)
        db_path = "/tmp/javalin-decrypted.db"
        Path(db_path).write_bytes(decrypted)
        print(f"Decrypted to {db_path} ({len(decrypted)} bytes)")
        
        print("Exporting SQL dump with column names...")
        dump_database(db_path, OUTPUT)
        print(f"SQL dump written to {OUTPUT}")
        print(f"Size: {OUTPUT.stat().st_size} bytes")
        
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        sys.exit(1)
