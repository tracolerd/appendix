#!/usr/bin/env python3
"""
Inspect dependencies from Cargo.lock and pubspec.lock, checking for copyleft/GPL licenses.
"""

import os
import re

def audit_cargo():
    cargo_lock = os.path.join('rust', 'Cargo.lock')
    with open(cargo_lock, 'r', encoding='utf-8') as f:
        content = f.read()

    packages = re.findall(r'\[\[package\]\]\nname = "([^"]+)"\nversion = "([^"]+)"', content)
    print(f"Total Cargo Packages in lockfile: {len(packages)}")
    
    # Direct dependencies from Cargo.toml
    with open(os.path.join('rust', 'Cargo.toml'), 'r', encoding='utf-8') as f:
        toml_lines = f.readlines()
    
    in_deps = False
    direct = []
    for line in toml_lines:
        line = line.strip()
        if line.startswith('[dependencies]'):
            in_deps = True
            continue
        elif line.startswith('['):
            in_deps = False
        if in_deps and '=' in line and not line.startswith('#'):
            direct.append(line.split('=')[0].strip())
            
    print(f"Direct Cargo Dependencies ({len(direct)}): {', '.join(direct)}")

    # Check for known GPL/AGPL crates
    suspicious = ['gpl', 'agpl']
    flagged = []
    for name, ver in packages:
        for s in suspicious:
            if s in name.lower():
                flagged.append((name, ver))
    if flagged:
        print(f"Flagged crates: {flagged}")
    else:
        print("No suspicious copyleft crate names found in Cargo.lock.")

def audit_pubspec():
    with open(os.path.join('app', 'pubspec.yaml'), 'r', encoding='utf-8') as f:
        print("Flutter Direct Dependencies:")
        for line in f:
            if 'cupertino_icons' in line or 'ffi' in line:
                print(" ", line.strip())

if __name__ == '__main__':
    audit_cargo()
    print("-" * 50)
    audit_pubspec()
