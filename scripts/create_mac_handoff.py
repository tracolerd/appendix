#!/usr/bin/env python3
"""
Create APPENDIX_MAC_BUILD_HANDOFF.zip for Apple development environment.
"""

import os
import zipfile
import hashlib

def sha256_file(p):
    hasher = hashlib.sha256()
    with open(p, 'rb') as f:
        while chunk := f.read(65536):
            hasher.update(chunk)
    return hasher.hexdigest().lower()

def should_include(rel_path):
    norm = rel_path.replace('\\', '/')
    
    # Exclude directories
    excluded_dirs = [
        '.git/', 'dist/', 'app/build/', 'rust/target/', 'app/.dart_tool/',
        'app/android/', '.idea/', '.vscode/', '.system_generated/', '__pycache__/'
    ]
    for d in excluded_dirs:
        if norm.startswith(d) or f"/{d}" in norm:
            return False

    # Exclude extensions / sensitive files
    excluded_exts = ['.gguf', '.keystore', '.dll', '.exe', '.pdb', '.log', '.tmp']
    for ext in excluded_exts:
        if norm.endswith(ext):
            return False

    # Include rules
    if norm in [
        'MAC_BUILD_COMMANDS.sh',
        'MAC_BUILD_ENVIRONMENT_CHECK.sh',
        'README_MAC_BUILD_HANDOFF.md',
        'LICENSE',
        'README.md',
        'INSTALL_MACOS.md',
        'INSTALL_IOS.md',
        'THIRD_PARTY_NOTICES.md',
        'SOURCE_SNAPSHOT_MANIFEST.json',
        'models/model_manifest.json',
        'models/tokenizer.json',
    ]:
        return True

    if norm.startswith('scripts/') and not norm.endswith('.pyc'):
        return True
    if norm.startswith('include/'):
        return True
    if norm.startswith('rust/'):
        return True
    if norm.startswith('app/'):
        # Ensure only cross-platform, ios, and macos files are included
        return not norm.startswith('app/android/')

    return False

def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    os.chdir(root)
    zip_path = 'APPENDIX_MAC_BUILD_HANDOFF.zip'

    print("Creating APPENDIX_MAC_BUILD_HANDOFF.zip...")
    total_files = 0
    total_uncompressed_bytes = 0

    with zipfile.ZipFile(zip_path, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=9) as zf:
        for dirpath, dirnames, filenames in os.walk('.'):
            # prune excluded dirs
            dirnames[:] = [d for d in dirnames if d not in ['.git', 'dist', 'build', 'target', '.dart_tool', 'android']]
            for f in sorted(filenames):
                full_path = os.path.join(dirpath, f)
                rel_path = os.path.relpath(full_path, '.')
                if should_include(rel_path):
                    # enforce POSIX path inside zip
                    arcname = rel_path.replace('\\', '/')
                    zf.write(full_path, arcname)
                    total_files += 1
                    total_uncompressed_bytes += os.path.getsize(full_path)

    zip_size = os.path.getsize(zip_path)
    zip_hash = sha256_file(zip_path)

    print(f"Archive Created Successfully: {zip_path}")
    print(f"  Total Files Included:     {total_files}")
    print(f"  Uncompressed Content:     {total_uncompressed_bytes:,} bytes")
    print(f"  Compressed ZIP Size:      {zip_size:,} bytes")
    print(f"  Archive SHA-256 Hash:     {zip_hash}")

if __name__ == '__main__':
    main()

