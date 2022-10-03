#!/bin/bash
# if run alone this shell. then $1 is method, $2 is api-port, $3 is p2p-port, $4 is debug-api port

helper(){
	echo -e '\n useage: \n
        > use -h open the help info. \n
        > if run alone this shell. then $1 is method, $2 is api-port, $3 is p2p-port, $4 is debug-api port. 
	if nested other shell run. then $1 is api-port, $2 is p2p-port, $3 is debug-api port example: \n
        > bash setport.sh setport 9003 9004 9005'

}

setport(){
	api=$1
	p2p=$2
	debug=$3
	pub_ip=$4
	if [[ $# -ne 4 ]];then helper;exit 0;fi
	all_files=$(grep -irE "9003|9004|9005" ./* --exclude-dir=bin --exclude-dir=data --exclude=setport* | awk -F: '{print $1}' | uniq)

	# replace 9003
	for i in $all_files;do sed -i "s/9003/$api/g" $i;done;echo "set api port is $api"
	# replace 9004
	for i in $all_files;do sed -i "s/9004/$p2p/g" $i;done;echo "set p2p port is $p2p"
	# replace 9005
	for i in $all_files;do sed -i "s/9005/$debug/g" $i;done;echo "set debug port is $debug"
	# replace nat-ip
	sed -i "s/natip/$pub_ip/" ./bee.yaml
	
	case $1 in
	#	setport)
	#		setport
	#		;;
			-h)
			helper
			;;
	esac
}

