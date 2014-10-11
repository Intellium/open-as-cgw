# Makefile for Open AS Communication Gateway
# Author: Erik Sonnleitner
# Contact: es@delta-xi.net
# vim: ts=4:sw=4


all: clean prepare build-cyrus-sasl build-limesas finalize

clean:
	rm -rf devel

prepare:
	aptitude update
	./scripts/install-package-list.sh scripts/packagelist-build-deps-trusty
	debconf-set-selections scripts/selections-postfix-policyd
	./scripts/install-package-list.sh scripts/packagelist-runtime-deps-trusty
	./scripts/install-cpan-modules.sh

build-cyrus-sasl:
	cd ext/cyrus-sasl-patch && ./build.sh

build-limesas:
	./scripts/build.pl

	mv ext/cyrus-sasl-patch/*.deb devel/
	
install:
	dpkg -i release/cyrus-sasl-patch/*.deb
	dpkg -i release/limesas-gui_*.deb
	dpkg -i release/limesas-lib_*.deb
	dpkg -i release/limesas_*.deb
