import os
import sys

def scan_file(filepath):
    rel_path = filepath.lower()
    # Skip .env, node_modules, .git, brain, and security_check.py itself
    if '.env' in rel_path or 'node_modules' in rel_path or '.git' in rel_path or 'brain' in rel_path or 'security_check.py' in rel_path:
        return []

    found = []
    try:
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            for i, line in enumerate(f, 1):
                if 'gsk_' in line:
                    found.append((i, line.strip()))
    except Exception as e:
        pass
    return found

def main():
    root_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    violations = []

    for dirpath, _, filenames in os.walk(root_dir):
        for fname in filenames:
            ext = os.path.splitext(fname)[1].lower()
            if ext in ['.dart', '.js', '.json', '.html', '.md', '.py', '.txt']:
                fpath = os.path.join(dirpath, fname)
                res = scan_file(fpath)
                if res:
                    for line_num, content in res:
                        violations.append(f"{fpath}:{line_num} -> {content}")

    print("\n--- SECURITY AUDIT SCAN RESULTS ---")
    if violations:
        print(f"FAILED: Found {len(violations)} potential secret exposures:")
        for v in violations:
            print("  - " + v)
        sys.exit(1)
    else:
        print("SUCCESS: Zero Groq API keys ('gsk_') found in source code files!")
        sys.exit(0)

if __name__ == '__main__':
    main()
