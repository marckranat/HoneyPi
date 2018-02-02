#!/bin/bash

#check root
if [ $UID -ne 0 ]; then
	echo "Please run this script as root: sudo $0"
	exit 1
fi

#outgoing e-mail server address
mailhub=$(whiptail --inputbox "Provide outgoing e-mail server address" 10 60 "smtp.gmail.com" 3>&1 1>&2 2>&3)
if [ -z $mailhub ]; then
	exit 1 #cancel has been selected
fi

#outgoing server port
port=$(whiptail --inputbox "Provide outgoing e-mail server port" 10 60 "587" 3>&1 1>&2 2>&3)
if [ -z $port ]; then
	exit 1 #cancel has been selected
fi

#enable STARTTLS
whiptail --yesno "Enable STARTTLS ?" 10 60
starttls_yesno=$?

#username
username=$(whiptail --inputbox "Provide username of your e-mail account" 10 60 3>&1 1>&2 2>&3)
if [ -z $username ]; then
	exit 1 #cancel has been selected
fi

#passsword
password=$(whiptail --inputbox "Provide password for your e-mail account" 10 60 3>&1 1>&2 2>&3)
if [ -z $password ]; then
	exit 1 #cancel has been selected
fi

#setup SSMTP configuration
function setup_ssmtp_conf() {
	SED_CMD="\@$1=@d"
	sed -i -e "$SED_CMD" /etc/ssmtp/ssmtp.conf
	SED_CMD="\$a$1=$2"
	sed -i -e "$SED_CMD" /etc/ssmtp/ssmtp.conf
}
setup_ssmtp_conf "mailhub" "$mailhub:$port"
if [ $starttls_yesno ]; then
	setup_ssmtp_conf "UseSTARTTLS" "YES"
else
	setup_ssmtp_conf "UseSTARTTLS" "NO"
fi
setup_ssmtp_conf "AuthUser" "$username"
setup_ssmtp_conf "AuthPass" "$password"

# get e-mail address where all messages will be send
email=$(whiptail --inputbox "Provide an e-mail address where all messages will be send" 10 60 3>&1 1>&2 2>&3)
if [ -z $email ]; then
	exit 1 #cancel has been selected
fi
sed -i "s/xemailx/$email/g" psad.conf

#test configuration
whiptail --yesno "Do you want to test the configured e-mail client ?" 10 60
test_yesno=$?
if [ $test_yesno ]; then
	echo "Sending a test message to $email..."
	result=$("test from RPi" | ssmtp $email)
	if [ $result ]; then
		whiptail --msgbox "Cannot send test message to ${email}. $result. Please check your settings." 20 60
		echo $result
	fi
fi
