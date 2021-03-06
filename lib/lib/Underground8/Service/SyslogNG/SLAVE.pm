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


package Underground8::Service::SyslogNG::SLAVE;
use base Underground8::Service::SLAVE;

use strict;
use warnings;
use Error;
use Underground8::Utils;
use Underground8::Exception;
use Underground8::Exception::FileOpen;
use Template;
use Data::Dumper;


sub new ($)
{
    my $class = shift;
    my $self = $class->SUPER::new('syslogng');
    return $self;
}

sub service_stop($)
{
    my $self = instance(shift);
    
    my $output = safe_system($g->{'cmd_syslogng_stop'});
}

sub service_start($)
{
    my $self = instance(shift);
    
    my $output = safe_system($g->{'cmd_syslogng_start'});
}

sub service_restart($)
{
    my $self = instance(shift);
    
    my $output = safe_system($g->{'cmd_syslogng_restart'});
}


sub write_config($$$$$)
{
    my $self = instance(shift);
   
    my $memory_factor = $self->memory_factor;
    my $enabled = shift;
    my $host = shift;
    my $port = shift;
    my $proto = shift;


    #
    # write syslog-ng config file
    # 
    my $template = Template->new (
	{
	    INCLUDE_PATH => $g->{'cfg_template_dir'},
	});  
    
    my $options = {
	    info => 'autogenerated by LimesAS',
        memory_factor => $memory_factor,
        server_enabled => $enabled,
        server => $host,
        port => $port,
        proto => $proto,
    };

   
    my $config_content;
    $template->process($g->{'template_syslogng'},$options,\$config_content) 
        or throw Underground8::Exception($template->error);

    open (SYSLOGNGCONF,'>',$g->{'file_syslogng'})
        or throw Underground8::Exception::FileOpen($g->{'file_syslogng'});

    print SYSLOGNGCONF $config_content;

    close (SYSLOGNGCONF);


    #
    # write logrotate template
    #

    undef $template;
    undef $options;
    undef $config_content;

    $template = Template->new (
    {
        INCLUDE_PATH => $g->{'cfg_template_dir'},
    });

    $options = {
        info => 'autogenerated by LimesAS',
        memory_factor => $memory_factor,
    };

    $template->process($g->{'template_syslogng_logrotate'},$options,\$config_content)
        or throw Underground8::Exception($template->error);

    open (SYSLOGNGLOGROTATECONF,'>',$g->{'file_syslogng_logrotate'})
        or throw Underground8::Exception::FileOpen($g->{'file_syslogng_logrotate'});

    print SYSLOGNGLOGROTATECONF $config_content;

    close (SYSLOGNGLOGROTATECONF);

}



1;
