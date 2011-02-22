#!/bin/bash

VERSION="2.1.23"
SRC="ftp://ftp.andrew.cmu.edu/pub/cyrus-mail/cyrus-sasl-$VERSION.tar.gz"
PATCH="u8_sasl_proxy.patch"
DEBIAN_DIR="debian-dir.tar.bz2"

rm -rf cyrus*
wget $SRC
tar xfvz `basename $SRC`

cp $PATCH "cyrus-sasl-$VERSION"
cp $DEBIAN_DIR "cyrus-sasl-$VERSION"

cd "cyrus-sasl-$VERSION"
# patch -p1 < $PATCH
quilt import $PATCH
quilt push

#./configure --with-saslauthd=/var/spool/postfix/var/run/saslauthd --with-des=no
#if [ $? eq 0 ]; then
#	echo "Aborted."
#	exit 1
#fi

#cd saslauthd
#./configure --with-saslauthd=/var/spool/postfix/var/run/saslauthd --with-des=no
#if [ $? eq 0 ]; then
#	echo "Aborted."
#	exit 1
#fi

#make

tar xfj $DEBIAN_DIR
dpkg-buildpackage


