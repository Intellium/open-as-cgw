#!/bin/bash
# This script aims to automatically install all necessary Ubuntu packages on
# the target AS system.

if [ ! -s $1 ]; then
	echo "Fatal: give me a (valid) packagelist as argument."
	exit 1
fi



# No interactivity, whatsoever
UCF_FORCE_CONFFNEW="yes"
DEBCONF_FRONTEND="noninteractive"
DEBIAN_FRONTEND="noninteractive"

if [ `id -u` -ne 0 ]; then
	echo "Fatal: You have to call this script as root."
	exit 1
fi


PACKAGE_LIST=`cat $1 | egrep -v "^#.*" | egrep -v "^$" | awk '{ print \$1 }'`


DEBCONF_FRONTEND=noninteractive DEBIAN_FRONTEND=noninteractive UCF_FORCE_CONFFNET=yes /usr/bin/aptitude -y -R \
 -o Dpkg::Options::=--force-confnew \
 -o Dpkg::Options::=--force-confmiss install $PACKAGE_LIST
