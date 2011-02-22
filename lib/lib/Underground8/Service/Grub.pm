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


package Underground8::Service::Grub;
use base Underground8::Service;


use strict;
use warnings;

use Underground8::Utils;
use Underground8::Service::Grub::SLAVE;
use Data::Dumper;

# Constructor
sub new ($$)
{
    my $class = shift;
    my $name = shift;

    my $self = $class->SUPER::new();
    $self->{'_slave'} = new Underground8::Service::Grub::SLAVE();
    $self->{'_limits'} = {};
    $self->{'_type'} = "N";
    $self->{'_version'} = "";
    $self->{'_uuid'} = "/dev/sda1";
    return $self;
}

#### Accessors ####

sub limits($)
{
    my $self = instance(shift);
    return $self->{'_limits'};
}

sub type($)
{
    my $self = instance(shift);
    return $self->{_type};
}

sub version($)
{
    my $self = instance(shift);
    return $self->{_version};
}

sub uuid($)
{
    my $self = instance(shift);
    return $self->{'_uuid'};
}

sub set_type ($)
{
    my $self = instance(shift);
    $self->{'_type'} = shift;
    $self->change;
}

sub set_version ($)
{
    my $self = instance(shift);
    $self->{'_version'} = shift;
    $self->change;
}

sub set_uuid ($)
{
    my $self = instance(shift);
    $self->{'_uuid'} = shift;
    $self->change;
}

sub set_limits($$$)
{
    my $self = instance(shift);
    my $ram = shift;
    my $cpus = shift;
    $self->{'_limits'}->{'ram'} = $ram;
    $self->{'_limits'}->{'cpus'} = $cpus;    
    $self->change;
}


sub commit ($)
{
    my $self = instance(shift);
    $self->slave->write_config( $self->limits, $self->type, $self->version, $self->uuid ) if( $self->is_changed() );
    $self->unchange;
}

1;
