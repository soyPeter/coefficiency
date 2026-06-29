#!/usr/bin/env python3
"""
scripts/base64-scan.py — Fast base64-encoded secret detection
Usage:
  python3 scripts/base64-scan.py           # Scan staged files (default)
  python3 scripts/base64-scan.py --all     # Scan all tracked files
"""

import re
import base64
import subprocess
import sys
import os

# ── Exclusions ─────────────────────────────────────────────────────────────
EXCLUDE_FILES = re.compile(r'node_modules|\.git|dist|build|package-lock\.json|\.min\.(js|css)|secret-scan|base64-scan|\.idea|\.vscode|dev-portal/(dist|node_modules)|\.skillfish\.json')
EXCLUDE_EXTS = re.compile(r'\.(png|jpg|jpeg|gif|ico|pdf|zip|tar\.gz|mp3|mp4|woff2?|ttf|eot)$')

# Suspicious decoded patterns
SUSPICIOUS_PATTERNS = [
    b'password', b'secret', b'token', b'api_key', b'private_key',
    b'AKIA', b'ghp_', b'xoxb-', b'BEGIN PRIVATE', b'BEGIN RSA'
]

# Base64 regex: longer strings to reduce false positives
B64_REGEX = re.compile(r'[A-Za-z0-9+/]{40,}={0,2}')

def get_files(mode):
    """Get list of files to scan."""
    if mode == "staged":
        result = subprocess.run(
            ["git", "diff", "--cached", "--name-only", "--diff-filter=ACM"],
            capture_output=True, text=True
        )
    else:
        result = subprocess.run(
            ["git", "ls-files"],
            capture_output=True, text=True
        )
    
    files = []
    for line in result.stdout.strip().split('\n'):
        line = line.strip()
        if not line:
            continue
        if EXCLUDE_FILES.search(line):
            continue
        if EXCLUDE_EXTS.search(line):
            continue
        files.append(line)
    return files

def is_binary(filepath):
    """Quick binary file check."""
    try:
        with open(filepath, 'rb') as f:
            data = f.read(200)
            for b in data:
                if b < 9 or b in [11, 12] or (14 <= b <= 31) or b >= 127:
                    return True
    except:
        pass
    return False

def main():
    mode = "staged"
    if "--all" in sys.argv:
        mode = "all"
    
    print(f"🔍 Scanning for base64-encoded secrets ({mode} mode)...")
    
    files = get_files(mode)
    
    if not files:
        print("✅ No files to scan")
        sys.exit(0)
    
    all_results = []
    total_files = 0
    
    for filepath in files:
        if not os.path.isfile(filepath):
            continue
        
        try:
            if os.path.getsize(filepath) > 1048576:
                continue
        except:
            continue
        
        if is_binary(filepath):
            continue
        
        total_files += 1
        
        try:
            with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()
        except:
            continue
        
        for match in B64_REGEX.finditer(content):
            b64_str = match.group()
            
            # Skip if not valid base64 length
            if len(b64_str) % 4 != 0 and not b64_str.endswith('='):
                continue
            
            try:
                decoded = base64.b64decode(b64_str, validate=True)
            except:
                continue
            
            if not decoded:
                continue
            
            # Check that decoded content is mostly printable ASCII
            printable_ratio = sum(1 for b in decoded if 32 <= b <= 126) / len(decoded)
            if printable_ratio < 0.8:
                continue
            
            # Check for suspicious patterns
            is_suspicious = any(pattern in decoded for pattern in SUSPICIOUS_PATTERNS)
            
            # Also flag high-entropy strings that look like credentials
            if not is_suspicious and len(decoded) > 16:
                try:
                    decoded_str = decoded.decode('utf-8', errors='ignore')
                    has_lower = any(c.islower() for c in decoded_str)
                    has_upper = any(c.isupper() for c in decoded_str)
                    has_digit = any(c.isdigit() for c in decoded_str)
                    has_special = any(not c.isalnum() for c in decoded_str)
                    
                    # Only flag if it has high entropy AND looks like a credential format
                    if sum([has_lower, has_upper, has_digit, has_special]) >= 3:
                        # Additional check: must have some structure (not random binary)
                        if any(c in decoded_str for c in ['_', '-', '.', ':', '=']):
                            is_suspicious = True
                except:
                    pass
            
            if is_suspicious:
                line_num = content[:match.start()].count('\n') + 1
                preview = decoded[:50].decode('utf-8', errors='ignore').replace('\n', ' ')
                all_results.append((filepath, line_num, b64_str[:40], preview))
    
    # ── Report ────────────────────────────────────────────────────────────
    if all_results:
        print("")
        print("❌ Suspicious base64 detected:")
        print("")
        
        for filepath, line_num, b64, decoded in all_results:
            print(f"  {filepath}:{line_num}")
            print(f"    Base64: {b64}...")
            print(f"    Decoded: {decoded}")
            print("")
        
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print(f"❌ Result: {len(all_results)} suspicious base64 string(s) in {total_files} file(s)")
        print("")
        print("If these are false positives:")
        print("  1. Add file to EXCLUDE_FILES in scripts/base64-scan.py")
        print("  2. Use git commit --no-verify (not recommended)")
        print("")
        sys.exit(1)
    else:
        print(f"✅ No suspicious base64 detected in {total_files} file(s)")
        sys.exit(0)

if __name__ == "__main__":
    main()
