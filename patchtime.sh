#!/usr/bin/env bash
#    Patch Time.  Prints a patch window name.
#    Copyright (C) 2023  Nashway
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/>.

if [[ "$*" == "--?" ]]; then
  echo -e "\n    Patch Time  Copyright (C) 2023  Nashway
    This program comes with ABSOLUTELY NO WARRANTY.\n
    This is free software, and you are welcome to redistribute it
    under certain conditions.\n \n
    Description\n    
    Patchtime prints a patch window name based on counting weeks from first Monday or Tuesday of the month.
    Example: w4d4h12 (Which means week 4 of the month, Thursday and 12 a clock.)
    This scipt will borrow the first few days from next months week 1 to complete last week of the month.\n
    Valid windows are w1d1h1-w4d7h23.\n

    Usage
    patchtime.sh -t \t Default is to count first week from Monday, to set Tuesday.
    patchtime.sh -l \t Links to Disclamer of warranty and Terms and Conditions\n"
  exit 0
fi
if [[ "$*" == "-l" ]]; then
  echo -e "    \e]8;;https://www.gnu.org/licenses/gpl-3.0.html#section15\aDisclaimer of Warranty\e]8;;\a"
  echo -e "    https://www.gnu.org/licenses/gpl-3.0.html#section15 \n"
  echo -e "    \e]8;;https://www.gnu.org/licenses/gpl-3.0.html#terms\aTerms and Conditions\e]8;;\a"
  echo -e "    https://www.gnu.org/licenses/gpl-3.0.html#terms \n"
  exit 0
fi

# Anchor day: Monday (default) or Tuesday (-t).
USE_TUE=0
if [[ "$*" == "-t" ]]; then
  USE_TUE=1
fi

# Today's date components (base-10 strip leading zeros).
YEAR=$(date +%Y)
MONTH=$(( 10#$(date +%m) ))
DAY=$(( 10#$(date +%d) ))
CURRENTDAY=$(date +%u)
CURRENTHOUR=$(date +%H)

# get_patch_week YEAR MONTH DAY USE_TUE  -> echoes patch week number.
#
# Mirrors patchtime.py's get_patch_week():
#   ndw1   = days in first (possibly partial) week, Monday-first cal
#   row    = which Mon-Sun row the day sits in (0 = first row)
#   thresh = 6 (Tue mode) or 7 (Mon mode); ndw1 < thresh -> partial first row
get_patch_week() {
  local y=$1 m=$2 d=$3 tue=$4
  local threshold=7
  (( tue == 1 )) && threshold=6

  # Tuesday override: Monday before a Tuesday 1st counts as w1.
  if (( tue == 1 )); then
    local tom_dom tom_dow
    tom_dom=$(date -d "$y-$m-$d + 1 day" +%-d)
    tom_dow=$(date -d "$y-$m-$d + 1 day" +%u)
    if [[ "$tom_dom" == "1" && "$tom_dow" == "2" ]]; then
      echo 1
      return
    fi
  fi

  local first_dow ndw1 row
  first_dow=$(date -d "$y-$m-01" +%u)
  ndw1=$(( 8 - first_dow ))
  if (( d <= ndw1 )); then
    row=0
  else
    row=$(( (d - ndw1 + 6) / 7 ))
  fi

  if (( ndw1 < threshold )); then
    if (( row == 0 )); then
      # Partial first row belongs to previous month's last patch week.
      local pm_y pm_m pm_first_dow pm_ndw1 pm_days pm_last_row week
      if (( m == 1 )); then
        pm_y=$(( y - 1 )); pm_m=12
      else
        pm_y=$y; pm_m=$(( m - 1 ))
      fi
      pm_first_dow=$(date -d "$pm_y-$pm_m-01" +%u)
      pm_ndw1=$(( 8 - pm_first_dow ))
      pm_days=$(date -d "$pm_y-$pm_m-01 + 1 month - 1 day" +%-d)
      if (( pm_days <= pm_ndw1 )); then
        pm_last_row=0
      else
        pm_last_row=$(( (pm_days - pm_ndw1 + 6) / 7 ))
      fi
      week=$(( pm_last_row + 1 ))
      (( pm_ndw1 < threshold )) && week=$(( week - 1 ))
      echo "$week"
    else
      echo "$row"
    fi
  else
    echo $(( row + 1 ))
  fi
}

CURRENTWEEK=$(get_patch_week "$YEAR" "$MONTH" "$DAY" "$USE_TUE")
echo "w${CURRENTWEEK}d${CURRENTDAY}h${CURRENTHOUR}"
