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
    patchtime.sh -a N \t Anchor weekday (1=Mon ... 7=Sun). Default 1 (Monday).
    patchtime.sh -t \t Deprecated alias for -a 2 (Tuesday anchor).
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

# Anchor weekday: 1=Mon (default) ... 7=Sun.  -t is shorthand for -a 2.
ANCHOR=1
args=("$@")
for ((i=0; i<${#args[@]}; i++)); do
  case "${args[i]}" in
    -t) ANCHOR=2 ;;
    -a)
      ANCHOR="${args[i+1]:-}"
      if ! [[ "$ANCHOR" =~ ^[1-7]$ ]]; then
        echo "error: -a requires an integer 1..7" >&2
        exit 2
      fi
      ((i++))
      ;;
  esac
done

# Today's date components (base-10 strip leading zeros).
YEAR=$(date +%Y)
MONTH=$(( 10#$(date +%m) ))
DAY=$(( 10#$(date +%d) ))
CURRENTDAY=$(date +%u)
CURRENTHOUR=$(date +%H)

# get_patch_week YEAR MONTH DAY ANCHOR  -> echoes patch week number.
#
# Mirrors patchtime.py's get_patch_week():
#   threshold = 8 - anchor; ndw1 < threshold -> partial first row
#   ndw1      = days in first row, Monday-first cal
#   row       = which Mon-Sun row the day sits in (0 = first row)
get_patch_week() {
  local y=$1 m=$2 d=$3 anchor=$4
  local threshold=$(( 8 - anchor ))

  # Override: the day before an anchor-day 1st counts as w1.
  local tom_dom tom_dow
  tom_dom=$(date -d "$y-$m-$d + 1 day" +%-d)
  tom_dow=$(date -d "$y-$m-$d + 1 day" +%u)
  if [[ "$tom_dom" == "1" && "$tom_dow" == "$anchor" ]]; then
    echo 1
    return
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

CURRENTWEEK=$(get_patch_week "$YEAR" "$MONTH" "$DAY" "$ANCHOR")
echo "w${CURRENTWEEK}d${CURRENTDAY}h${CURRENTHOUR}"
