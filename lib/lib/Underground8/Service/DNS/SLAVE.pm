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


package Underground8::Service::DNS::SLAVE;
use base Underground8::Service::SLAVE;

use strict;
use warnings;
use Underground8::Utils;
use Error;
use Underground8::Exception::FileOpen;
use Underground8::Exception::Execution;

sub new ($)
{
    my $class = shift;
    my $self = $class->SUPER::new('dns');
}

sub service_start ($)
{
    # nothing to do here 
}

sub service_stop ($)
{
    # nothing to do here
}

# call /etc/init.d/hostname.sh
sub service_restart ($$)
{
    my $self = instance(shift);
    
    safe_system($g->{'cmd_hostname_change'},1); # return code 1 is ok
    safe_system($g->{'cmd_dnsmasq_restart'}); # return code 1 is ok
}

sub write_config ($$$$$)
{
    my $self = instance(shift);
    my $primary_dns = shift;
    my $secondary_dns = shift;
    my $use_local_cache = shift;
    my $hostname = shift;
    my $domainname = shift;

    $self->write_resolv_conf($primary_dns,
                             $secondary_dns,
                             $use_local_cache,
                             $domainname);

    $self->write_hosts_file($hostname,
                            $domainname);
    
    $self->write_hostname_file($hostname);
    $self->write_mailname_file($domainname);
}

sub write_hostname_file ($$)
{
    my $self = instance(shift);
    my $hostname = shift;
    
    open (HOSTNAME, '>', $g->{'file_hostname'})
        or throw Underground8::Exception::FileOpen($g->{'file_hostname'});
    
    print HOSTNAME "$hostname\n";

    close (HOSTNAME);
}

sub write_mailname_file ($$)
{
    my $self = instance(shift);
    my $mailname = shift;
    
    open (MAILNAME, '>', $g->{'file_mailname'})
        or throw Underground8::Exception::FileOpen($g->{'file_mailname'});
    
    print MAILNAME "$mailname\n";

    close (MAILNAME);
}

sub write_hosts_file ($$$)
{
    my $self = instance(shift);
    my $hostname = shift;
    my $domainname = shift;

    open (HOSTS, '>', $g->{'file_hosts'})
        or throw Underground8::Exception::FileOpen($g->{'file_hosts'}); 
    
    print HOSTS "127.0.0.1    localhost\n";
    print HOSTS "127.0.1.1    $hostname.$domainname $hostname\n";

    close (HOSTS);
}

sub write_resolv_conf($$$$$)
{
    my $self = instance(shift);
    my $primary_dns = shift;
    my $secondary_dns = shift;
    my $use_local_cache = shift;
    my $domainname = shift;

    open (RESOLV, '>', $g->{'file_resolv'})
        or throw Underground8::Exception::FileOpen($g->{'file_resolv'});

    print RESOLV "### automatically created by LIMES ###\n";
    print RESOLV "search $domainname\n";

    if ($use_local_cache)
    {
        print RESOLV "nameserver 127.0.0.1\n";
    }
    
    print RESOLV "nameserver $primary_dns\n";
    print RESOLV "nameserver $secondary_dns\n";
    
    close (RESOLV);
}
1;
