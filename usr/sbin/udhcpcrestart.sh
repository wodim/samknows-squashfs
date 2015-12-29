#!/bin/sh


GW=`route -n | grep "^0.0.0.0" | sed -n 's/^0.0.0.0 *\([0-9\.]*\) .*/\1/p'`
if [ "$GW" != "" ]; then
	echo "default GW = $GW"
else
	echo "restarting udhcpc to get gateway"
	killall udhcpc
	killall -9 udhcpc
	/sbin/udhcpc -t 0 -i br-lan -b -p /var/run/dhcp-br-lan.pid -O rootpath -R
	exit 0
fi	

res=$(ping -c 1 -q ${GW} | grep "packets received" | sed -n 's/.* packets transmitted, *\(.*\) packets received.*/\1/p');

if [ "$res" != "1" ]; then
	echo "GW $GW is not reachable cnt = $res"
	echo "restarting udhcpc to get new lease"
	killall udhcpc
	killall -9 udhcpc
	/sbin/udhcpc -t 0 -i br-lan -b -p /var/run/dhcp-br-lan.pid -O rootpath -R
else
	echo "GW $GW is reachable packets received = $res"
fi

