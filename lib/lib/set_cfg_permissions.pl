#!/usr/bin/perl

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

use strict;
use warnings;
use File::stat;

my $group = 'limes';
my $gid   = getgrnam($group);

my @files = qw(
/etc/environment
/etc/network/interfaces
/etc/postfix/main.cf
/etc/postfix/master.cf
/etc/postfix/transport
/etc/postfix/sasl/smtpd.conf 
/etc/resolv.conf
/etc/hosts
/etc/hostname
/etc/mailname
/etc/amavis/conf.d/15-content_filter_mode
/etc/amavis/conf.d/99-limes
/etc/amavis/conf.d/20-debian_defaults
/etc/amavis/conf.d/15-av_scanners
/etc/clamav/clamd.conf
/etc/clamav/freshclam.conf
/etc/kav/kav_server.conf
/etc/kav/kav_updater.conf
/etc/avira/avira.conf
/etc/avira/update-vdf.conf
/etc/avira/mirror.conf
/etc/sambucus/main.cfg
/etc/sambucus/roles.cfg
/etc/postfix-policyd.conf
/etc/postfix-policyd2.conf
/etc/default/postfix-policyd
/etc/init.d/postfix-policyd
/etc/postfix/main.cf
/etc/postfix/filter-dynip.pcre
/etc/postfix/amavis_bypass_filter
/etc/postfix/amavis_bypass_filter_smtpcrypt
/etc/postfix/amavis_bypass_accept
/etc/postfix/amavis_senderbypass_filter
/etc/postfix/amavis_senderbypass_accept
/etc/postfix/amavis_bypass_internal_filter
/etc/postfix/amavis_bypass_internal_warn
/etc/postfix/amavis_bypass_internal_accept
/etc/postfix/local_rcpt_map
/etc/postfix/mbox_transport
/etc/postfix/virtual_mbox
/etc/postfix/virtual_alias
/etc/postfix/usermaps
/etc/postfix/header_checks
/etc/postfix/postfwd.cf
/etc/default/postfwd
/etc/spamassassin/local.cf
/var/log/limes/mail.log
/etc/localtime
/etc/ntp.conf
/var/lib/spamassassin/updates_spamassassin_org.cf
/usr/local/bin/firewall.sh
/etc/sasl.cf
/etc/mysql/my.cnf
/etc/monit/monitrc
/etc/default/monit
/etc/syslog-ng/syslog-ng.conf
/etc/logrotate.d/syslog-ng
/boot/grub/menu.lst
/etc/lsb-release
/etc/default/batv-filter
/etc/mail/batv-filter.relay
/etc/mail/batv-filter.domains
/etc/mail/batv-filter.key
/etc/limes/xml/antispam.xml
/etc/limes/xml/backup.exclude
/etc/limes/xml/backup.include
/etc/limes/xml/backup.xml
/etc/limes/xml/notification.xml
/etc/limes/xml/postfwd.xml
/etc/limes/xml/quarantine.xml
/etc/limes/xml/system.xml
/etc/limes/xml/usermaps.xml
/etc/limes/xml/smtpcrypt.xml
/etc/limes/conf/as_license.ulf
/etc/default/snmpd
/etc/snmp/snmpd.conf
);

print "\n\nChanging file ownerships and permissions to read/write for group: $group\n";
print "-" x 75 . "\n";
foreach my $file (@files) {
    printf("File: %s\n",$file);
    chomp $file;
    unless (-e $file) {
        print "does not exist - creating directory and touching file\n";
        system("mkdir -p $1") if $file =~ /^(\/.+)\/.+?$/;
        system("touch $file");
    }

    my $info = stat($file) or die "$file does not exist!";
    unless (chown ($info->uid, $gid, $file)) {
        print "Failed to set ownership.\n";
    } # else { print "\tOwner: ".getpwuid($info->uid).".".getgrgid($info->gid)." --> ".getpwuid($info->uid).".".$group."\n"; }
    
    my $mode = $info->mode & 07777 | 48; # add read+write to group permissions
    unless (chmod ($mode,$file)) {
        print "Failed to set permissions.\n";
    } # else { printf("\tPermissions: %04o --> %04o\n",$info->mode & 07777, $mode); }
}

system("/bin/chmod 755 /usr/local/bin/sasl_auth.pl");
system("/bin/chown smtpcrypt:limes /etc/limes/xml/smtpcrypt.xml");
system("/bin/chgrp limes /var/log/mail-simple*");
