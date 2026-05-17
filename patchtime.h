/*
 *    Patch Time.  C port of get_patch_week.
 *    Copyright (C) 2026  Nashway
 *
 *    Licensed under GNU GPL v3 or later <https://www.gnu.org/licenses/>.
 */

#ifndef PATCHTIME_H
#define PATCHTIME_H

/*
 * Return the patch week number (1..5) for the given Gregorian date,
 * counting weeks from the first occurrence of `anchor` (ISO weekday,
 * 1 = Mon ... 7 = Sun) in the month.  Days in the partial first row
 * that come before that anchor belong to the previous month's last
 * patch week.  Mirrors patchtime.py's get_patch_week().
 *
 * Returns -1 on invalid input.
 */
int patchtime_week(int year, int month, int day, int anchor);

#endif /* PATCHTIME_H */
