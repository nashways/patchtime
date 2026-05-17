#!/usr/bin/env python3
"""Generate expected patch-week data using patchtime.py to compare against C.

Output: one line per (date, anchor) -- "YYYY-MM-DD a w"

Usage: gen_expected.py START_YEAR END_YEAR
"""

import sys
from calendar import monthrange
from datetime import date

import patchtime  # local


def main():
    if len(sys.argv) != 3:
        print("usage: gen_expected.py START_YEAR END_YEAR", file=sys.stderr)
        sys.exit(2)
    sy = int(sys.argv[1])
    ey = int(sys.argv[2])
    out = sys.stdout.write
    for y in range(sy, ey + 1):
        for m in range(1, 13):
            dim = monthrange(y, m)[1]
            for d in range(1, dim + 1):
                dt = date(y, m, d)
                for a in range(1, 8):
                    w = patchtime.get_patch_week(dt, anchor=a)
                    out(f"{y:04d}-{m:02d}-{d:02d} {a} {w}\n")


if __name__ == "__main__":
    main()
