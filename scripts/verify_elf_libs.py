#!/usr/bin/env python3
import os
import hashlib
import struct

libs = [
    ('arm64-v8a', os.path.join('app', 'android', 'app', 'src', 'main', 'jniLibs', 'arm64-v8a', 'libappendix_core.so')),
    ('x86_64', os.path.join('app', 'android', 'app', 'src', 'main', 'jniLibs', 'x86_64', 'libappendix_core.so'))
]

for abi, p in libs:
    if not os.path.exists(p):
        print(f"[FAIL] {p} does not exist!")
        continue
    sz = os.path.getsize(p)
    with open(p, 'rb') as f:
        data = f.read()
    h = hashlib.sha256(data).hexdigest()
    magic = data[:4]
    elf_class = data[4]
    data_enc = data[5]
    e_machine = struct.unpack('<H', data[18:20])[0] if data_enc == 1 else struct.unpack('>H', data[18:20])[0]
    arch_str = 'AArch64 (ARM 64-bit)' if e_machine == 183 else ('x86-64 (AMD/Intel 64-bit)' if e_machine == 62 else f'Unknown ({e_machine})')
    print(f"=== {abi} ===")
    print(f"  Path:        {p}")
    print(f"  Size:        {sz} bytes")
    print(f"  SHA-256:     {h}")
    print(f"  ELF Magic:   {magic == b'\x7fELF'} (0x{magic.hex()})")
    print(f"  Class:       {elf_class} (2 = 64-bit)")
    print(f"  Machine:     {e_machine} ({arch_str})")

