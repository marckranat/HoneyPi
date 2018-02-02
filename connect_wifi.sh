#!/bin/bash

#check root
if [ $UID -ne 0 ]; then
	echo "Please run this script as root: sudo $0"
	exit 1
fi

OLD_IFS="$IFS"
IFS=$'\n'
ssid_arr=( $(iwlist wlan0 scan | grep -oP "(?<=ESSID:).*") )
quality_arr=( $(iwlist wlan0 scan | grep "Quality") )
IFS="$OLD_IFS"

len=${#ssid_arr[@]}

# no available WiFi networks
if [ 0 -eq $len ]; then
	echo "No WiFi network to connect to. Please check your settings."
	exit 1
fi

#select a WiFi network if several are available
net_idx=0
if [ 1 -ne $len ]; then
	echo -e "Choose the WiFi network you want to connect to:\n"
	for ((i = 0; len != i; i++)); do
		echo -ne "\t#$i  ESSID: "
		echo "${ssid_arr[$i]}" | xargs
		echo -ne "\t    "
		echo "${quality_arr[$i]}" | xargs
	done
	echo -ne "\nSelected network index [0]: "
	read net_idx
	if [ -z "$net_idx" ]; then
		net_idx=0
	fi
fi

net_ssid=${ssid_arr[$net_idx]}
echo -n "Provide password for WiFi network $net_ssid: "
read net_pwd

#remove previous configuration from wpa_supplicant.conf
SED_CMD="\@network=@d"
sudo sed -i -e "$SED_CMD" /etc/wpa_supplicant/wpa_supplicant.conf
SED_CMD="\@ssid=@d"
sudo sed -i -e "$SED_CMD" /etc/wpa_supplicant/wpa_supplicant.conf
SED_CMD="\@psk=@d"
sudo sed -i -e "$SED_CMD" /etc/wpa_supplicant/wpa_supplicant.conf
SED_CMD="\@^}@d"
sudo sed -i -e "$SED_CMD" /etc/wpa_supplicant/wpa_supplicant.conf

#create new network configuration
SED_CMD="\$anetwork={"
sed -i -e "$SED_CMD" /etc/wpa_supplicant/wpa_supplicant.conf
SED_CMD="\$assid=$net_ssid"
sed -i -e "$SED_CMD" /etc/wpa_supplicant/wpa_supplicant.conf
SED_CMD="\$apsk=\"$net_pwd\"}"
sed -i -e "$SED_CMD" /etc/wpa_supplicant/wpa_supplicant.conf
SED_CMD="\$a}"
sed -i -e "$SED_CMD" /etc/wpa_supplicant/wpa_supplicant.conf

#connect to the configured network
echo "Connecting to ${net_ssid}..."
result=`wpa_cli -i wlan0 reconfigure`
echo $result

if [ "$result" == "OK" ]; then
	echo -n "Assigned address: "
	ifconfig wlan0 | grep inet | head -n 1 | xargs
	echo
fi
