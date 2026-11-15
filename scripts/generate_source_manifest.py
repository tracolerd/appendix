#!/usr/bin/env python3
"""
Generate SOURCE_SNAPSHOT_MANIFEST.json recording exact dirty working tree state.
"""

import os
import hashlib
import json
import subprocess

def compute_sha256(filepath):
    hasher = hashlib.sha256()
    with open(filepath, 'rb') as f:
        while chunk := f.read(65536):
            hasher.update(chunk)
    return hasher.hexdigest().lower()

def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

    res = subprocess.run(['git', 'status', '--porcelain=v1'], cwd=root, capture_output=True, text=True, check=True)
    lines = res.stdout.strip().split('\n')

    modified_tracked = []
    untracked_relevant = []

    excluded_prefixes = ('dist/', 'dist\\', '.git/', '.git\\', 'app/build/', 'app/build\\', 'rust/target/', 'rust/target\\', '.dart_tool/', '.dart_tool\\', 'models/', 'models\\')
    excluded_exts = ('.gguf', '.keystore', '.db', '.log', '.tmp')

    for line in lines:
        if not line:
            continue
        status = line[:2]
        filepath = line[3:].strip()
        if filepath.startswith('"') and filepath.endswith('"'):
            filepath = filepath[1:-1]
        
        norm_path = filepath.replace('\\', '/')
        if any(norm_path.startswith(p) for p in excluded_prefixes) or any(norm_path.endswith(e) for e in excluded_exts):
            continue

        full_path = os.path.join(root, filepath)
        if not os.path.isfile(full_path):
            continue

        h = compute_sha256(full_path)
        item = {
            'path': norm_path,
            'sha256': h,
            'size_bytes': os.path.getsize(full_path)
        }

        if status.startswith('?') or status.endswith('?'):
            untracked_relevant.append(item)
        else:
            modified_tracked.append(item)

    all_items = sorted(modified_tracked + untracked_relevant, key=lambda x: x['path'])
    fingerprint_hasher = hashlib.sha256()
    for it in all_items:
        fingerprint_hasher.update(f"{it['path']}:{it['sha256']}\n".encode('utf-8'))
    combined_fingerprint = fingerprint_hasher.hexdigest()

    manifest = {
        'schema_version': '1.0.0',
        'base_commit': '6394fb3c8f41a051be062b0460225f465626c110',
        'branch': 'feat/local-ai-inference',
        'working_tree_status': 'DIRTY_UNCOMMITTED_CHANGES_PRESENT',
        'source_snapshot_fingerprint': combined_fingerprint,
        'total_modified_tracked_files': len(modified_tracked),
        'total_untracked_source_files': len(untracked_relevant),
        'modified_tracked_files': sorted(modified_tracked, key=lambda x: x['path']),
        'untracked_source_files': sorted(untracked_relevant, key=lambda x: x['path']),
        'notes': 'This snapshot records the exact source code state used for Phase 8/8.1 release candidate validation builds. Artifacts were built against this dirty working tree, NOT from a clean git commit.'
    }

    out_path = os.path.join(root, 'SOURCE_SNAPSHOT_MANIFEST.json')
    with open(out_path, 'w', encoding='utf-8') as f:
        json.dump(manifest, f, indent=2)

    print(f"Generated SOURCE_SNAPSHOT_MANIFEST.json with fingerprint: {combined_fingerprint}")
    print(f"Modified tracked files: {len(modified_tracked)}, Untracked relevant files: {len(untracked_relevant)}")

if __name__ == '__main__':
    main()

