#!/usr/bin/env python3
"""
Create a full backup of the Appendix project working tree outside the project directory.
Excludes build caches, compiled binaries, models, and .git.
"""

import os
import shutil
import time

def backup():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    parent = os.path.dirname(root)
    backup_dir = os.path.join(parent, "Appendix_Phase9_Backup_20261115")
    
    print(f"Source: {root}")
    print(f"Destination: {backup_dir}")
    
    exclude_dirs = {'.git', 'target', 'build', '.dart_tool', 'models', 'dist', 'bin', 'obj', '.gradle', 'intermediates'}
    exclude_exts = {'.gguf', '.dll', '.exe', '.apk', '.aab', '.zip', '.tmp', '.log'}
    
    if os.path.exists(backup_dir):
        print(f"Removing existing backup directory: {backup_dir}")
        shutil.rmtree(backup_dir)
        
    os.makedirs(backup_dir, exist_ok=True)
    
    total_files = 0
    total_bytes = 0
    
    for dirpath, dirnames, filenames in os.walk(root):
        # Exclude directories in-place
        dirnames[:] = [d for d in dirnames if d not in exclude_dirs]
        
        rel_dir = os.path.relpath(dirpath, root)
        if rel_dir == '.':
            target_dir = backup_dir
        else:
            target_dir = os.path.join(backup_dir, rel_dir)
            os.makedirs(target_dir, exist_ok=True)
            
        for f in filenames:
            ext = os.path.splitext(f)[1].lower()
            if ext in exclude_exts:
                continue
            src_file = os.path.join(dirpath, f)
            dst_file = os.path.join(target_dir, f)
            shutil.copy2(src_file, dst_file)
            total_files += 1
            total_bytes += os.path.getsize(src_file)
            
    print(f"Backup successfully created at: {backup_dir}")
    print(f"Total files copied: {total_files}")
    print(f"Total size: {total_bytes} bytes ({total_bytes / (1024*1024):.2f} MB)")

if __name__ == '__main__':
    backup()
