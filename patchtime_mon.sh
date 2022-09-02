#!/bin/bash
# This will print the patch window name based on counting weeks from first monday in the month.
# ex w4d412
# week 4, thur and 12 a clock
# This scipt will borrow the first few days from next months week one if it does not have a monday to complete last week of the month.
# You can only trust w1d1 to w4d7 as week five does not always exist.
#blame Nashway

#Get todays number
d=$(expr $(date +%d) + 0)

function cal_var ()
{
	#Get variables
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
	#Find Number of Days Week 1 of Next Month
	local NDW1NM=$(expr $(cal -3 -m $MONTH $YEAR|head -n +3|tail -n 1|tr ' ' '\n'|grep -v ^$|tail -n 1) + 0 )

	#If first week has less then 7 days, Fill upp end of previous month instead
        if [[ "$NDW1NM" -lt 7 ]] ; then

		#Print the head of this month
                echo "$(cal -m $MONTH $YEAR | awk 'NF'|head -n -1)"

		#Print this month and start adding days to the end of the month with NDW1NM to fill it up
                echo "$(cal -m $MONTH $YEAR |awk 'NF{p=$0}END{print p}'|sed 's/ *$//g')$( for (( i=1; i<=$NDW1NM; i++ )); do echo -n " $(expr $(cal -m $MONTH $YEAR | xargs echo | awk '{print $NF}') + $i )" ; done)"
                echo ""
        else
                #Print month as it is already complete
		cal -m $MONTH $YEAR
        fi
}


function main ()
{	
	#Find Number of Days Week 1 of this month
	NDW1=$(expr $(cal_var $(date "+%m %Y")|head -n +3|tail -n 1|tr ' ' '\n'|grep -v ^$|wc -l) + 0)
	
	#If NDW1 is greater that todays number and less than 7 we need to be on the fake end of previous month
	if [[ $NDW1 -ge $d ]] && [[ $NDW1 -lt 7 ]] ; then

		#Reculate todays number, add todays number to number of days last month so we are on 29-38th
		d=$(expr $d + $(cal -m $(date "+%m %Y" --date "$(date +%Y-%m-01) -1 day") | xargs echo | awk '{print $NF}'))

		#If the first week of previous month has less than 7 days subtract 1 from the week calculation
		if [[ $(expr $(cal_var $(date "+%m %Y" --date "$(date +%Y-%m-01) -1 day") | head -n +3|tail -n 1|tr ' ' '\n'|grep -v ^$|wc -l) + 0) -lt 7 ]]; then
			currentweek=$(expr $(echo $(echo "$(cal_var $(date "+%m %Y" --date "$(date +%Y-%m-01) -1 day"))$(echo -n " ")"|sed -n "3,$ p" | egrep -n "^$d | $d | $d$" | cut -d ":" -f1)|cut -d " " -f1) - 1)
		else
			currentweek=$(expr $(echo $(echo "$(cal_var $(date "+%m %Y" --date "$(date +%Y-%m-01) -1 day"))$(echo -n " ")"|sed -n "3,$ p" | egrep -n "^$d | $d | $d$" | cut -d ":" -f1)|cut -d " " -f1) - 0)
		fi
	else 
		#Stay on this month and subtract 1 from current week if first week has less than 7 days
		if [[ $(expr $(cal_var |head -n +3|tail -n 1|tr ' ' '\n'|grep -v ^$|wc -l) + 0) -lt 7 ]]; then
			currentweek=$(expr $(echo $(echo "$(cal_var)$(echo -n " ")"|sed -n "3,$ p" | egrep -n "^$d | $d | $d$" | cut -d ":" -f1)|cut -d " " -f1) - 1)
		else
			currentweek=$(echo $(echo "$(cal_var)$(echo -n " ")"|sed -n "3,$ p" | egrep -n "^$d | $d | $d$" | cut -d ":" -f1)|cut -d " " -f1)
		fi
	fi

}
#Find the day of the week
currentday=$(date +%u)

#Find the current hour
currenthour=$(date +"%H")

main
echo "w${currentweek}d${currentday}h$currenthour"
