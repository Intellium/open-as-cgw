#!/usr/bin/perl -w
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


# 
# lcd_menu.pl - a server menu client for LCDproc
# 
# Offers the possibility to execute a factory default
# script by utilizing the screen buttons.
#
# Updated 08/08/2008 by <as@dcon.at>
#
# Raw Version Copyright GPL  2005, Guido Socher
#

use IO::Socket;
use Getopt::Std;
use Fcntl;
use strict;
use vars qw($opt_h);
use POSIX qw(setsid);

sub parse_config;
sub daemonize;

# set variables
my $rin='';
my $timeout=2; # seconds
my $timeleft;
my $rout;
my $nfound;
my $str1; # 2 line display, line 1
my $str2; # 2 line display, line 2
my $keyenter=0;
my $keyup=0;
my $keydown=0;
my $keyescape=0;
my $factorydefaultmenustate=0;
my $lastkeyup=0;
my $lastkeydown=0;
my $lastkeyenter=0;
my $lastkeyescape=0;
my $defaulttimeout=30;

my $configLocation = "/etc/limes/conf/factory_defaults.conf";
my %configHash = %{parse_config($configLocation)};
my $resetScript = $configHash{"resetScript"};
my $user = $ENV{'USER'};

# daemonize
&daemonize;

my $remote = IO::Socket::INET->new(
    Proto     => "tcp",
    PeerAddr  => "localhost",  # this machine, 127.0.0.1
    PeerPort  => 13666
    ) || die "Cannot connect to LCDd\n";

if ($> > 0){
    print "Warning: factory default will not work if you do not start this script as root\n";
}

# Make sure our messages get there right away
$remote->autoflush(1);
sleep 1;	# Give server time to notice us...

# initialize
print $remote "hello\n";

# you must always read the answer from LCDd even if you do not need it
# otherwise select will not work as expected:
my $lcdresponse = <$remote>;

# Set up some screen widgets...
print $remote "client_set name lcd_menu\n";
$lcdresponse = <$remote>; # read and ignore response
print $remote "screen_add scr1\n";
$lcdresponse = <$remote>; # read and ignore response
print $remote "screen_set scr1 -heartbeat off\n";
$lcdresponse = <$remote>; # read and ignore response
print $remote "widget_add scr1 str1 string\n";
$lcdresponse = <$remote>; # read and ignore response
print $remote "widget_add scr1 str2 string\n";
$lcdresponse = <$remote>; # read and ignore response
print $remote "client_add_key Enter\n";
$lcdresponse = <$remote>; # read and ignore response
print $remote "client_add_key Up\n";
$lcdresponse = <$remote>; # read and ignore response
print $remote "client_add_key Down\n";
$lcdresponse = <$remote>; # read and ignore response
print $remote "client_add_key Escape\n";
$lcdresponse = <$remote>; # read and ignore response

$SIG{ALRM}=sub { $factorydefaultmenustate=0; };

