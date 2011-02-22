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


my $guipath;
my $libpath;

BEGIN { 
    $ENV{CATALYST_ENGINE} ||= 'HTTP';
    $ENV{CATALYST_SCRIPT_GEN} = 30;
    require Catalyst::Engine::HTTP;


    my $libpath = $ENV{'LIMESLIB'};
    my $guipath = $ENV{'LIMESGUI'};

    unless ($guipath && $libpath)
    {
        print "ERROR: Necessary path information missing. (Did you define LIMESLIB and LIMESGUI in ENV?)\n";
        exit(0);
    }

    print "Using lib-path: $libpath\nUsing gui-path: $guipath\n";

    unshift(@INC,"$libpath/lib/");
}  

use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use FindBin;
use lib "$FindBin::Bin/../lib";

my $debug             = 0;
my $fork              = 0;
my $help              = 0;
my $host              = undef;
my $port              = 3000;
my $keepalive         = 0;
my $restart           = 0;
my $restart_delay     = 1;
my $restart_regex     = '\.yml$|\.yaml$|\.pm$';
my $restart_directory = undef;

my @argv = @ARGV;

GetOptions(
    'debug|d'             => \$debug,
    'fork'                => \$fork,
    'help|?'              => \$help,
    'host=s'              => \$host,
    'port=s'              => \$port,
    'keepalive|k'         => \$keepalive,
    'restart|r'           => \$restart,
    'restartdelay|rd=s'   => \$restart_delay,
    'restartregex|rr=s'   => \$restart_regex,
    'restartdirectory=s'  => \$restart_directory,
);

pod2usage(1) if $help;

if ( $restart ) {
    $ENV{CATALYST_ENGINE} = 'HTTP::Restarter';
}
if ( $debug ) {
    $ENV{CATALYST_DEBUG} = 1;
}

# This is require instead of use so that the above environment
# variables can be set at runtime.
require LimesGUI;

LimesGUI->run( $port, $host, {
    argv              => \@argv,
    'fork'            => $fork,
    keepalive         => $keepalive,
    restart           => $restart,
    restart_delay     => $restart_delay,
    restart_regex     => qr/$restart_regex/,
    restart_directory => $restart_directory,
} );

LimesGUI->config->{'guipath'} = $guipath;
LimesGUI->config->{'libpath'} = $libpath;

1;

=head1 NAME

limesgui_server.pl - Catalyst Testserver

=head1 SYNOPSIS

limesgui_server.pl [options]

 Options:
   -d -debug          force debug mode
   -f -fork           handle each request in a new process
                      (defaults to false)
   -? -help           display this help and exits
      -host           host (defaults to all)
   -p -port           port (defaults to 3000)
   -k -keepalive      enable keep-alive connections
   -r -restart        restart when files get modified
                      (defaults to false)
   -rd -restartdelay  delay between file checks
   -rr -restartregex  regex match files that trigger
                      a restart when modified
                      (defaults to '\.yml$|\.yaml$|\.pm$')
   -restartdirectory  the directory to search for
                      modified files
                      (defaults to '../')

 See also:
   perldoc Catalyst::Manual
   perldoc Catalyst::Manual::Intro

=head1 DESCRIPTION

Run a Catalyst Testserver for this application.

=head1 AUTHOR

Sebastian Riedel, C<sri@oook.de>
Maintained by the Catalyst Core Team.

=head1 COPYRIGHT

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
