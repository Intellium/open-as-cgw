# This file is part of the Open AS Communication Gateway.
#
# The Open AS Communication Gateway is free software: you can redistribute it
# and/or modify it under theterms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the License,
# or (at your option) any later version.
#
# The Open AS Communication Gateway is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero
# General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License along
# with the Open AS Communication Gateway. If not, see http://www.gnu.org/licenses/.


PREFIX?=debian/limesas-lib
# PERLDIR?=usr/local/share/perl/5.8.8
PERLDIR?=usr/local/share/perl/5.10.1
LIMES?=etc/limes
BIN?=usr/local/bin
LIB?=usr/local/lib
CACERT?=usr/share/ca-certificates


all: limesas-lib

.PHONY: all install clean distclean

# Put here all files that you want to install
limesas-lib: Underground8
	
# Put here an instruction what to do with these files, + change of rights and so on
install: limesas-lib
	mkdir -p $(PREFIX)/${PERLDIR}/Underground8
	mkdir -p $(PREFIX)/${PERLDIR}/Catalyst
	mkdir -p $(PREFIX)/${PERLDIR}/Data
	mkdir -p $(PREFIX)/${PERLDIR}/HTML
	mkdir -p $(PREFIX)/${CACERT}

	mkdir -p ${PREFIX}/${LIMES}/cfg-templates
	mkdir -p ${PREFIX}/${LIMES}/xml
	mkdir -p ${PREFIX}/${LIMES}/conf
	mkdir -p ${PREFIX}/${LIMES}/xml_backup
	mkdir -p ${PREFIX}/${LIMES}/db_struct
	mkdir -p ${PREFIX}/etc/event.d
	mkdir -p ${PREFIX}/${BIN}
	# mkdir -p ${PREFIX}/${LIB}/modules
	# mkdir -p ${PREFIX}/${LIB}/drivers

	mkdir -p $(PREFIX)/var/limes/backup	
	
	cp -rf cfg-templates/* ${PREFIX}/${LIMES}/cfg-templates
	cp -rf xml_backup/* ${PREFIX}/${LIMES}/xml_backup
	cp -rf db_struct/* ${PREFIX}/${LIMES}/db_struct
	cp -rf conf/* ${PREFIX}/${LIMES}/conf
	cp -f  avail_secversion ${PREFIX}/${LIMES}
	cp -rf event.d/* ${PREFIX}/etc/event.d
	cp -rf bin/* ${PREFIX}/${BIN}
	# cp -rf modules/* ${PREFIX}/${LIB}/modules
	# cp -rf drivers/* ${PREFIX}/${LIB}/drivers
	cp -rf Underground8/* $(PREFIX)/${PERLDIR}/Underground8
	cp -rf Catalyst/* $(PREFIX)/${PERLDIR}/Catalyst
	cp -rf Data/* $(PREFIX)/${PERLDIR}/Data
	cp -rf HTML/* $(PREFIX)/${PERLDIR}/HTML
	cp -rf ca-certificates/* $(PREFIX)/${CACERT}



clean:

distclean: clean

uninstall:
	rm -rf $(PREFIX)/${PERLDIR}Underground8
	rm -rf ${PREFIX}/${BIN}
