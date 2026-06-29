#!/usr/bin/env python3
"""
scripts/secret-scan.py — Fast secret detection for pre-commit/CI
Usage:
  python3 scripts/secret-scan.py           # Scan staged files (default)
  python3 scripts/secret-scan.py --all     # Scan all tracked files
"""

import re
import subprocess
import sys
import os

# ── Secret Patterns ────────────────────────────────────────────────────────
PATTERNS = [
    ("Anthropic API Key", r"sk-ant-[a-zA-Z0-9]{32,}"),
    ("AWS Access Key ID", r"AKIA[0-9A-Z]{16}"),
    ("AWS Secret Access Key", "['\"][0-9a-zA-Z/+]{40}['\"]"),
    ("GitHub Token", r"gh[pousr]_[A-Za-z0-9_]{36,}"),
    ("GitHub OAuth", r"gho_[A-Za-z0-9_]{36}"),
    ("Slack Token", r"xox[baprs]-[0-9]{10,13}-[0-9]{10,13}"),
    ("Stripe Live Key", r"sk_live_[a-zA-Z0-9]{24,}"),
    ("Stripe Test Key", r"sk_test_[a-zA-Z0-9]{24,}"),
    ("SendGrid Key", r"SG\.[a-zA-Z0-9]{22,}"),
    ("JWT Token", r"eyJ[a-zA-Z0-9_-]*\.eyJ[a-zA-Z0-9_-]*\.[a-zA-Z0-9_-]*"),
    ("Private Key", r"-----BEGIN (RSA |DSA |EC |OPENSSH )?PRIVATE KEY-----"),
    ("Password assignment", "^\\s*password\\s*=\\s*['\"][^'\"]{8,}['\"]"),
    ("Secret assignment", "^\\s*secret\\s*=\\s*['\"][^'\"]{8,}['\"]"),
    ("API Key assignment", "^\\s*api[_-]?key\\s*=\\s*['\"][^'\"]{16,}['\"]"),
    ("Auth Token", "^\\s*auth[_-]?token\\s*=\\s*['\"][^'\"]{16,}['\"]"),
    ("Bearer Token", r"^\s*Authorization:\s*Bearer\s+[a-zA-Z0-9_\-\.]{20,}"),
    ("Basic Auth", r"^\s*Authorization:\s*Basic\s+[A-Za-z0-9+/]{20,}={0,2}"),
    ("URL with password", r"https?://[^:]+:[^@]+@"),
]

# ── Exclusions ─────────────────────────────────────────────────────────────
EXCLUDE_FILES = re.compile(r'node_modules|\.git|dist|build|package-lock\.json|\.min\.(js|css)|secret-scan|base64-scan|\.idea|\.vscode|dev-portal/(dist|node_modules)|\.skillfish\.json|\.env\.test|\.env\.example|\.env\.local\.example')
EXCLUDE_EXTS = re.compile(r'\.(png|jpg|jpeg|gif|ico|pdf|zip|tar\.gz|mp3|mp4|woff2?|ttf|eot)$')

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

def scan_file(filepath):
    """Scan a single file for secrets. Returns list of (line_num, pattern_name, line)."""
    results = []
    
    try:
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            lines = f.readlines()
    except:
        return results
    
        for line_num, line in enumerate(lines, 1):
            # Skip lines that end with ... (likely documentation examples)
            stripped = line.strip()
            if stripped.endswith('...') or stripped.endswith('…'):
                continue
            
            for pattern_name, pattern_regex in PATTERNS:
                if re.search(pattern_regex, line, re.IGNORECASE):
                    results.append((line_num, pattern_name, line.strip()))
                    break  # Only report first match per line
    
    return results

def main():
    mode = "staged"
    if "--all" in sys.argv:
        mode = "all"
    
    print(f"🔍 Scanning for secrets ({mode} mode)...")
    
    files = get_files(mode)
    
    if not files:
        print("✅ No files to scan")
        sys.exit(0)
    
    all_results = []
    total_files = 0
    
    for filepath in files:
        if not os.path.isfile(filepath):
            continue
        
        # Skip large files
        try:
            if os.path.getsize(filepath) > 1048576:
                continue
        except:
            continue
        
        # Skip binary
        if is_binary(filepath):
            continue
        
        total_files += 1
        results = scan_file(filepath)
        
        for line_num, pattern_name, line in results:
            all_results.append((filepath, line_num, pattern_name, line))
    
    # ── Report ────────────────────────────────────────────────────────────
    if all_results:
        print("")
        print("❌ Potential secrets detected:")
        print("")
        
        for filepath, line_num, pattern_name, line in all_results:
            print(f"  {pattern_name}")
            print(f"    {filepath}:{line_num}: {line}")
            print("")
        
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print(f"❌ Result: {len(all_results)} secret pattern(s) found in {total_files} file(s)")
        print("")
        print("If these are false positives:")
        print("  1. Add file to EXCLUDE_FILES in scripts/secret-scan.py")
        print("  2. Use git commit --no-verify (not recommended)")
        print("")
        sys.exit(1)
    else:
        print(f"✅ No secrets detected in {total_files} file(s)")
        sys.exit(0)

if __name__ == "__main__":
    main()
