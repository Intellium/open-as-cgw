#!/usr/bin/perl -w
# This script is supposed to create Debian packages for the
# AS Communication Gateway, out of a full clone of the AS
# bzr repository.
# The packages created are:
#   * limesas (a meta package, just for versioning and dependencies)
#   * limesas-lib (core backend)
#   * limesas-gui (core frontend)
#
# Packages that need to be installed prior to calling this script are
#   - bzr
#   - dpkg & dpkg-dev

use strict;
use Data::Dumper;
use Tie::File;
use DateTime;
use Getopt::Long;
use Cwd qw(getcwd);
use File::Path qw(remove_tree mkpath);
use File::Copy::Recursive qw(dircopy fcopy rcopy);
use File::Copy qw(move);

my $BASE = getcwd;
if($BASE =~ /\/scripts$/) {
	&fatal(1,"Please call this script from the root directory of the bzr clone!");
}

my $INSTALLDIR = '/tmp';
my $DISTRIBUTION = "autodetect";
my $SUFFIX = "0";
my $LIBDIR = "lib";
my $GUIDIR = "gui";
my $VIRDIR = "meta";
my $BUILD_ENV = "devel";
my $BUILD_ENV_LIBDIR = $BUILD_ENV . "/" . "limesas-lib";
my $BUILD_ENV_GUIDIR = $BUILD_ENV . "/" . "limesas-gui";
my $BUILD_ENV_VIRDIR = $BUILD_ENV . "/" . "limesas";
my $SRC_DIR = "src";
my $NOCLEANUP = 0;
my $SIGN_FILES = 0;
my $rev = 0;


# Manual override via command-line arguments
GetOptions (
	'libdir=s'		=> \$LIBDIR,
	'guidir=s'		=> \$GUIDIR,
	'virdir=s'		=> \$VIRDIR,
	'installdir=s'	=> \$INSTALLDIR,
	'suffix=s'		=> \$SUFFIX,
	'distribution=s' => \$DISTRIBUTION,
	'nocleanup!'	=> \$NOCLEANUP,
	'signfiles!'	=> \$SIGN_FILES,
		);


print "Going to build with the following parameters:\n";
print "  LIBDIR = $LIBDIR, GUIDIR = $GUIDIR, VIRDIR = $VIRDIR\n";
print "  Installing final packages to <$INSTALLDIR>\n";
print "  Packaging with suffix <-$SUFFIX>, distribution <$DISTRIBUTION>\n";
print "  Signing packages: $SIGN_FILES\n\n"


print "Preparing code-base for package construction in <${BUILD_ENV}>\n";
print "  Cleaning directories ...\n";
remove_tree($BUILD_ENV);

print "  Creating directories ...\n";
my @dirs_needed_lib = qw/Underground8 Catalyst Data HTML bin cfg-templates xml xml_backup var modules drivers conf/;
my @dirs_needed_gui = qw/LimesGUI/;

mkpath "${BUILD_ENV}/${SRC_DIR}";
mkpath "${BUILD_ENV_VIRDIR}";
mkpath("${BUILD_ENV_LIBDIR}/$_") foreach(@dirs_needed_lib);
mkpath("${BUILD_ENV_GUIDIR}/$_") foreach(@dirs_needed_gui);


# Getting package-base from bzr #
print "  Retrieving revision ... ";
# my $REVISION = `git log --date=raw HEAD^..HEAD | egrep "^Date:" | awk '{ print \$2 }'`;	 # legacy for GIT repo
my $REVISION = `bzr log -r-1 | grep "revno" | awk '{ print \$2 }'`;
chomp($REVISION);
print "is $REVISION\n";

print "  Fetching debian package bases ...\n";
dircopy("${LIBDIR}/package-base", $BUILD_ENV_LIBDIR);
dircopy("${GUIDIR}/package-base", $BUILD_ENV_GUIDIR);
dircopy("${VIRDIR}", $BUILD_ENV_VIRDIR);

# Retrieve sources from bzr 
print "  Fetching necessary source trees ... \n";
dircopy("${LIBDIR}/lib", "${BUILD_ENV}/${SRC_DIR}/lib");
dircopy("${LIBDIR}/bin", "${BUILD_ENV}/${SRC_DIR}/bin");
dircopy("${LIBDIR}/etc", "${BUILD_ENV}/${SRC_DIR}/etc");
dircopy("${LIBDIR}/var", "${BUILD_ENV}/${SRC_DIR}/var");
dircopy("${LIBDIR}/ca-certificates", "${BUILD_ENV}/${SRC_DIR}/ca-certificates");
dircopy("${GUIDIR}", "${BUILD_ENV}/${SRC_DIR}/LimesGUI");


