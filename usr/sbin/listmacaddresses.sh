#!/bin/sh
MAC=""
MAC1=""
MAC2=""
INTERFACES=$(find /sys/devices/platform -path  *net* -name address)
for i in $INTERFACES;
do
	INT=$(echo $i | sed 's/^.*net\///g;s/\/.*$//g')
	ADDR=$(cat $i | sed 's/\://g' | tr '[a-f]' '[A-F]')
	case "$INT" in
	"wlan0") 
		MAC=$ADDR
		;;
	"eth0")
		MAC1=$ADDR
		;;
	"eth1")
		MAC2=$ADDR
		;;
	esac
done
echo mac=${MAC}\&mac1=${MAC1}\&mac2=${MAC2} 
