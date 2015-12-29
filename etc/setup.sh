#!/bin/ash

skledoff() {
	echo none > /sys/class/leds/tp-link:green:qss/trigger
	echo 0 > /sys/class/leds/tp-link:green:qss/brightness
}
                
skledon() {
	echo 255 > /sys/class/leds/tp-link:green:qss/brightness
}
                        
skledactivity() {
	echo timer > /sys/class/leds/tp-link:green:qss/trigger
	echo 100 > /sys/class/leds/tp-link:green:qss/delay_off
	echo 100 > /sys/class/leds/tp-link:green:qss/delay_on
}
                                                
skleddelay() {
	echo timer > /sys/class/leds/tp-link:green:qss/trigger
	echo 250 > /sys/class/leds/tp-link:green:qss/delay_off
	echo 250 > /sys/class/leds/tp-link:green:qss/delay_on
}

/usr/sbin/listmacaddresses.sh > /tmp/macaddresses.txt

# Set QSS LED flashing
skledactivity

# Sleep randomly
sleep $(($RANDOM % 60))
 
# Setup time
REMOTENOW=`curl -m 20 -s "http://ntp.samknows.com/?tz=UTC&fmt=new"`
if [ $? -eq 0 ]; then
   TZ=UTC date -s "$REMOTENOW"
   logger -s -p 6 -t 'pm' "setup.sh (Info) Time synced successfully, time is now `date`"
fi

# Check time
NOW=`date +%s`
if [ $NOW -lt 1206316800 ]; then
   logger -s -p 6 -t 'pm' "setup.sh (Error) Time is clearly wrong (`date`)"
fi

if [ ! -s /tmp/macaddresses.txt ]; then
   mac=$(/sbin/ifconfig br-lan | grep 'HWaddr' | sed -n 's/.*HWaddr *\([A-F0-9:]*\) */\1/p' | sed -e 's/://g');
   mac="mac=${mac}"
else
   mac=$(cat /tmp/macaddresses.txt)
fi
mkdir -p /tmp/samknows
http_code=$(curl  --cacert /etc/ca-bundle.crt -m 20 -o /tmp/samknows/dcs  -w "%{http_code}" "https://dcs.samknows.com/dcs?${mac}&model=wr741ndv4" 2>/dev/null);
ecode=$?
if [ "${ecode}" = "0" ] && [ "${http_code}" -eq "200" ]; then
        DCSSERVER=$(cat /tmp/samknows/dcs);
	# Run the DCS client
	/usr/sbin/dcsclient https://"$DCSSERVER" -a
	RET=$?
	echo none > /sys/class/leds/tp-link:green:qss/trigger
	if [ $RET -eq 0 ]; then
		logger -s -p 6 -t 'pm' "setup.sh (Info) Unit Activation Successfull with DCS ${DCSSERVER}"
		skledon
	else
		logger -s -p 6 -t 'pm' "setup.sh (Info) Unit Activation Fail with DCS ${DCSSERVER}"
		skleddelay
	fi
        exit 0
else
	logger -s -p 6 -t 'pm' "setup.sh (Info) Unit doesn't know the DCSSERVER to activate with"
	echo none > /sys/class/leds/tp-link:green:qss/trigger
	skleddelay
        exit 2
fi
