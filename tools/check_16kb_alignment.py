#!/usr/bin/env python3
"""Verify 16 KB page-size compliance of every native library in an APK/AAB.

Google Play rejects releases whose native libraries don't support 16 KB memory
pages. A library is compliant when every PT_LOAD segment in its ELF program
header has p_align >= 0x4000 (16384).

Usage:
    python tools/check_16kb_alignment.py build/app/outputs/bundle/release/app-release.aab
    python tools/check_16kb_alignment.py build/app/outputs/flutter-apk/*.apk

Exit code 0 = compliant (safe to upload), 1 = non-compliant (Play will reject).

Note: 16 KB pages only exist on 64-bit Android, so upstream vendors ship
4 KB-aligned armeabi-v7a binaries by design. This app is built 64-bit only
(see abiFilters in android/app/build.gradle), so no armeabi-v7a libs should
appear here at all.
"""
import collections
import re
import struct
import sys
import zipfile

PAGE_16KB = 0x4000
PT_LOAD = 1


def load_segment_aligns(data):
    """Return p_align of every PT_LOAD segment, or None if not an ELF file."""
    if data[:4] != b"\x7fELF":
        return None
    is64 = data[4] == 2
    endian = "<" if data[5] == 1 else ">"

    if is64:
        e_phoff = struct.unpack_from(endian + "Q", data, 0x20)[0]
        e_phentsize = struct.unpack_from(endian + "H", data, 0x36)[0]
        e_phnum = struct.unpack_from(endian + "H", data, 0x38)[0]
        align_off, align_fmt = 0x30, endian + "Q"
    else:
        e_phoff = struct.unpack_from(endian + "I", data, 0x1C)[0]
        e_phentsize = struct.unpack_from(endian + "H", data, 0x2A)[0]
        e_phnum = struct.unpack_from(endian + "H", data, 0x2C)[0]
        align_off, align_fmt = 0x1C, endian + "I"

    aligns = []
    for i in range(e_phnum):
        off = e_phoff + i * e_phentsize
        if off + e_phentsize > len(data):
            break
        if struct.unpack_from(endian + "I", data, off)[0] != PT_LOAD:
            continue
        aligns.append(struct.unpack_from(align_fmt, data, off + align_off)[0])
    return aligns


def check(path):
    """Audit one APK/AAB. Returns the number of non-compliant libraries."""
    per_abi = collections.defaultdict(list)
    with zipfile.ZipFile(path) as z:
        for name in z.namelist():
            if not name.endswith(".so"):
                continue
            m = re.search(r"lib/([^/]+)/([^/]+\.so)$", name)
            if not m:
                continue
            with z.open(name) as f:
                # Program headers live near the start; 64 KB is ample.
                aligns = load_segment_aligns(f.read(65536))
            if aligns is None:
                continue
            per_abi[m.group(1)].append((m.group(2), min(aligns) if aligns else 0))

    print("=== %s ===" % path)
    if not per_abi:
        print("  no native libraries found")
        return 0

    total_bad = 0
    for abi in sorted(per_abi):
        libs = sorted(per_abi[abi])
        bad = [(n, a) for n, a in libs if a < PAGE_16KB]
        total_bad += len(bad)
        status = "OK" if not bad else "FAIL (%d misaligned)" % len(bad)
        print("  %-14s %2d libs  %s" % (abi, len(libs), status))
        for name, align in bad:
            print("      p_align=0x%-5x %s" % (align, name))

    print("  -> %s" % ("COMPLIANT" if not total_bad else
                       "NOT COMPLIANT - Play will reject this build"))
    return total_bad


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(2)
    failures = sum(check(p) for p in sys.argv[1:])
    sys.exit(1 if failures else 0)
