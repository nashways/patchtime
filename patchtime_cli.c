/*
 *    patchtime_cli - tiny standalone CLI around patchtime_week.
 *    Copyright (C) 2026  Nashway
 *    Licensed under GNU GPL v3 or later <https://www.gnu.org/licenses/>.
 *
 *    Usage:  patchtime_cli YEAR MONTH DAY ANCHOR
 *    Prints the patch week (1..5) or exits non-zero on bad input.
 */

#include <stdio.h>
#include <stdlib.h>

#include "patchtime.h"

int main(int argc, char **argv) {
    if (argc != 5) {
        fprintf(stderr, "usage: %s YEAR MONTH DAY ANCHOR\n", argv[0]);
        return 2;
    }
    int y = atoi(argv[1]);
    int m = atoi(argv[2]);
    int d = atoi(argv[3]);
    int a = atoi(argv[4]);
    int w = patchtime_week(y, m, d, a);
    if (w < 0) {
        fprintf(stderr, "patchtime_cli: invalid input\n");
        return 1;
    }
    printf("%d\n", w);
    return 0;
}
