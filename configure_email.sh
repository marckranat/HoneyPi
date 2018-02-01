#!/bin/bash

#check root
if [ $UID -ne 0 ]; then
	echo "Please run this script as root: sudo $0"
	exit 1
fi

echo "Install required dependences..."
apt install -y ssmtp

#outgoing e-mail server address
echo -n "Provide outgoing e-mail server address [smtp.gmail.com]: "
read mailhub
if [ -z "$mailhub" ]; then
	mailhub="smtp.gmail.com"
fi

#outgoing server port
echo -n "Provide outgoing e-mail server port [587]: "
read port
if [ -z "$port" ]; then
	port="587"
fi

#enable STARTTLS
echo -n "Enable STARTTLS (y/n) [Y]?: "
read starttls_yesno
if [ -z "$starttls_yesno" ]; then
	starttls_yesno="Y"
fi

#username
echo -n "Provide username of your e-mail account: "
read username

#passsword
echo -n "Provide password for your e-mail account: "
read password

#setup SSMTP configuration
function setup_ssmtp_conf() {
	SED_CMD="\@$1=@d"
	sed -i -e "$SED_CMD" /etc/ssmtp/ssmtp.conf
	SED_CMD="\$a$1=$2"
	sed -i -e "$SED_CMD" /etc/ssmtp/ssmtp.conf
}
setup_ssmtp_conf "mailhub" "$mailhub:$port"
if [ "Y" == "$starttls_yesno" ] || [ "y" == "$starttls_yesno" ]; then
	setup_ssmtp_conf "UseSTARTTLS" "YES"
else
	setup_ssmtp_conf "UseSTARTTLS" "NO"
fi
setup_ssmtp_conf "AuthUser" "$username"
setup_ssmtp_conf "AuthPass" "$password"

#test configuration
echo -n "Do you want to test the configured e-mail client (y/n) [Y]?:"
read test_yesno
if [ -z "$test_yesno" ]; then
	test_yesno="Y"
fi
if [ "Y" == "$test_yesno" ] || [ "y" == "$test_yesno" ]; then
	echo -n "Provide an e-mail address where the message will be send: "
	read email
	echo "Sending a test message to $email..."
	echo "test from RPi" | ssmtp $email
	echo "Done"
fi
