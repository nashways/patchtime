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


if [[ "$@" == "--?" ]]; then 
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
if [[ "$@" == "-l" ]]; then
  echo -e "    \e]8;;https://www.gnu.org/licenses/gpl-3.0.html#section15\aDisclaimer of Warranty\e]8;;\a"
  echo -e "    https://www.gnu.org/licenses/gpl-3.0.html#section15 \n"
  echo -e "    \e]8;;https://www.gnu.org/licenses/gpl-3.0.html#terms\aTerms and Conditions\e]8;;\a"
  echo -e "    https://www.gnu.org/licenses/gpl-3.0.html#terms \n"
  exit 0
fi

# Credits:
# Nashway (Nashways)
# ifthenfi

# Description:
# Prints a patch window name based on counting weeks from first Monday or Tuesday of the month.
# Example: w4d4h12 (The w4d4h12 means: week 4 of the month, Thursday and 12 a clock.)
# This scipt will borrow the first few days from next months week 1 if it does not have a Monday or Tuesday to complete last week of the month.
# It will also consider monday before a tuesday the first as week day 1 of week 1.
# You can only trust w1d1 to w4d7 as week 5 does not always exist.

# Set DAY="Tue" for Tuesday, anything else counts as Monday.
DAY=""
if [[ "$@" == "-t" ]]; then
  DAY="Tue"
fi

# Get the number of the current day.
D=$(expr $(date +%d) + 0)

cal_var () {
	# Get variables
  if [[ -z $1 ]]; then
    local MONTH=$(date +%m)
  else
    local MONTH=$1
  fi
  if [[ -z $2 ]]; then
    local YEAR=$(date +%Y)
  else
    local YEAR=$2
  fi

	# Find Number of Days Week 1 of Next Month.
	local NDW1NM=$(expr $(cal -3 -m $MONTH $YEAR | head -n +3 | tail -n 1|tr ' ' '\n' | grep -v ^$ | tail -n 1) + 0 )

	# If first week has less than 7 days, fill upp end of previous month instead.
  if [[ "$NDW1NM" -lt 7 ]]; then
    # Print the head of this month.
    echo "$(cal -m $MONTH $YEAR | awk 'NF' | head -n -1)"

    # Print this month and start adding days to the end of the month with NDW1NM to fill it up.
    echo "$(cal -m $MONTH $YEAR | awk 'NF{p=$0}END{print p}' | sed 's/ *$//g')$( for (( i=1; i<=$NDW1NM; i++ )); do echo -n " $(expr $(cal -m $MONTH $YEAR | xargs echo | awk '{print $NF}') + $i )" ; done)"
    echo ""
  else
    # Print month as it is already complete.
    cal -m $MONTH $YEAR
  fi
}

