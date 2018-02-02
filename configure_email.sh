#!/bin/bash

#check root
if [ $UID -ne 0 ]; then
	echo "Please run this script as root: sudo $0"
	exit 1
fi

#outgoing e-mail server address
mailhub=$(whiptail --inputbox "Provide outgoing e-mail server address [smtp.gmail.com]" 20 60 3>&1 1>&2 2>&3)
if [ -z "$mailhub" ]; then
	mailhub="smtp.gmail.com"
fi

#outgoing server port
port=$(whiptail --inputbox "Provide outgoing e-mail server port [587]" 20 60 3>&1 1>&2 2>&3)
if [ -z "$port" ]; then
	port="587"
fi

#enable STARTTLS
starttls_yesno=$(whiptail --yesno "Enable STARTTLS ?" 0 0 3>&1 1>&2 2>&3)

#username
username=$(whiptail --inputbox "Provide username of your e-mail account" 20 60 3>&1 1>&2 2>&3)

#passsword
password=$(whiptail --inputbox "Provide password for your e-mail account" 20 60 3>&1 1>&2 2>&3)

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

#test configuration
test_yesno=$(whiptail --yesno "Do you want to test the configured e-mail client ?" 0 0 3>&1 1>&2 2>&3)
if [ $test_yesno ]; then
	email=$(whiptail --inputbox "Provide password for your e-mail account" 20 60 3>&1 1>&2 2>&3)
	echo "Sending a test message to $email..."
	echo "test from RPi" | ssmtp $email
	echo "Done"
fi
