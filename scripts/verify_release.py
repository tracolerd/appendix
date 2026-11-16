#!/usr/bin/env python3
"""
Appendix Release Verification & Audit Script
Validates release artifacts against dist/SHA256SUMS.txt, dist/BUILD_MANIFEST.json,
and dist/SOURCE_SNAPSHOT_MANIFEST.json.
"""

import hashlib
import json
import os
import sys

def compute_sha256(filepath):
    hasher = hashlib.sha256()
    with open(filepath, 'rb') as f:
        while chunk := f.read(65536):
            hasher.update(chunk)
    return hasher.hexdigest().lower()

def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    dist_dir = os.path.join(root, 'dist')
    manifest_path = os.path.join(dist_dir, 'BUILD_MANIFEST.json')
    source_manifest_path = os.path.join(dist_dir, 'SOURCE_SNAPSHOT_MANIFEST.json')
    sums_path = os.path.join(dist_dir, 'SHA256SUMS.txt')

    print("================================================================")
    print("      APPENDIX RELEASE VERIFICATION & INTEGRITY AUDIT           ")
    print("================================================================")

    if not os.path.exists(dist_dir):
        print(f"[FAIL] dist directory not found at: {dist_dir}")
        sys.exit(1)

    if not os.path.exists(manifest_path):
        print(f"[FAIL] BUILD_MANIFEST.json not found in {dist_dir}")
        sys.exit(1)

    with open(manifest_path, 'r', encoding='utf-8') as f:
        manifest = json.load(f)

    print(f"Project:             {manifest.get('project')}")
    print(f"Version:             {manifest.get('app_version')}+{manifest.get('build_number')}")
    print(f"Git Commit:          {manifest.get('git_commit')}")
    print(f"Working Tree Status: {manifest.get('working_tree_status')}")
    print(f"Snapshot Hash:       {manifest.get('source_snapshot_fingerprint')}")
    print(f"Release Verdict:     {manifest.get('distribution_readiness_verdict')}")
    print("----------------------------------------------------------------")

    errors = 0

    # 1. Source Snapshot Provenance Verification
    if os.path.exists(source_manifest_path):
        with open(source_manifest_path, 'r', encoding='utf-8') as f:
            src_manifest = json.load(f)
        expected_fp = src_manifest.get('source_snapshot_fingerprint')
        actual_fp = manifest.get('source_snapshot_fingerprint')
        if expected_fp == actual_fp:
            print(f"[PASS] Source snapshot fingerprint verified: {actual_fp}")
        else:
            print(f"[FAIL] Source snapshot fingerprint mismatch! Manifest: {actual_fp}, Snapshot: {expected_fp}")
            errors += 1
    else:
        print("[WARN] SOURCE_SNAPSHOT_MANIFEST.json not found in dist/")

    # 2. SHA256SUMS.txt Verification
    if not os.path.exists(sums_path):
        print(f"[FAIL] SHA256SUMS.txt not found in {dist_dir}")
        sys.exit(1)

    seen_files = set()
    listed_files = set()

    with open(sums_path, 'r', encoding='utf-8') as f:
        for line_num, line in enumerate(f, 1):
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            parts = line.split(None, 1)
            if len(parts) != 2:
                print(f"[FAIL] Malformed line {line_num} in SHA256SUMS.txt")
                errors += 1
                continue

            expected_hash, filename = parts[0].strip().lower(), parts[1].strip()

            # Path traversal prevention
            if '..' in filename or filename.startswith('/') or filename.startswith('\\'):
                print(f"[FAIL] Potential path traversal detected in line {line_num}: {filename}")
                errors += 1
                continue

            # Duplicate entry detection
            if filename in seen_files:
                print(f"[FAIL] Duplicate entry detected for {filename} on line {line_num}")
                errors += 1
                continue
            seen_files.add(filename)
            listed_files.add(filename)

            file_path = os.path.join(dist_dir, filename)
            if not os.path.exists(file_path):
                print(f"[FAIL] Missing artifact: {filename}")
                errors += 1
                continue

            actual_hash = compute_sha256(file_path)
            if actual_hash == expected_hash:
                print(f"[PASS] {filename} (SHA256 OK)")
            else:
                print(f"[FAIL] {filename} CHECKSUM MISMATCH!")
                print(f"       Expected: {expected_hash}")
                print(f"       Actual:   {actual_hash}")
                errors += 1

    # 3. Check for unlisted files in dist/
    all_dist_files = set(f for f in os.listdir(dist_dir) if os.path.isfile(os.path.join(dist_dir, f)) and f != 'SHA256SUMS.txt')
    unlisted = all_dist_files - listed_files
    if unlisted:
        for u in unlisted:
            print(f"[FAIL] File exists in dist/ but is omitted from SHA256SUMS.txt: {u}")
            errors += 1

    # 4. Manifest size verification
    for artifact in manifest.get('built_artifacts', []):
        aname = artifact.get('name')
        expected_size = artifact.get('size_bytes')
        apath = os.path.join(dist_dir, aname)
        if os.path.exists(apath):
            actual_size = os.path.getsize(apath)
            if actual_size == expected_size:
                print(f"[PASS] {aname} size matches manifest ({actual_size} bytes)")
            else:
                print(f"[FAIL] {aname} size mismatch! Manifest: {expected_size}, Actual: {actual_size}")
                errors += 1

    print("----------------------------------------------------------------")
    print("LEGAL & CRYPTOGRAPHIC DISCLAIMER:")
    print("A successful checksum comparison demonstrates file integrity against")
    print("the manifest list. It does NOT constitute proof of supply-chain")
    print("authenticity, nor does it imply production code-signing certification.")
    print("----------------------------------------------------------------")

    if errors == 0:
        print(f"[SUCCESS] All {len(listed_files)} release artifacts and manifest entries verified.")
        sys.exit(0)
    else:
        print(f"[FAILURE] {errors} verification error(s) detected.")
        sys.exit(1)

if __name__ == '__main__':
    main()