print "  Reading version information from Meta package and writing versions file ...\n";
my %versioninfo;
read_version("${BUILD_ENV_VIRDIR}/versions", \%versioninfo);
open (VERFILE, "> ${BUILD_ENV_VIRDIR}/versions");
print VERFILE "main=$versioninfo{'main'}\n";
print VERFILE "build=$versioninfo{'build'}\n";
print VERFILE "revision=$REVISION\n";
close VERFILE;


# Write debian changelog
print "  Writing debian changelog files for all packages ...\n";
&write_debian_changelog();


print "  Constructing correct package directory structure (this is hacky stuff) ...\n";
# ${TMP}/devel == ${BUILD_ENV}/${SRC_DIR}
# ${DSTLIB} == ${BUILD_ENV_LIBDIR}
# rename("${BUILD_ENV}/${SRC_DIR}/lib/set_cfg_permissions.pl", "${BUILD_ENV_LIBDIR}/bin/set_cfg_permissions.pl");
fcopy("${BUILD_ENV}/${SRC_DIR}/lib/set_cfg_permissions.pl", "${BUILD_ENV_LIBDIR}/bin/");
dircopy("${BUILD_ENV}/${SRC_DIR}/lib/Underground8", "${BUILD_ENV_LIBDIR}/Underground8");
dircopy("${BUILD_ENV}/${SRC_DIR}/lib/Catalyst", "${BUILD_ENV_LIBDIR}/Catalyst");
dircopy("${BUILD_ENV}/${SRC_DIR}/lib/Data", "${BUILD_ENV_LIBDIR}/Data");
dircopy("${BUILD_ENV}/${SRC_DIR}/lib/HTML", "${BUILD_ENV_LIBDIR}/HTML");
# fcopy("${BUILD_ENV}/${SRC_DIR}/bin/rtlogd.init", "${BUILD_ENV_LIBDIR}/debian/limesas-lib.rtlogd.init2");  #needed?
# system("mv ${TMP}/devel/bin/firewall ${DSTLIB}/debian/limesas-lib.firewall.init"); #needed?
# system("rm ${TMP}/devel/bin/launch");        # needed?
# system("rm ${TMP}/devel/bin/monit_rtlogd");  # needed?
# system("rm ${TMP}/devel/bin/host.pl");       # needed?
dircopy("${BUILD_ENV}/${SRC_DIR}/bin", "${BUILD_ENV_LIBDIR}/bin/");
dircopy("${BUILD_ENV}/${SRC_DIR}/lib/modules", "${BUILD_ENV_LIBDIR}/modules");
dircopy("${BUILD_ENV}/${SRC_DIR}/lib/drivers", "${BUILD_ENV_LIBDIR}/drivers");
dircopy("${BUILD_ENV}/${SRC_DIR}/var", "${BUILD_ENV_LIBDIR}/var") if(-d "${BUILD_ENV}/${SRC_DIR}/var/quarantine");
dircopy("${BUILD_ENV}/${SRC_DIR}/etc/cfg-templates", "${BUILD_ENV_LIBDIR}/cfg-templates");
dircopy("${BUILD_ENV}/${SRC_DIR}/etc/conf", "${BUILD_ENV_LIBDIR}/conf");
dircopy("${BUILD_ENV}/${SRC_DIR}/etc/xml_backup", "${BUILD_ENV_LIBDIR}/xml_backup");
dircopy("${BUILD_ENV}/${SRC_DIR}/ca-certificates", "${BUILD_ENV_LIBDIR}/ca-certificates");
dircopy("${BUILD_ENV}/${SRC_DIR}/LimesGUI", "${BUILD_ENV_GUIDIR}");

print "  Writing avail_secversion file ...\n";
system "echo $versioninfo{'main'} > ${BUILD_ENV_LIBDIR}/avail_secversion";

# prepare GUI
# system("rm -r ${TMP}/devel/LimesGUI/script/limesgui_cgi.pl");    # needed?
# system("rm -r ${TMP}/devel/LimesGUI/script/limesgui_create.pl"); # needed?
# system("rm -r ${TMP}/devel/LimesGUI/script/limesgui_test.pl");   # needed?
# system("rm ${TMP}/devel/LimesGUI/README");                       # needed?

