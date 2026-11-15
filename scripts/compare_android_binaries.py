#!/usr/bin/env python3
"""
Compare native binaries across source jniLibs, stripped intermediate outputs,
APK-extracted binaries, and AAB-extracted binaries.
"""

import os
import hashlib
import zipfile
import glob

def sha256_file(p):
    with open(p, 'rb') as f:
        return hashlib.sha256(f.read()).hexdigest().lower()

def sha256_bytes(data):
    return hashlib.sha256(data).hexdigest().lower()

def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    os.chdir(root)

    print("=================================================================")
    print("       ANDROID NATIVE BINARY COMPREHENSIVE HASH AUDIT             ")
    print("=================================================================")

    abis = ['arm64-v8a', 'x86_64']

    # 1. Source jniLibs
    print("\n1. Source Built Native Libraries (Unstripped jniLibs):")
    source_hashes = {}
    for abi in abis:
        p = os.path.join('app', 'android', 'app', 'src', 'main', 'jniLibs', abi, 'libappendix_core.so')
        if os.path.exists(p):
            h = sha256_file(p)
            sz = os.path.getsize(p)
            source_hashes[abi] = (sz, h)
            print(f"  {abi}: {sz} bytes | SHA256: {h}")
        else:
            print(f"  {abi}: NOT FOUND")

    # 2. Stripped Intermediate Gradle outputs
    print("\n2. Android Gradle Stripped Intermediate Outputs (llvm-strip):")
    stripped_hashes = {}
    for abi in abis:
        # Search for stripped_native_libs release
        matches = glob.glob(f"app/build/**/stripped_native_libs/release/**/{abi}/libappendix_core.so", recursive=True)
        if matches:
            p = matches[0]
            h = sha256_file(p)
            sz = os.path.getsize(p)
            stripped_hashes[abi] = (sz, h)
            print(f"  {abi}: {sz} bytes | SHA256: {h} ({p})")
        else:
            print(f"  {abi}: NOT FOUND")

    # 3. APK-extracted libraries
    print("\n3. APK-Packaged Native Libraries (dist/appendix-android.apk):")
    apk_hashes = {}
    with zipfile.ZipFile('dist/appendix-android.apk', 'r') as z:
        for abi in abis:
            entry = f"lib/{abi}/libappendix_core.so"
            if entry in z.namelist():
                data = z.read(entry)
                h = sha256_bytes(data)
                sz = len(data)
                apk_hashes[abi] = (sz, h)
                print(f"  {abi}: {sz} bytes | SHA256: {h}")
            else:
                print(f"  {abi}: NOT FOUND in APK")

    # 4. AAB-extracted libraries
    print("\n4. AAB-Packaged Native Libraries (dist/appendix-android.aab):")
    aab_hashes = {}
    with zipfile.ZipFile('dist/appendix-android.aab', 'r') as z:
        for abi in abis:
            entry = f"base/lib/{abi}/libappendix_core.so"
            if entry in z.namelist():
                data = z.read(entry)
                h = sha256_bytes(data)
                sz = len(data)
                aab_hashes[abi] = (sz, h)
                print(f"  {abi}: {sz} bytes | SHA256: {h}")
            else:
                print(f"  {abi}: NOT FOUND in AAB")

    print("\n-----------------------------------------------------------------")
    print("VERIFICATION CHECKS:")
    for abi in abis:
        str_h = stripped_hashes.get(abi)
        apk_h = apk_hashes.get(abi)
        aab_h = aab_hashes.get(abi)
        src_h = source_hashes.get(abi)

        match_strip_apk = (str_h == apk_h) if (str_h and apk_h) else False
        match_apk_aab = (apk_h == aab_h) if (apk_h and aab_h) else False

        print(f"[{'PASS' if match_strip_apk else 'FAIL'}] {abi}: Stripped Gradle Output == APK Packaged Binary")
        print(f"[{'PASS' if match_apk_aab else 'FAIL'}] {abi}: APK Packaged Binary == AAB Packaged Binary")
        if src_h and str_h and src_h != str_h:
            print(f"[INFO] {abi}: Source unstripped binary ({src_h[0]} bytes) differs from stripped release binary ({str_h[0]} bytes) due to NDK llvm-strip debug symbol removal.")

    print("=================================================================")

if __name__ == '__main__':
    main()

