#!/usr/bin/env python3
"""
Patch Time - Prints a patch window name.
Copyright (C) 2023  Nashway

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <https://www.gnu.org/licenses/>.
"""

import sys
import calendar
from datetime import date, timedelta, datetime


def days_in_first_week(year: int, month: int) -> int:
    """Return the number of days in the first (possibly partial) week of a month."""
    cal = calendar.monthcalendar(year, month)
    return sum(1 for d in cal[0] if d != 0)


def get_patch_week(dt: date, anchor: int = 1) -> int:
    """
    Return the patch week number (1-4) for a given date.

    Weeks are counted from the first occurrence of `anchor` (ISO weekday,
    1=Mon … 7=Sun) in the month. Days before that anchor day belong to the
    previous month's last patch week.

    threshold = 8 - anchor; ndw1 < threshold means the first row is a
    partial week that doesn't contain the anchor day.
    """
    if not 1 <= anchor <= 7:
        raise ValueError(f"anchor must be 1..7, got {anchor}")
    threshold = 8 - anchor

    # Override: the day before an anchor-day 1st counts as w1.
    tomorrow = dt + timedelta(days=1)
    if tomorrow.day == 1 and tomorrow.isoweekday() == anchor:
        return 1

    cal_m = calendar.monthcalendar(dt.year, dt.month)
    ndw1 = days_in_first_week(dt.year, dt.month)

    # Find which row (0-based) the current day sits in.
    row_idx = next(i for i, week in enumerate(cal_m) if dt.day in week)

    if ndw1 < threshold:
        if row_idx == 0:
            # This day is in the partial first week — it belongs to the
            # previous month's last patch week.
            prev = date(dt.year, dt.month, 1) - timedelta(days=1)
            pm_cal = calendar.monthcalendar(prev.year, prev.month)
            pm_ndw1 = days_in_first_week(prev.year, prev.month)
            week_num = len(pm_cal)
            if pm_ndw1 < threshold:
                week_num -= 1
            return week_num
        else:
            # row 0 is the partial week belonging to prev month,
            # so row 1 → w1, row 2 → w2, etc.
            return row_idx
    else:
        # First week is full — row 0 → w1, row 1 → w2, etc.
        return row_idx + 1


def patch_window(dt: date = None, anchor: int = 1, hour: int = None) -> str:
    """
    Return the patch window string, e.g. 'w2d4h09'.

    w = week of month (1-4)
    d = day of week (1=Mon … 7=Sun, ISO)
    h = hour (00-23)
    """
    if dt is None:
        dt = date.today()
    if hour is None:
        hour = datetime.now().hour

    week = get_patch_week(dt, anchor)
    day  = dt.isoweekday()
    return f"w{week}d{day}h{hour:02d}"


def print_help():
    print("""
    Patch Time  Copyright (C) 2023  Nashway
    This program comes with ABSOLUTELY NO WARRANTY.

    This is free software, and you are welcome to redistribute it
    under certain conditions.

    Description

    Patchtime prints a patch window name based on counting weeks from
    the first Monday or Tuesday of the month.
    Example: w4d4h12 (week 4 of the month, Thursday, 12 o'clock.)
    This script will borrow the first few days from next month's week 1
    to complete the last week of the month.

    Valid windows are w1d1h00 - w4d7h23.

    Usage
    patchtime.py -a N  Anchor weekday (1=Mon … 7=Sun). Default 1 (Monday).
    patchtime.py -t    Deprecated alias for -a 2 (Tuesday anchor).
    patchtime.py -l    Links to Disclaimer of Warranty and Terms and Conditions
""")


def print_links():
    print("    \033]8;;https://www.gnu.org/licenses/gpl-3.0.html#section15\aDisclaimer of Warranty\033]8;;\a")
    print("    https://www.gnu.org/licenses/gpl-3.0.html#section15\n")
    print("    \033]8;;https://www.gnu.org/licenses/gpl-3.0.html#terms\aTerms and Conditions\033]8;;\a")
    print("    https://www.gnu.org/licenses/gpl-3.0.html#terms\n")


def main():
    args = sys.argv[1:]

    if "--?" in args:
        print_help()
        sys.exit(0)

    if "-l" in args:
        print_links()
        sys.exit(0)

    anchor = 1
    if "-t" in args:
        anchor = 2
    if "-a" in args:
        i = args.index("-a")
        try:
            anchor = int(args[i + 1])
        except (IndexError, ValueError):
            print("error: -a requires an integer 1..7", file=sys.stderr)
            sys.exit(2)
        if not 1 <= anchor <= 7:
            print(f"error: anchor must be 1..7, got {anchor}", file=sys.stderr)
            sys.exit(2)

    result = patch_window(anchor=anchor)
    print(result)


if __name__ == "__main__":
    main()
