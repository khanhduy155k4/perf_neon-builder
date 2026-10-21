#!/usr/bin/env python3
"""Patch goodix,panel-max-x / panel-max-y inside a dtbo partition image.

Background
----------
Aftermarket GT9896 panels whose OEM config is NOT sent (send_config skipped to
avoid bricking the touch IC) fall back to the IC's default/NVM config. That
config reports touch coordinates in Q3 fixed point (1/8 px), e.g. X up to
8 * 1079 = 8632 and Y up to 8 * 2399 = 19192.

The kernel declares the evdev range from goodix,panel-max-x/y taken from the
DTB. If those stay at the native panel size (1079/2399), Android clamps every
real touch to that range and only the top-left 1/8 of the screen responds.

Fix: declare the real IC range (8 * width - 1, 8 * height - 1) in the dtbo.
Android then computes XScale = width / (max + 1) = 0.125 and maps correctly.

This tool edits ONLY the 4 value bytes of the two properties, leaving the FDT
structure untouched. It locates properties by name, not by fixed offset, so it
also works after an OTA changed the dtbo layout.

Usage
-----
    python patch_dtbo.py -i dtbo.img -o dtbo_patched.img
    python patch_dtbo.py -i dtbo.img -o dtbo_patched.img --max-x 8639 --max-y 19199
    python patch_dtbo.py -i dtbo.img --dry-run
"""
import argparse
import struct
import sys

FDT_MAGIC = 0xD00DFEED
FDT_BEGIN_NODE, FDT_END_NODE, FDT_PROP, FDT_NOP, FDT_END = 1, 2, 3, 4, 9

PROPS = ("goodix,panel-max-x", "goodix,panel-max-y")


def cstr(buf, off):
    end = buf.find(b"\x00", off)
    if end < 0:
        raise ValueError("unterminated string")
    return buf[off:end].decode("latin1")


def find_props(buf, base, node_hint):
    """Return {prop_name: (absolute_value_offset, length)} under a matching node."""
    magic, _total, off_struct, off_strings = struct.unpack_from(">4I", buf, base)
    if magic != FDT_MAGIC:
        raise ValueError("bad FDT magic at 0x%x" % base)

    pos = base + off_struct
    strings = base + off_strings
    path = []
    found = {}

    while True:
        tok = struct.unpack_from(">I", buf, pos)[0]
        pos += 4

        if tok == FDT_BEGIN_NODE:
            name = cstr(buf, pos)
            pos += (len(name) + 1 + 3) & ~3
            path.append(name)
        elif tok == FDT_END_NODE:
            if path:
                path.pop()
        elif tok == FDT_PROP:
            length, nameoff = struct.unpack_from(">II", buf, pos)
            pos += 8
            value_off = pos
            pos += (length + 3) & ~3
            pname = cstr(buf, strings + nameoff)
            if path and node_hint in path[-1] and pname in PROPS:
                found[pname] = (value_off, length)
        elif tok == FDT_NOP:
            continue
        elif tok == FDT_END:
            break
        else:
            raise ValueError("unexpected FDT token 0x%x at 0x%x" % (tok, pos - 4))

    return found


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("-i", "--input", required=True, help="source dtbo image")
    ap.add_argument("-o", "--output", help="output image (required unless --dry-run)")
    ap.add_argument("--max-x", type=int, default=8639, help="new panel-max-x (default 8639)")
    ap.add_argument("--max-y", type=int, default=19199, help="new panel-max-y (default 19199)")
    ap.add_argument("--node", default="gt9896", help="node name substring (default gt9896)")
    ap.add_argument("--dry-run", action="store_true", help="only report what would change")
    args = ap.parse_args()

    if not args.dry_run and not args.output:
        ap.error("-o/--output is required unless --dry-run is used")

    data = bytearray(open(args.input, "rb").read())
    base = data.find(struct.pack(">I", FDT_MAGIC))
    if base < 0:
        print("error: no FDT found in %s" % args.input, file=sys.stderr)
        return 1

    props = find_props(data, base, args.node)
    if not props:
        print("error: no goodix,panel-max-* under node '%s'" % args.node, file=sys.stderr)
        return 1

    wanted = {"goodix,panel-max-x": args.max_x, "goodix,panel-max-y": args.max_y}
    changed = 0

    print("FDT at 0x%x" % base)
    for name, new in wanted.items():
        if name not in props:
            print("  ! missing %s" % name, file=sys.stderr)
            continue
        off, length = props[name]
        if length != 4:
            print("  ! %s is %d bytes, expected 4" % (name, length), file=sys.stderr)
            continue
        old = struct.unpack_from(">I", data, off)[0]
        print("  %-20s @0x%06x  %d -> %d" % (name, off, old, new))
        if not args.dry_run:
            struct.pack_into(">I", data, off, new)
        changed += 1

    if changed != len(wanted):
        print("error: could not patch every property, aborting", file=sys.stderr)
        return 1

    if args.dry_run:
        print("dry run: nothing written")
        return 0

    open(args.output, "wb").write(data)
    print("wrote %s (%d bytes)" % (args.output, len(data)))

    # Re-parse the result to prove the structure is still valid.
    check = find_props(data, base, args.node)
    for name, new in wanted.items():
        off, _ = check[name]
        got = struct.unpack_from(">I", data, off)[0]
        if got != new:
            print("error: verify failed for %s (%d)" % (name, got), file=sys.stderr)
            return 1
    print("verify OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
