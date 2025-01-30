#!/usr/bin/env bash
LC_TIME="en_US.UTF-8"
# This will print the patch window name based on counting weeks from first Tuesday of the month.
# ex w4d412
# week 4, thur and 12 a clock
# This scipt will borrow the first few days from next months week one if it does not have a monday to complete last week of the month.
# It will also consider monday before a tuesday the first as week day 1 of week 1.
# You can only trust w1d1 to w4d7 as week five does not always exist.
#blame Nashway

#Get todays number
D=$(expr $(date +%d) + 0)

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

	#If first week has less then 7 days, fill upp end of previous month instead
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

	#If NDW1 is greater that todays number and less than 5 we need to be on the fake end of previous month
	if [[ $NDW1 -ge $D ]] && [[ $NDW1 -le 5 ]]; then
	
		#Reculate todays number, add todays number to number of days last month so we are on 29-38th
		D=$(expr $D + $(cal -m $(date "+%m %Y" --date "$(date +%Y-%m-01) -1 day") | xargs echo | awk '{print $NF}'))

		#If the first week of previous month has less than 5 days subtract 1 from the week calculation
		if [[ $(expr $(cal_var $(date "+%m %Y" --date "$(date +%Y-%m-01) -1 day") | head -n +3|tail -n 1|tr ' ' '\n'|grep -v ^$|wc -l) + 0) -le 5 ]]; then
			CURRENTWEEK=$(expr $(echo $(echo "$(cal_var $(date "+%m %Y" --date "$(date +%Y-%m-01) -1 day"))$(echo -n " ")"|sed -n "3,$ p" | grep -En "^$D | $D | $D$" | cut -d ":" -f1)|cut -d " " -f1) - 1)
		else
			CURRENTWEEK=$(expr $(echo $(echo "$(cal_var $(date "+%m %Y" --date "$(date +%Y-%m-01) -1 day"))$(echo -n " ")"|sed -n "3,$ p" | grep -En "^$D | $D | $D$" | cut -d ":" -f1)|cut -d " " -f1) - 0)
		fi
	else 
		#Stay on this month and subtract 1 from current week if first week has less than 5 days
		if [[ $(expr $(cal_var |head -n +3|tail -n 1|tr ' ' '\n'|grep -v ^$|wc -l) + 0) -le 5 ]]; then
			CURRENTWEEK=$(expr $(echo $(echo "$(cal_var)$(echo -n " ")"|sed -n "3,$ p" | grep -En "^$D | $D | $D$" | cut -d ":" -f1)|cut -d " " -f1) - 1)
		else
			CURRENTWEEK=$(echo $(echo "$(cal_var)$(echo -n " ")"|sed -n "3,$ p" | grep -En "^$D | $D | $D$" | cut -d ":" -f1)|cut -d " " -f1)
		fi
	fi
	#Override if tomorrow is the 1 and a tuesday, count this monday as week 1
        if [ $(expr $(date +%d --date="next day") + 0) == 1 ] && [ $(/bin/date +\%a --date="next day") == "Tue" ] ; then
                CURRENTWEEK=$(echo 1)
	fi

}
#Find the day of the week
CURRENTDAY=$(date +%u)

#Find the current hour
CURRENTHOUR=$(date +"%H")

main
echo "w${CURRENTWEEK}d${CURRENTDAY}h$CURRENTHOUR"
