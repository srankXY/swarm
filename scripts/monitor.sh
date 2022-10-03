#!/bin/bash

workdir=/bee/9004
check(){
	process=$(ps -elf | grep "/bee/9004" | grep -viEc "grep|cron|bash")
	if [[ $process -lt 1 ]];then
		cd $workdir && bash start.sh
	fi
}

check