# changing all those things that need to be changed in development version...
print "  Doing some bitchy, nasty regex substitutions in source files ...\n";
open(UTILS,"${BUILD_ENV_LIBDIR}/Underground8/Utils.pm");
my $tmp = join('', <UTILS>);
close(UTILS);
$tmp =~ s/\(getpwuid\(\$\<\)\)\[7\]/\"\/etc\/limes\"/g;
$tmp =~ s/\/devel\/limesgui\/trunk\/limes\-as//g;
$tmp =~ s/\$homedir\/bin\//\/usr\/local\/bin\//g;
$tmp =~ s/eth1/eth0/g;
$tmp =~ s/eth2/eth0/g;
$tmp =~ s/eth3/eth0/g;
$tmp =~ s/\$homedir\/backup/\/var\/limes\/backup/g;
open(UTILS,">${BUILD_ENV_LIBDIR}/Underground8/Utils.pm");
print UTILS $tmp;
close UTILS;

my $type = "stable";
my $ticket = "0";
open(USUS,"${BUILD_ENV_LIBDIR}/cfg-templates/usus/usus.conf.tt2");
$tmp = join('', <USUS>);
close(USUS);

if ( $versioninfo{'main'} =~ m/\d+?\.\d+?\.\d+?([a|b|s])/ ) {
    $type = "devel" if ( $1 eq "a" );
    $type = "beta" if ( $1 eq "b" );
}

if ( $SUFFIX ne "0" ) {
    $ticket = $DISTRIBUTION;
}

$tmp =~ s/\ devel/\ $type/g;
$tmp =~ s/\ 0/\ $ticket/g;

open(USUS,">${BUILD_ENV_LIBDIR}/cfg-templates/usus/usus.conf.tt2");
print USUS $tmp;
close(USUS);

open(LIMESAS,"${BUILD_ENV_GUIDIR}/lib/LimesGUI.pm") or die "open()";
$tmp = join('', <LIMESAS>);
close(LIMESAS);
$tmp =~ s/\$homedir\/devel\/limesas\/lib\/trunk\/etc/\/etc\/limes/g;
$tmp =~ s/\$homedir\/devel\/limesas\/LimesGUI\/trunk\/session_store/\/var\/www\/LimesGUI\/session_store/g;
$tmp =~ s/\-Debug//g;
$tmp =~ s/\(getpwuid\(\$\<\)\)\[7\]/\"\/var\/www\"/g;
$tmp =~ s/\/devel\/limesgui\/trunk\/limes-as\//\//g;
$tmp =~ s/\#\$appliance\-\>commit/\$appliance\-\>commit/g;
open(LIMESAS,">${BUILD_ENV_GUIDIR}/lib/LimesGUI.pm") or die "open()";
print LIMESAS $tmp;
close LIMESAS;


#print "  The following error is completly OK ;) :\n";
dircopy("${BUILD_ENV_GUIDIR}", "/tmp/LimesGUI");
dircopy("/tmp/LimesGUI", "${BUILD_ENV_GUIDIR}/LimesGUI");
#dircopy("${BUILD_ENV_GUIDIR}", "${BUILD_ENV_GUIDIR}/LimesGUI");


# print "mv ${TMP}/limesas-lib/* ${DSTLIB}";
# system("rm -r ${DSTLIB}/xml_backup/*");
# remove_tree("${BUILD_ENV_LIBDIR}/xml_backup");

## already done?
#system("mv ${TMP}/limesas-lib/* ${DSTLIB}");
#system("mv ${TMP}/limesas-gui/* ${DSTGUI}");



if ( $DISTRIBUTION eq "autodetect" ) {
	if ( $versioninfo{'main'} !~ m/^(\d+?\.\d+?)/ ) {
			print "Something went terribly wrong, exiting.\n";
			exit 1;
		}

		$DISTRIBUTION = $1;
	}

&create_debs($rev, $DISTRIBUTION, $BASE);


1;

sub read_version {
	my $file = shift;
	my $hash = shift;
	my ($key, $val);
	open (SETS, $file) or die;
	while (<SETS>) {
		chop;
		($key, $val) = split (/=/, $_, 2);
		if (defined $key && length $key) {
			$val =~ s/^\'//g;
			$val =~ s/\'$//g;
			$key =~ /([A-Z-a-z0-9_-]*)/;
			$key = $1;
			$val =~ /([\W\w]*)/;
			$val = $1;
			$hash->{$key} = $val;
		}
	}
	close SETS;
}

