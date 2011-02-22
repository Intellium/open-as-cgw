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
# daemon.pl - daemon that interacts with a kernel character-device via cat
# to check for factory-default button presses by using the polling-mechanism
#
# 07/22/2008 - Updated by Andreas Starlinger <as@dcon.at>
#

use strict;
use POSIX qw(setsid);
use Sys::Syslog qw( :DEFAULT setlogsock);

# change the full-path location of the configuration file here
my $configLocation = "/etc/limes/conf/factory_defaults.conf";
my $result = 0;
my $subResult = 0;
my $returnCode = 0;
my $user = $ENV{'USER'};

sub parse_config;
sub daemonize;
sub log_message;

# daemonize
&daemonize;

# get configs
my %configHash = %{parse_config($configLocation)};
my $count = keys %configHash; 

my $charDeviceFile = $configHash{"charDeviceFile"};
my $pollingInterval = $configHash{"pollingInterval"};
my $resetScript = $configHash{"resetScript"};

# all configuration parameters must be set
if (!$charDeviceFile || !$pollingInterval || !$resetScript) {
	log_message('info', "Configuration parameters not complete");
	die "Check syslog for details";
}

# infinite loop
while(1) {
	
	# execute cat at kernel char-device
	$result = `cat $charDeviceFile`;

	# char-device returns 1 in case of factory-default button was pressed 
	if ($result == "1") {
		log_message('info', "Factory-Default button pressed");
		# execute subscript in case button was pressed
		$subResult = `$resetScript`;
		$returnCode = $?;
		if ($returnCode != 0) {
			log_message('info', "Error on executing resetScript: result was $returnCode - $!");
			die "Check syslog for details";
		}
	}

	# wait for x seconds
	sleep($pollingInterval);
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

sub log_message {
	my ($priority, $msg) = @_; 
	return 0 unless ($priority =~ /info|err|debug/);
	setlogsock('unix');
	openlog($0, 'pid,cons', 'user');
	syslog($priority, $msg);
	closelog();
	return 1;
}

sub writePIDFile {
    my $recParamsSize = @_;
    if ($recParamsSize == 0)
    {
        die ("Wrong parameters qty writePIDFile\n");
    }
    open(PIDFILE, "> /var/run/factory_defaults.pl.pid") || die ("Couldn't write to PID file\n");
    print(PIDFILE "$_[0]");
    close(PIDFILE);
}

