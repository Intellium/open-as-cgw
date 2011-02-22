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


package Underground8::Service::Grub::SLAVE;
use base Underground8::Service::SLAVE;

use strict;
use warnings;
use Underground8::Utils;
use Error;
use Underground8::Exception::FileOpen;
use Data::Dumper;

sub new ($)
{
    my $class = shift;
    my $self = $class->SUPER::new('timesync');
}

sub service_start ($)
{
    # none 
}

sub service_stop ($)
{
    # none
}

sub service_restart ($$)
{
    #my $self = instance(shift);
    #my $output = safe_system($g->{'cmd_system_restart'},0,1);
}

sub service_update_grub ($$)
{
    my $self = instance(shift);
    my $output = safe_system($g->{'cmd_grub_update'},0,1);
}

sub write_config ($@)
{
    my $self = instance(shift); 
    my $limits = shift;
    my $type = shift;
    my $version = shift;
    my $uuid = shift;

    $self->write_lsb_release($version);
    $self->write_grub_list($limits, $type, $uuid);
    $self->service_update_grub();
}

sub write_grub_list($$)
{
    my $self = instance(shift);
    my $limits = shift;
    my $type = shift;
    my $uuid = shift;


   my $template = Template->new ({
                           INCLUDE_PATH => $g->{'cfg_template_dir'},
                      });

   my $options = {
        limits => $limits,
        type => $type,
        uuid => $uuid,
    };

    my $config_content;
    $template->process($g->{'template_grub_menu_list'},$options,\$config_content)
      or throw Underground8::Exception($template->error);


    open (GRUBLIST, '>', $g->{'file_grub_menu_list'})
        or throw Underground8::Exception::FileOpen($g->{'file_grub_menu_list'});

    print GRUBLIST $config_content;

    close (GRUBLIST);

}

sub write_lsb_release ($)
{
    my $self = instance(shift);
    my $version = shift;
    
    my @lsb_release_file;
    open (LSB_RELEASE, '<', $g->{'file_lsb_release'})
        or throw Underground8::Exception::FileOpen($g->{'file_lsb_release'});

    my $marker = "DISTRIB_DESCRIPTION";
    
    while (my $line = <LSB_RELEASE>)
    {

        if ($line =~ m/^$marker/)
        {
            push (@lsb_release_file,"DISTRIB_DESCRIPTION=\"underground_8 AS $version\"");
        } else {
            push (@lsb_release_file,$line);
        }
    }

    close(LSB_RELEASE);

    open (LSB_RELEASE, '>', $g->{'file_lsb_release'})
        or throw Underground8::Exception::FileOpen($g->{'file_lsb_release'});

    while (my $line = shift(@lsb_release_file))
    {
        print LSB_RELEASE "$line";
    }

    close (LSB_RELEASE);



}


1;
