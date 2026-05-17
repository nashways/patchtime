/*
 *    Patch Time.  C port of get_patch_week.
 *    Copyright (C) 2026  Nashway
 *
 *    Licensed under GNU GPL v3 or later <https://www.gnu.org/licenses/>.
 */

#include "patchtime.h"

/* Sakamoto-based ISO weekday: 1 = Mon ... 7 = Sun. -1 on bad input. */
static int iso_weekday(int year, int month, int day) {
    if (month < 1 || month > 12 || day < 1 || day > 31) return -1;
    /* Sakamoto's algorithm */
    static const int t[] = {0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4};
    int y = year - (month < 3);
    int wd = (y + y/4 - y/100 + y/400 + t[month - 1] + day) % 7; /* 0=Sun..6=Sat */
    return wd == 0 ? 7 : wd;
}

static int days_in_month(int year, int month) {
    static const int dim[] = {31,28,31,30,31,30,31,31,30,31,30,31};
    if (month < 1 || month > 12) return -1;
    if (month == 2) {
        int leap = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
        return leap ? 29 : 28;
    }
    return dim[month - 1];
}

int patchtime_week(int year, int month, int day, int anchor) {
    if (anchor < 1 || anchor > 7) return -1;
    int dim = days_in_month(year, month);
    if (dim < 0 || day < 1 || day > dim) return -1;

    int threshold = 8 - anchor;

    /* Override: if tomorrow is the 1st AND tomorrow's dow == anchor,
     * today (the last day of prev month) counts as w1. */
    {
        int tom_y = year, tom_m = month, tom_d = day + 1;
        if (tom_d > dim) {
            tom_d = 1;
            if (++tom_m > 12) { tom_m = 1; tom_y++; }
        }
        if (tom_d == 1 && iso_weekday(tom_y, tom_m, tom_d) == anchor)
            return 1;
    }

    int first_dow = iso_weekday(year, month, 1);
    if (first_dow < 0) return -1;
    int ndw1 = 8 - first_dow;
    int row = (day <= ndw1) ? 0 : (day - ndw1 + 6) / 7;

    if (ndw1 < threshold) {
        if (row == 0) {
            /* Partial first row → previous month's last patch week */
            int pm_y = (month == 1) ? year - 1 : year;
            int pm_m = (month == 1) ? 12 : month - 1;
            int pm_first_dow = iso_weekday(pm_y, pm_m, 1);
            int pm_ndw1 = 8 - pm_first_dow;
            int pm_days = days_in_month(pm_y, pm_m);
            int pm_last_row = (pm_days <= pm_ndw1)
                ? 0
                : (pm_days - pm_ndw1 + 6) / 7;
            int week = pm_last_row + 1;
            if (pm_ndw1 < threshold) week -= 1;
            return week;
        }
        return row;
    }
    return row + 1;
}
