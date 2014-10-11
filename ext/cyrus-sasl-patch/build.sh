#!/bin/bash

# settings
VERSION="2.1.25"
SRC="ftp://ftp.cyrusimap.org/cyrus-sasl/cyrus-sasl-$VERSION.tar.gz"
PATCH="u8_sasl_proxy.patch"
DEBSRC="debian.tar.gz"

# cleanup from previous builds
rm -rf cyrus*

# get cyrus src and extract
wget $SRC
tar xfvz `basename $SRC`

# get debian sources and unpack
#apt-get source cyrus-sasl2
tar xfvz $DEBSRC

# copy patches and package dependencies
cp $PATCH "cyrus-sasl-$VERSION"
mv debian "cyrus-sasl-$VERSION"

# switch to cyrus-sasl dir
cd "cyrus-sasl-$VERSION"

# apply patch
quilt import $PATCH
quilt push

# build deb package
dpkg-buildpackage -b
