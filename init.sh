#!/bin/bash

api=$2
p2p=$3
debug=$4
pub_ip=$5
# workdir=/bee/9004

source ./scripts/setport.sh
set_cron(){
	cat ./scripts/cron.txt >> /var/spool/cron/crontabs/root
#	service cron reload
}

case $1 in
	init)
		setport $api $p2p $debug $pub_ip
		set_cron
		;;
	set-cron)
		set_cron
		;;
	setport)
		setport $api $p2p $debug $pub_ip
		;;
	-h|*)
		echo -e "\n default useage:
		> init.sh init, params {\$apiport \$p2pport \$debugport \$pub_ip} \n
		> init.sh set-cron, set monitor crontab \n
		> init.sh setport, only set bzz port, not set crontab(support -h query help info)"
esac


