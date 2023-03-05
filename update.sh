#!/bin/bash

function textifyDuration() 
{
	local localReturnString=""
	local duration=$1
	local durationShif=$duration
	local seconds=$((durationShif % 60)); durationShif=$((durationShif / 60));
	local minutes=$((durationShif % 60)); durationShif=$((durationShif / 60));
	local hours=$durationShif
	local secondPlural; if [ $seconds  -lt 2 ]; then secondPlural=''; else secondPlural='s'; fi
	local minutePlural; if [ $minutes  -lt 2 ]; then minutePlural=''; else minutePlural='s'; fi
	local hourPlural; if [ $hours -lt 2 ]; then hourPlural=''; else hourPlural='s'; fi
	local mainSecondPlural; if [ $duration  -lt 2 ]; then mainSecondPlural=''; else mainSecondPlural='s'; fi
	if [[ $seconds -gt 0 ]]; then secondText="$seconds seconde$secondPlural"; fi
	local minuteText="";
	if [[ $minutes -gt 0 ]]; then minuteText="$minutes minute$minutePlural"; fi
	local hourText="";
	if [[ $hours -gt 0 ]]; then hourText="$minutes minute$hourPlural"; fi
	local text="";
	if [[ $hourText != '' ]]; then text="$hourText"; fi
	if [[ $minuteText != '' ]]; then 
		if [[ $text = '' ]]; then text="$minuteText"; else text="$text, $minuteText";
		fi
	fi
	if [[ $secondText != '' ]]; then 
		if [[ $text = '' ]]; then text="$secondText"; else text="$text, $secondText";
		fi
	fi
	if [[ $duration -gt 60 ]]; then
		localReturnString="$text ($duration seconde$mainSecondPlural)"
	else
		localReturnString="$text"
	fi
	eval "$2='$localReturnString'"
}	

function getCurrentTime()
{
 	echo "$(date +"%A $(echo "$(date "+"%e)"|sed 's/ //') %B %Y à %T.%1N")"|sed 's/\.0//g'
}

readonly WAITING_TIME_BEFORE_RETRY=0.1
readonly MAX_COUNTER=421138
readonly MODULO_FOR_DISPLAY=120
moduloForDisplay=$MODULO_FOR_DISPLAY
formatSecondsBeforeScript="$(TZ=UTC0 printf '%(%s)T\n' '-1')"  
echo "----------------------------------------- Start of the script launch on $(getCurrentTime) -----------------------------------------" >> .update.log
counterWaitingInternet=0
for counterWaitingInternet in $( eval echo {0..$MAX_COUNTER} )
do
	secondsCheckingInternet=$(($(TZ=UTC0 printf '%(%s)T\n' '-1')-formatSecondsBeforeScript))
	if nc -zw1 google.com 443; then
  		break
 	elif [[ $secondsCheckingInternet -gt $moduloForDisplay ]]; then
 		returnStringInternet=''
 		textifyDuration $secondsCheckingInternet returnStringInternet
  		echo "No Internet found on $(getCurrentTime) either at the end of $returnStringInternet"  >> .update.log
  		moduloForDisplay=$(($moduloForDisplay * 2))
	fi
	sleep $WAITING_TIME_BEFORE_RETRY
done
returnStringinternetNotFoundOrFoundDate=''
secondsCheckingInternet=$(($(TZ=UTC0 printf '%(%s)T\n' '-1')-formatSecondsBeforeScript))
textifyDuration $secondsCheckingInternet returnStringinternetNotFoundOrFoundDate
if [[ $counterWaitingInternet -eq $MAX_COUNTER ]]; then
	echo "At $(getCurrentTime) the Internet was not found after $counterWaitingInternet attempts, maximum number of attempts: $MAX_COUNTER, time taken: $returnStringinternetNotFoundOrFoundDate" >> .update.log
else
	formatSecondsBeforeUdpate="$(TZ=UTC0 printf '%(%s)T\n' '-1')"  
	echo 'hereistherootpassword'|sudo -S apt update && sudo -S apt full-upgrade -y && sudo -S apt autoremove  && sudo -S apt clean
	formatSecondsAfterScript=$(($(TZ=UTC0 printf '%(%s)T\n' '-1')-formatSecondsBeforeUdpate))
	returnStringUpdate=''
	textifyDuration $formatSecondsAfterScript returnStringUpdate
	formatSecondsAllScript=$(($(TZ=UTC0 printf '%(%s)T\n' '-1')-formatSecondsBeforeScript))
	returnStringAllScript=''
	textifyDuration $formatSecondsAllScript returnStringAllScript
	echo "Script finished at $(getCurrentTime), time to find the Internet: $returnStringinternetNotFoundOrFoundDate, time to update: $returnStringUpdate, total time: $returnStringAllScript" >> .update.log
fi