# starting main loop
while(1)
{

    vec($rin,fileno($remote),1)=1;
    ($nfound,$timeleft) = select($rout=$rin, undef, undef, $timeout);

    if ($nfound){
        # data is available
        $lcdresponse = <$remote>;
        $keyenter=0;
        $keyescape=0;
        $keyup=0;
        $keydown=0;
        $keyenter=1 if ($lcdresponse && $lcdresponse=~/key Enter/);
        $keyup=1 if ($lcdresponse && $lcdresponse=~/key Up/);
        $keydown=1 if ($lcdresponse && $lcdresponse=~/key Down/);
        $keyescape=1 if ($lcdresponse && $lcdresponse=~/key Escape/);
	
        if ($keyup == 1 && $lastkeyup == 1)
        {
            next;
        }
        if ($keydown == 1 && $lastkeydown == 1)
        {
            next;
        }
        if ($keyenter == 1 && $lastkeyenter == 1)
        {
            next;
        }
        if ($keyescape == 1 && $lastkeyescape == 1)
        {
            next;
        }       
 
        $lastkeyup=0;
        $lastkeydown=0; 
        $lastkeyenter=0;
        $lastkeyescape=0; 
    }

    # the up or down key was pressed once, show factory default menu:
    if (($keyup || $keydown) && $factorydefaultmenustate==0)
    {
        $factorydefaultmenustate=1;
        $str1="Factory Default?";
        $str2="                ";
        if ($keyup == 1)
        {
           $lastkeyup=1; 
        }	
        else 
        {
           $lastkeydown=1;
        } 
        $keyup=0;
        $keydown=0;
        alarm($defaulttimeout);
    } 

    # we are in factory default visible state and enter was pressed, show the first warning message
    elsif ($keyenter && $factorydefaultmenustate==1)
    {
        $factorydefaultmenustate=2;
        $str1="Are you sure?   ";
        $str2="                ";
        $lastkeyenter=1; 
        $keyenter=0;
        alarm($defaulttimeout);
    }

    # we are in first warning message visible state and enter was pressed, show the second warning message
    elsif ($keyenter && $factorydefaultmenustate==2)
    {
        $factorydefaultmenustate=3;
        $str1="Are you really  ";
        $str2="sure?           ";
        $lastkeyenter=1; 
        $keyenter=0;
        alarm($defaulttimeout);
    }

    # we are in second warning message visible state and enter was pressed, start the script
    elsif ($keyenter && $factorydefaultmenustate==3)
    {
        $factorydefaultmenustate=4;
        $str1="Resetting...    ";
        $str2="                ";
        $lastkeyenter=1; 
        $keyenter=0;
        alarm($defaulttimeout);
    }

    elsif ($keyescape==1)
    {
        $factorydefaultmenustate=0;
        $keyescape=0;
        $lastkeyescape=1; 
    }

    elsif ($factorydefaultmenustate==0)
    {
        # no factory default menu, show empty text
        $str1="underground_8    ";
        $str2="secure computing";
    }

    # bring everything to the screen
    print $remote "widget_set scr1 str1 1 1 \"$str1\"\n";
    $lcdresponse = <$remote>; # read and ignore response
    print $remote "widget_set scr1 str2 1 2 \"$str2\"\n";
    $lcdresponse = <$remote>; # read and ignore response

    if ($factorydefaultmenustate==4)
    {
       system($resetScript);
       $factorydefaultmenustate=0; 
    } 

    sleep(1);

}

# parse the config file
sub parse_config($)
{
	my $file = shift;
	local *CF;

	open(CF,'<'.$file) or die "Open $file: $!";
	read(CF, my $data, -s $file);
	close(CF);

	my @lines  = split(/\015\012|\012|\015/,$data);
	my $config = {};
	my $count  = 0;

	foreach my $line(@lines)
	{
		$count++;

		next if($line =~ /^\s*#/);
		next if($line !~ /^\s*\S+\s*=.*$/);

		my ($key,$value) = split(/=/,$line,2);

		# Remove whitespaces at the beginning and at the end

		$key   =~ s/^\s+//g;
		$key   =~ s/\s+$//g;
		$value =~ s/^\s+//g;
		$value =~ s/\s+$//g;

		die "Configuration option '$key' defined twice in line $count of configuration file '$file'" if($config->{$key});

		$config->{$key} = $value;
	}

	return $config;

}

# daemonize the script
sub daemonize {
    chdir '/' or die "Can't chdir to /: $!";
    open STDIN, '/dev/null' or die "Can't read /dev/null: $!";
    open STDOUT, '>>/dev/null' or die "Can't write to /dev/null: $!";
    open STDERR, '>>/dev/null' or die "Can't write to /dev/null: $!";
    defined(my $pid = fork) or die "Can't fork: $!";
    exit if $pid;
    writePIDFile($$);
    setsid or die "Can't start a new session: $!";
    umask 0;
}

sub writePIDFile {
    my $recParamsSize = @_;
    if ($recParamsSize == 0)
    {
        die ("Wrong parameters qty writePIDFile\n");
    }
    open(PIDFILE, "> /var/run/lcd_menu.pl.pid") || die ("Couldn't write to PID file\n");
    print(PIDFILE "$_[0]");
    close(PIDFILE);
}

