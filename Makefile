# Makefile for Open AS Communication Gateway
# Author: Erik Sonnleitner
# Contact: es@delta-xi.net
# vim: ts=4:sw=4


all: clean prepare build-cyrus-sasl build-limesas install

clean:
	rm -rf devel

prepare:
	aptitude update
	./scripts/install-package-list.sh scripts/packagelist-build-deps-lucid
	debconf-set-selections scripts/selections-postfix-policyd
	./scripts/install-package-list.sh scripts/packagelist-runtime-deps-lucid
	./scripts/install-cpan-modules.sh

build-cyrus-sasl:
	cd ext/cyrus-sasl-patch && ./build.sh

build-limesas:
	./scripts/build.pl

install:
	dpkg -i ext/cyrus-sasl-patch/*.deb
	dpkg -i devel/limesas-gui_*.deb
	dpkg -i devel/limesas-lib_*.deb
	dpkg -i devel/limesas_*.deb

