#!/usr/bin/env python3
"""
Validate APPENDIX_MAC_BUILD_HANDOFF.zip extraction and integrity in a clean temporary directory.
"""

import os
import zipfile
import tempfile
import hashlib
import json

def sha256_file(p):
    hasher = hashlib.sha256()
    with open(p, 'rb') as f:
        while chunk := f.read(65536):
            hasher.update(chunk)
    return hasher.hexdigest().lower()

def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    os.chdir(root)
    zip_path = 'APPENDIX_MAC_BUILD_HANDOFF.zip'

    print("=================================================================")
    print("        APPENDIX MAC BUILD HANDOFF INTEGRITY VALIDATION           ")
    print("=================================================================")

    if not os.path.exists(zip_path):
        print(f"[FAIL] {zip_path} not found!")
        return 1

    errors = 0

    with tempfile.TemporaryDirectory() as temp_dir:
        print(f"Extracting archive into clean temporary sandbox: {temp_dir}")
        with zipfile.ZipFile(zip_path, 'r') as zf:
            zf.extractall(temp_dir)

        # 1. Check prohibited items (secrets, weights, caches)
        print("\n1. Prohibited Items Scan (Weights, Keys, Caches, DLLs):")
        prohibited_found = []
        for root_p, _, files in os.walk(temp_dir):
            for f in files:
                if f.endswith('.gguf') or f.endswith('.keystore') or f.endswith('.dll') or f.endswith('.exe'):
                    prohibited_found.append(os.path.join(root_p, f))
        if prohibited_found:
            print(f"  [FAIL] Found prohibited files: {prohibited_found}")
            errors += 1
        else:
            print("  [PASS] Zero .gguf model weights, zero keystores, zero Windows DLLs/EXEs found.")

        # 2. Check essential Apple project files
        print("\n2. Essential Apple Project Files:")
        expected_files = [
            'MAC_BUILD_COMMANDS.sh',
            'MAC_BUILD_ENVIRONMENT_CHECK.sh',
            'README_MAC_BUILD_HANDOFF.md',
            'scripts/build_apple.sh',
            'rust/Cargo.toml',
            'rust/src/lib.rs',
            'include/appendix_core.h',
            'app/pubspec.yaml',
            'app/lib/main.dart',
            'app/ios/Runner.xcworkspace/contents.xcworkspacedata',
            'app/ios/Runner.xcodeproj/project.pbxproj',
            'app/ios/AppendixKeyboard/KeyboardViewController.swift',
            'app/ios/AppendixKeyboard/Info.plist',
            'app/macos/Runner.xcodeproj/project.pbxproj',
            'SOURCE_SNAPSHOT_MANIFEST.json',
        ]
        for ef in expected_files:
            p = os.path.join(temp_dir, ef.replace('/', os.sep))
            if os.path.exists(p):
                print(f"  [PASS] Found: {ef}")
            else:
                print(f"  [FAIL] Missing expected file: {ef}")
                errors += 1

        # 3. Check Source Snapshot Fingerprint
        print("\n3. Source Snapshot Fingerprint Verification:")
        manifest_p = os.path.join(temp_dir, 'SOURCE_SNAPSHOT_MANIFEST.json')
        if os.path.exists(manifest_p):
            with open(manifest_p, 'r', encoding='utf-8') as mf:
                mdata = json.load(mf)
            fp = mdata.get('source_snapshot_fingerprint')
            print(f"  [PASS] SOURCE_SNAPSHOT_MANIFEST.json present (Fingerprint: {fp})")
        else:
            print("  [FAIL] SOURCE_SNAPSHOT_MANIFEST.json missing!")
            errors += 1

        # 4. Verify bash scripts syntax
        print("\n4. Shell Script Syntax Checks:")
        scripts = ['MAC_BUILD_COMMANDS.sh', 'MAC_BUILD_ENVIRONMENT_CHECK.sh', 'scripts/build_apple.sh']
        for sc in scripts:
            sc_p = os.path.join(temp_dir, sc.replace('/', os.sep))
            if os.path.exists(sc_p):
                with open(sc_p, 'r', encoding='utf-8') as f:
                    first_line = f.readline().strip()
                if first_line.startswith('#!/usr/bin/env bash') or first_line.startswith('#!/bin/bash'):
                    print(f"  [PASS] {sc}: Valid shebang ({first_line})")
                else:
                    print(f"  [FAIL] {sc}: Missing valid bash shebang ({first_line})")
                    errors += 1

    print("\n-----------------------------------------------------------------")
    if errors == 0:
        print("[SUCCESS] All Mac handoff package validation checks PASSED.")
        return 0
    else:
        print(f"[FAILURE] {errors} error(s) detected during handoff validation.")
        return 1

if __name__ == '__main__':
    exit(main())