main () {	
  # Find Number of Days Week 1 of this month.
  NDW1=$(expr $(cal_var $(date "+%m %Y") | head -n +3 | tail -n 1 | tr ' ' '\n' | grep -v ^$ | wc -l) + 0)
  		
  if [[ $DAY == "Tue" ]]; then
    # If NDW1 is greater than todays number and less than 5 we need to be on the fake end of previous month.
    if [[ $NDW1 -ge $D ]] && [[ $NDW1 -le 5 ]]; then
      # Reculate todays number, add todays number to number of days last month so we are on 29-38th.
      D=$(expr $D + $(cal -m $(date "+%m %Y" --date "$(date +%Y-%m-01) -1 day") | xargs echo | awk '{print $NF}'))

      # If the first week of previous month has less than 5 days subtract 1 from the week calculation.
      if [[ $(expr $(cal_var $(date "+%m %Y" --date "$(date +%Y-%m-01) -1 day") | head -n +3 | tail -n 1 | tr ' ' '\n' | grep -v ^$ | wc -l) + 0) -le 5 ]]; then
        CURRENTWEEK=$(expr $(echo $(echo "$(cal_var $(date "+%m %Y" --date "$(date +%Y-%m-01) -1 day"))$(echo -n " ")" | sed -n "3,$ p" | egrep -n "^$D | $D | $D$" | cut -d ":" -f1) | cut -d " " -f1) - 1)
      else
        CURRENTWEEK=$(expr $(echo $(echo "$(cal_var $(date "+%m %Y" --date "$(date +%Y-%m-01) -1 day"))$(echo -n " ")" | sed -n "3,$ p" | egrep -n "^$D | $D | $D$" | cut -d ":" -f1) | cut -d " " -f1) - 0)
      fi
    else 
      # Stay on this month and subtract 1 from current week if first week has less than 5 days.
      if [[ $(expr $(cal_var | head -n +3 | tail -n 1 | tr ' ' '\n' | grep -v ^$ | wc -l) + 0) -le 5 ]]; then
        CURRENTWEEK=$(expr $(echo $(echo "$(cal_var)$(echo -n " ")" | sed -n "3,$ p" | egrep -n "^$D | $D | $D$" | cut -d ":" -f1) | cut -d " " -f1) - 1)
      else
        CURRENTWEEK=$(echo $(echo "$(cal_var)$(echo -n " ")" | sed -n "3,$ p" | egrep -n "^$D | $D | $D$" | cut -d ":" -f1) | cut -d " " -f1)
      fi
    fi
  
    # Override if tomorrow is the 1 and a tuesday, count this monday as week 1.
    if [ $(expr $(date +%d --date="next day") + 0) == 1 ] && [ $(/bin/date +\%a --date="next day") == "Tue" ]; then
      CURRENTWEEK=$(echo 1)
    fi
  else
    # If NDW1 is greater than todays number and less than 7 we need to be on the fake end of previous month.
    if [[ $NDW1 -ge $D ]] && [[ $NDW1 -lt 7 ]]; then
      # Reculate todays number, add todays number to number of days last month so we are on 29-38th.
      D=$(expr $D + $(cal -m $(date "+%m %Y" --date "$(date +%Y-%m-01) -1 day") | xargs echo | awk '{print $NF}'))

      # If the first week of previous month has less than 7 days subtract 1 from the week calculation.
      if [[ $(expr $(cal_var $(date "+%m %Y" --date "$(date +%Y-%m-01) -1 day") | head -n +3 | tail -n 1 | tr ' ' '\n' | grep -v ^$ | wc -l) + 0) -lt 7 ]]; then
        CURRENTWEEK=$(expr $(echo $(echo "$(cal_var $(date "+%m %Y" --date "$(date +%Y-%m-01) -1 day"))$(echo -n " ")" | sed -n "3,$ p" | egrep -n "^$D | $D | $D$" | cut -d ":" -f1) | cut -d " " -f1) - 1)
      else
        CURRENTWEEK=$(expr $(echo $(echo "$(cal_var $(date "+%m %Y" --date "$(date +%Y-%m-01) -1 day"))$(echo -n " ")" | sed -n "3,$ p" | egrep -n "^$D | $D | $D$" | cut -d ":" -f1) | cut -d " " -f1) - 0)
      fi
    else
      # Stay on this month and subtract 1 from current week if first week has less than 7 days.
      if [[ $(expr $(cal_var | head -n +3 | tail -n 1 | tr ' ' '\n' | grep -v ^$ | wc -l) + 0) -lt 7 ]]; then
        CURRENTWEEK=$(expr $(echo $(echo "$(cal_var)$(echo -n " ")" | sed -n "3,$ p" | egrep -n "^$D | $D | $D$" | cut -d ":" -f1) | cut -d " " -f1) - 1)
      else
        CURRENTWEEK=$(echo $(echo "$(cal_var)$(echo -n " ")" | sed -n "3,$ p" | egrep -n "^$D | $D | $D$" | cut -d ":" -f1) | cut -d " " -f1)
      fi
    fi
  fi
}

# Find the day of the week.
CURRENTDAY=$(date +%u)

# Find the current hour.
CURRENTHOUR=$(date +"%H")

main
echo "w${CURRENTWEEK}d${CURRENTDAY}h$CURRENTHOUR"
