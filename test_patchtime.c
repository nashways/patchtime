/*
 *    test_patchtime - enumerate patchtime_week() over a date range.
 *    Emits one "YYYY-MM-DD a w" line per (date, anchor) combination so
 *    output can be diffed against the Python implementation.
 *
 *    Copyright (C) 2026  Nashway
 *    Licensed under GNU GPL v3 or later <https://www.gnu.org/licenses/>.
 *
 *    Usage:  test_patchtime START_YEAR END_YEAR
 */

#include <stdio.h>
#include <stdlib.h>

#include "patchtime.h"

static int days_in_month_local(int year, int month) {
    static const int dim[] = {31,28,31,30,31,30,31,31,30,31,30,31};
    if (month == 2) {
        int leap = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
        return leap ? 29 : 28;
    }
    return dim[month - 1];
}

int main(int argc, char **argv) {
    if (argc != 3) {
        fprintf(stderr, "usage: %s START_YEAR END_YEAR\n", argv[0]);
        return 2;
    }
    int sy = atoi(argv[1]);
    int ey = atoi(argv[2]);
    if (sy < 1 || ey < sy) {
        fprintf(stderr, "bad year range\n");
        return 2;
    }

    for (int y = sy; y <= ey; y++) {
        for (int m = 1; m <= 12; m++) {
            int dim = days_in_month_local(y, m);
            for (int d = 1; d <= dim; d++) {
                for (int a = 1; a <= 7; a++) {
                    int w = patchtime_week(y, m, d, a);
                    if (w < 0) {
                        fprintf(stderr,
                            "patchtime_week failed on %04d-%02d-%02d a=%d\n",
                            y, m, d, a);
                        return 1;
                    }
                    printf("%04d-%02d-%02d %d %d\n", y, m, d, a, w);
                }
            }
        }
    }
    return 0;
}
