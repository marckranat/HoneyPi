#!/bin/bash

#check root
if [ $UID -ne 0 ]
then
 echo "Please run this script as root: sudo honeyPI.sh"
 exit 1
fi

####Disclaimer!###
if whiptail --yesno "Hey Hey! You're about to install honeyPi to turn this Raspberry Pi into an IDS/honeypot. Congratulations on being so clever. This install process will change some things on your Pi. Most notably, it will flush your iptables and turn up logging. Select 'Yes' if you're cool with all that or 'No' to stop now." 20 60
then
  echo "continue"
else
  exit 1
fi

####Change password if you haven't yet###
if [ $SUDO_USER == 'pi' ]
then
 if whiptail --yesno "You're currently logged in as default pi user. If you haven't changed the default password 'raspberry' would you like to do it now?" 20 60
 then
  passwd
 fi
fi

####Install Debian updates ###
if whiptail --yesno "Let's install some updates. Answer 'no' if you are just experimenting and want to save some time (updates might take 15 minutes or more). Otherwise, shall we update now?" 20 60
then
 apt-get update
 apt-get upgrade
fi


####Name the host something enticing ###
sneakyname=$(whiptail --inputbox "Let's name your honeyPi something enticing like 'SuperSensitiveServer'. Well maybe not that obvious, but you get the idea. Remember, hostnames cannot contain spaces or most special chars. Best to keep it to just alphanumeric and less than 24 characters." 20 60 3>&1 1>&2 2>&3)
if [ -z $sneakyname ]; then
	exit 1 #cancel has been selected
fi
echo $sneakyname > /etc/hostname
echo "127.0.0.1 $sneakyname" >> /etc/hosts

####Install PSAD ###
whiptail --infobox "Installing a bunch of software like the log monitoring service and other dependencies...\n" 20 60
apt-get -y install psad ssmtp python-twisted iptables-persistent libnotify-bin fwsnort

###Choose Notification Option###
OPTION=$(whiptail --menu "Choose how you want to get notified:" 20 60 5 "email" "Send me an email" "script" "Execute a script" "blink" "Blink a light on your Raspberry Pi" 3>&2 2>&1 1>&3)
if [ -z $OPTION ]; then
	exit 1 #cancel has been selected
fi
emailaddy=test@example.com
enablescript=N
externalscript=/bin/true
alertingmethod=ALL
check=1

# get folder of the current script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

case $OPTION in
	email)
		( "$DIR/configure_email.sh" )
	;;
	script)
		externalscript=$(whiptail --inputbox "Enter the full path and name of the script you would like to execute when an alert is triggered:" 20 60 3>&1 1>&2 2>&3)
		enablescript=Y
		alertingmethod=noemail
	;;
	blink)
		enablescript=Y
		alertingmethod=noemail
		externalscript="/usr/bin/python /root/honeyPi/blinkonce.py"
	;;
esac

( "$DIR/connect_wifi.sh" )

###update vars in configuration files
sed -i "s/xhostnamex/$sneakyname/g" psad.conf
#sed -i "s/xemailx/$emailaddy/g" psad.conf
sed -i "s/xenablescriptx/$enablescript/g" psad.conf
sed -i "s/xalertingmethodx/$alertingmethod/g" psad.conf
sed -i "s=xexternalscriptx=$externalscript=g" psad.conf
sed -i "s/xcheckx/$check/g" psad.conf


###Wrap up everything and exit
whiptail --msgbox "Configuration files created. Next we will move those files to the right places." 20 60
mkdir -p /root/honeyPi
cp blink*.* /root/honeyPi
cp psad.conf /etc/psad/psad.conf
iptables --flush
iptables -A INPUT -p igmp -j DROP
#too many IGMP notifications. See if that prevents it
iptables -A INPUT -j LOG
iptables -A FORWARD -j LOG
service netfilter-persistent save
service netfilter-persistent restart
psad --sig-update
service psad restart
cp mattshoneypot.py /root/honeyPi
(crontab -l 2>/dev/null; echo "@reboot python /root/honeyPi/mattshoneypot.py &") | crontab -
python /root/honeyPi/mattshoneypot.py &
ifconfig
printf "\n \n ok. should be good to go. Now go portscan this honeyPi and see if you get an alert!\n"
