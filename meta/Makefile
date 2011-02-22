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


PREFIX?=debian/limesas/etc


all: limesas

.PHONY: all install clean distclean

# Put here all files that you want to install
limesas: versions
	
# Put here an instruction what to do with these files, + change of rights and so on
install: versions
	mkdir -p $(PREFIX)/limes
	install versions $(PREFIX)/limes
	chmod -R 644 $(PREFIX)/limes/*

clean:

distclean: clean

uninstall:
	rm -R $(PREFIX)/limes