sub create_debs ($$$) {
	my $rev = shift;
	my $distribution = shift;
	my $base = shift;

	print "\nCreating Debian packages\n";

	print "  Cleaning previously created stuff ...\n";
	my @trash = ();
	push(@trash, glob("${BASE}/${BUILD_ENV}/limesas*.deb"));
	push(@trash, glob("${BASE}/${BUILD_ENV}/limesas*.changes"));
	push(@trash, glob("${BASE}/${BUILD_ENV}/limesas*.dsc"));
	push(@trash, glob("${BASE}/${BUILD_ENV}/limesas*.tar.gz"));
	unlink $_ foreach (@trash);

	print "  Building meta package ... ";
	chdir("${BASE}/${BUILD_ENV_VIRDIR}");

	($SIGN_FILES == 0)
		? system("dpkg-buildpackage -rfakeroot -d -us -uc > /dev/null 2>&1")
		: system("dpkg-buildpackage -rfakeroot -S -d -k22E1D6FD > /dev/null 2>&1");
	fatal(1, "failed to build limesas meta") if $? != 0;
	print "OK\n";

	print "  Building lib package ... ";
	chdir("${BASE}/${BUILD_ENV_LIBDIR}");
	($SIGN_FILES == 0)
		? system("dpkg-buildpackage -rfakeroot -d -us -uc > /dev/null 2>&1")
		: system("dpkg-buildpackage -rfakeroot -S -d -k22E1D6FD > /dev/null 2>&1");
	fatal(1, "failed to build limesas-lib") if $? != 0;
	print "OK\n";

	print "  Building gui package ... ";
	chdir("${BASE}/${BUILD_ENV_GUIDIR}");

	($SIGN_FILES == 0)
		? system("dpkg-buildpackage -rfakeroot -d -us -uc > /dev/null 2>&1")
		: system("dpkg-buildpackage -rfakeroot -S -d -k22E1D6FD > /dev/null 2>&1");
	fatal(1, "failed to build limesas-gui") if $? != 0;
	print "OK\n";

	if($NOCLEANUP == 0) {
		print "  Removing legacy Debian packages from destination directory ...\n";
		@trash = ();
		push(@trash, glob("${INSTALLDIR}/limesas*.deb"));
		unlink $_ foreach (@trash);

		print "  Removing temporary build source-trees ...\n";
		remove_tree(${BUILD_ENV});
	}

	my @final_packages = glob("${BASE}/${BUILD_ENV}/*.deb");
	fcopy($_, "${INSTALLDIR}") foreach (@final_packages);
}

sub fatal($$){
	my $exitcode = shift;
	my $msg = shift;

	print STDERR "\nFatal: $msg\n";
	exit $exitcode;
}

sub write_debian_changelog {
	my $dt = DateTime->now;
	my ($year, $month, $day, $wday, $hms) =
		($dt->year, $dt->month_abbr, $dt->day, $dt->day_abbr, $dt->hms);

	my $package_version = ($SUFFIX ne "0")
		? "$versioninfo{'main'}-${REVISION}~1${SUFFIX}1"
		: "$versioninfo{'main'}-${REVISION}";


	tie my @changelog, "Tie::File", "${BUILD_ENV_LIBDIR}/debian/changelog";
	unshift @changelog, " -- Erik Sonnleitner <es\@delta-xi.net>  $wday,  $day $month $year $hms +0100\n\n";
	unshift @changelog, "  * Automatically created entry.\n\n";
	unshift @changelog, "limesas-lib ($package_version) lucid; urgency=low\n\n";

	tie @changelog, "Tie::File", "${BUILD_ENV_GUIDIR}/debian/changelog";
	unshift @changelog, " -- Erik Sonnleitner <es\@delta-xi.net>  $wday,  $day $month $year $hms +0100\n\n";
	unshift @changelog, "  * Automatically created entry.\n\n";
	unshift @changelog, "limesas-gui ($package_version) lucid; urgency=low\n\n";

	tie @changelog, "Tie::File", "${BUILD_ENV_VIRDIR}/debian/changelog";
	unshift @changelog, " -- Erik Sonnleitner <es\@delta-xi.net>  $wday,  $day $month $year $hms +0100\n\n";
	unshift @changelog, "  * Automatically created entry.\n\n";
	unshift @changelog, "limesas ($package_version) lucid; urgency=low\n\n";
}
