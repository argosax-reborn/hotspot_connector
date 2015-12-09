#! /bin/bash
#Android version
#Need curl and openssl for android
# curl site - android linux version
# untar, and cp
#bin into /system/bin
#with the help of su && mount -o rw,remount /system
#then from host, adb push curl openssl /storage/sdcard0/
#and finally from the android
#cd /storage/sdcard0/ && su && cp curl openssl /system/bin/
#created by Majes for majestikfortress.com

# Hotspot connection
screen -X -S hotspotdaemon quit
screen -dmS hotspotdaemon "wpa_supplicant -i wlan1 -c /etc/wpa_supplicant.conf"
#dhclient wlan1

# Captive portal defeating
service openvpn stop
path=/tmp/
#pathtocert=--cacert /data/local/ssl/certs/ca-bundle.crt
pathtocert=""
loop=0
while loop==0 ;
do
	trap "exit" INT
	url="https://hotspot.wifi.sfr.fr/nb4_crypt.php"
	okmatch="licitations"

	#PARAMETRES A REMPLIR
	login="ID"
	password="pass"

	rm /$path/hotspot.txt /$path/hotspot2.txt
	touch /$path/hotspot.txt
	touch /$path/hotspot2.txt


## TODO
## Refaire avec functions
## Check sur le ping
## if no ping || no curl
## 	Phase1,2 et 3
## else
##	sleep 10 and check

	# Phase I
	curl -silent -L http://www.google.com $pathtocert > /$path/hotspot.txt
	chall=$(cat /$path/hotspot.txt |awk -F "=" '/&challenge=/ {print $5}'| sed '1!d'|sed 's/&userurl//g')
	echo "challenge: ${chall}"
	if [ -z $chall ]
	then
		service openvpn stop
		echo "Connection is Ok !"
		echo "Checking connection every 5minutes"
		curl -silent -L http://www.google.com $pathtocert > /$path/hotspot.txt
		chall=$(cat /$path/hotspot.txt |awk -F "=" '/&challenge=/ {print $5}'| sed '1!d'|sed 's/&userurl//g')
		service openvpn start
		sleep 600
	else
	# Phase II
	curl -silent -L -d "username=${login}&password=${password}&cond=on&accessType=neuf&nb4=https://hotspot.wifi.sfr.fr/nb4_crypt.php&challenge=${chall}" ${url} $pathtocert > /$path/hotspot2.txt
	response=$(cat /$path/hotspot2.txt|awk -F "=" '/response=/ {print $4}'|sed 's/&amp;uamip//g')
	echo "reponse: ${response}"

	# Phase III
	final=`curl -silent -L "http://192.168.2.1:3990/logon?username=ssowifi.neuf.fr/${login}&response=${response}&uamip=192.168.2.1&userurl=http%3A%2F%2Fwww.fon.com%2Ffr%2Flanding%2Ffoneroneufbox%3Bfon%3B%3B&lang=fr&ARCHI" $pathtocert|grep ${okmatch}`
	service openvpn start
	sleep 3600
	fi
done
echo "Bye"
