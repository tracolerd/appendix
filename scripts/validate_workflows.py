#!/usr/bin/env python3
"""
Validate workflow YAML syntax and structure
"""

import sys

try:
    import yaml
    has_yaml = True
except ImportError:
    has_yaml = False

def validate_file(filepath):
    print(f"Validating {filepath}...")
    if has_yaml:
        with open(filepath, 'r', encoding='utf-8') as f:
            data = yaml.safe_load(f)
        print(f"  [OK] Valid YAML syntax.")
        print(f"  Name: {data.get('name')}")
        print(f"  Triggers: {list(data.get('on', {}).keys()) if isinstance(data.get('on'), dict) else data.get('on')}")
        print(f"  Permissions: {data.get('permissions')}")
        print(f"  Jobs ({len(data.get('jobs', {}))}): {list(data.get('jobs', {}).keys())}")
    else:
        print("  [SKIP] PyYAML not available in Python environment.")

if __name__ == '__main__':
    validate_file('.github/workflows/ci.yml')
    print("-" * 50)
    validate_file('.github/workflows/release.yml')

