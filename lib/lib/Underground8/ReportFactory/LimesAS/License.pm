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


package Underground8::ReportFactory::LimesAS::License;
use base Underground8::ReportFactory;

use strict;
use warnings;

use Underground8::Report::LimesAS::License;
use Underground8::Utils;
use Error qw(:try);
use Underground8::Exception;
use Underground8::Exception::LicenseWrongSN;
use Underground8::Exception::XMLRPCError;

use DBI;
use Time::HiRes qw(gettimeofday tv_interval);
use Data::Dumper;

use Crypt::OpenSSL::RSA;
use Time::Local;
use Date::Calc qw(Delta_Days Delta_YMD);
use File::Temp qw(tempfile tempdir);





our $DEBUG = 0;

# Constructor
sub new ($)
{
    my $class = shift;

    my $self = $class->SUPER::new();

    bless $self, $class;
    return $self;
}

sub license_info
{
    my $self = shift;
    my $info;

    try
    {
        $info = $self->read_license_file();
    } catch Underground8::Exception with {
        my $E = shift;
    } catch Error with {
        my $E = shift;
    };


    my $report = new Underground8::Report::LimesAS::License;
    
    # We only care about info we KNOW, so here is what we do - ignore the rest
    foreach my $key (keys %{$report})
    {
        if (defined $info->{$key})
        {
            
            $report->{$key} = $info->{$key};
            #print STDERR "Report $key -> $info->{$key}\n";
        }
    }

    
    # We have the information we want - lets get a few extras here
    my @date = localtime();
    my $current_year = $date[5] + 1900;
    my $current_mon = $date[4]+1;
    my $current_day = $date[3];
    my $licences = avail_lic_services();

    foreach my $service (@{$licences})
    {
        #print STDERR "\nEvaluating $service\n";
        my $date = $report->{$service};
        #print STDERR "date for $service is $date\n";
        $report->{$service} = {};

        if ( !(defined $date) or $date eq "0000-00-00" )
        {
            $date = "1970-01-01";
        }
        $report->{$service}->{'valid_until'} = $date;
        $date =~ m/(\d+)-(\d+)-(\d+)/;
            my $valid_year = $1;
            my $valid_mon = $2;
            my $valid_day = $3;
        
        my $day_difference = Delta_Days($current_year,$current_mon,$current_day,$valid_year,$valid_mon,$valid_day);

        # warn level 1 => soon to expire, warn level 2 => has already expired
        $report->{$service}->{'warn_level'} = 0;

        if ($day_difference >= 0)
        {
            $report->{$service}->{'valid_for_days'} = $day_difference;
            $report->{$service}->{'active'} = 1;
            if ($day_difference <= 7)
            {
                $report->{$service}->{'warn_level'} = 1;
            }
        } else {
            $report->{$service}->{'valid_for_days'} = 0;
            $report->{$service}->{'active'} = 0;
            if ($day_difference >= -7)
            {
                $report->{$service}->{'warn_level'} = 2;
            }
           
        }
   
    }


    return $report;
}


sub read_license_file ($$)
{
    my $self = shift;
    my $file = shift;
    if (!defined $file)
    {
        $file = $g->{'file_license_ulf'}
    }

    my $return = {};

    # Starting with the try ... we need to catch the exceptions!
   
    # Read RSA public key and load into RSA object.
    open( PUBLIC_KEY, '<'.$g->{'file_license_key'} ) or throw Underground8::Exception::FileOpen($g->{'file_license_key'});
    my $key_string = do { local $/; <PUBLIC_KEY> };
    close( PUBLIC_KEY );
    my $rsa = Crypt::OpenSSL::RSA->new_public_key( $key_string );
    $rsa->use_pkcs1_padding();
    my $block_size = $rsa->size();

    open( LICENSE_FILE, "<", $file ) or throw Underground8::Exception::FileOpen($g->{'file_license_key'});
    binmode( LICENSE_FILE );
    my $cipher, my $blocks;
    sysread( LICENSE_FILE, $blocks, 4 );
    $blocks = unpack( 'N', $blocks );
        

    my $plaintext = '';
    
    for( my $i = 0; $i < $blocks; $i++ ) {
        sysread( LICENSE_FILE, $cipher, $block_size );
        $plaintext .= $rsa->public_decrypt( $cipher );
    }
    close( LICENSE_FILE );


    #print STDERR "-------- PLAIN TEXT\n$plaintext\n-------- PLAIN TEXT\n\n\n";

    # Now checking if what we got is in fact a license file
    # parsing the file here to get the first line
    my @lines = split(/[\n\r\l]+/,$plaintext);
    my $info;
    foreach my $line (@lines) {
        chomp($line);
        if ($line =~ m/(\w+?):\s+(.+)/) {
            $info->{$1} = $2;
        }
    }

    my $sn = read_sn();
    if ($info->{'serial'} ne $sn) {
        throw Underground8::Exception::LicenseWrongSN([$info->{'serial'},$info->{'appliance_family'}]);
    }

    return $info;
}


sub create_xml
{
    my $self = shift;
    my $serial = read_sn();
    my $voucher = shift; # optional

    my $name = $g->{'license_xmlrpc_user'};
    my $password = $g->{'license_xmlrpc_passhash'};

    my $XML = XML::Smart->new();
    $XML->{voucher} = "";
    if (defined $voucher)
    {
        $XML->{voucher}->set_node(
                        'auth' => 1,
                        'serial' => 1,
                        'code' => 1,
                );
    } else {
        $XML->{voucher}->set_node(
                        'auth' => 1,
                        'serial' => 1,
                );
    }
    $XML->{voucher}{auth} = "";
    $XML->{voucher}{auth}->set_node(
                           'password' => 1,
                           'name' => 1,
            );
    $XML->{voucher}{auth}{name}{CONTENT} = $name;
    $XML->{voucher}{auth}{password}{CONTENT} = $password;
    $XML->{voucher}{serial}{CONTENT} = $serial;
    if (defined $voucher)
    {
       $XML->{voucher}{code}{CONTENT} = $voucher;
    }

    return $XML;
}

sub get_license_file
{
    my $self = shift;
    my $XML = shift;

    my $license_url = $g->{'license_xmlrpc_serverurl'};
    my $license_voucherpath = $g->{'license_xmlrpc_voucherpath'};

    my $ua = LWP::UserAgent->new();
    $ua->protocols_allowed(['https']);
    $ua->timeout(60);

    my $request = HTTP::Request->new(POST => "$license_url/$license_voucherpath");
    $request->content($XML->data);


    # CLIM Return Codes --- put that in the Exception to give info
    # 400 => 'clim_malformed_xml',
    # 403 => 'clim_auth_failed',
    # 409 => 'clim_conflict',
    # 500 => 'clim_unknown_error',
    # 999 => 'clim_unreachable',
    #
    
    my $response = $ua->request($request);
    if ($response->is_error())
    {
        print STDERR "DEBUG: ".$response->status_line."\n";

        if ($response->status_line =~ /^500\s+Can't\s+connect\s+to/)
        {
            #print STDERR "Error code 500, can't connect\n\n";
            throw Underground8::Exception::XMLRPCError("999");
        }
            elsif ($response->status_line =~ /^(\d+)\s+/)
        {
            throw Underground8::Exception::XMLRPCError($1);
        }
            else
        {
            throw Underground8::Exception::XMLRPCError("500");
        }
    } else {
        # Check if the license file is valid here
        # If it is --- copy over current
        # This could be an additional function, that also checks the sign dates of the two files
        (my $temp_lic_fh, my $temp_lic_name) = tempfile(DIR => "/tmp",
                                                        TEMPLATE => "tmp_lic_XXXXXX",
                                                        SUFFIX => ".ulf",
                                                        );

        print $temp_lic_fh $response->content;

        return $temp_lic_name;
    }
        return 0;
}


sub service_status($$)
{
    my $self = shift;
    my $service = shift;
    my $license_report = $self->license_info();
    
    if(defined $license_report->{$service})
    {
        return $license_report->{$service}->{'active'};
    } else {
        return 0;
    }
}


#sub read_sn
#{
#    my $sn = '';
#    if (open SN, ("<" . $g->{'cfg_sn_file'}))
#    {
#        $sn = <SN>;
#        chomp($sn);
#        close SN;
#    }
#    return $sn;
#}

sub renew_licence_warning
{
    my $self = shift;
    my $system_warn_level = 0;
    my $services_expiring = 0;
    my $services_expired = 0;
    my $report = $self->license_info();
    my $licences = avail_lic_services();
    
    foreach my $service (@{$licences})
    {
        if ( $report->{$service}->{'warn_level'} == 1 )
        {
            $services_expiring += 1;
        } elsif ($report->{$service}->{'warn_level'} == 2) {
            $services_expired += 1;
        }
    }
    
    if ($services_expiring > 0)
    {
        $system_warn_level = 1;
    } elsif ($services_expired > 0) {
        $system_warn_level = 2;
    }
    
    return $system_warn_level;
}


sub virtual_restrictions ($$)
{
    my $self = shift;
    my $appendix = shift;
    my $limits = {};
    $limits->{'ram'} = 0;
    $limits->{'cpus'} = 0;
    
    open( RESTRICTIONFILE, '<'.$g->{'file_virtual_restrictions'} ) or throw Underground8::Exception::FileOpen($g->{'file_virtual_restrictions'});

    #print STDERR "Searching for restrictions for appendix $appendix in file $g->{'file_virtual_restrictions'}";
    foreach my $line (<RESTRICTIONFILE>)
    {
        chomp $line;
        #print STDERR "$line\n";
        if ($line =~ m/^#/)
        {
            # We have a comment ... ignore
        } else {
            # lets parse the line further... ;)
            if ($line =~ m/^$appendix\=(\d+?),(\d+?)/)
            {
                # We have our restrictions ... get them to the object and break the loop
                
                $limits->{'ram'} = $1;
                $limits->{'cpus'} = $2;
                last;
            }
        }
    }

    close( RESTRICTIONFILE );

    return $limits;

}

# META Licence subs ... to be used for EVERYTHING that may or may not run
# ALWAYS return 0 or 1
# Can be used for
## Time decisions (free until ...)
## Serial Number decisions (Hardware serials before a certain week?
## Serial Type decisions (Hardware, Virtual, ...)
## Serial Granular Type decisions (H/V - exact Type (AS300 ASV500, ...)
## Last but not least - one and/or more actual licences
#
# AGAIN - DO NOT FORGET TO RETURN 0 OR 1!

sub meta_lic_usegui
{
    my $self = instance(shift);
    my $return = 0;
    
    my $serial_info = serial_info();
    # my $licence_info = $self->license_info();
    #i $licence_info->{$service}->{'active'}
    
    $return = 1 if ($serial_info->{'type'} eq "H");
    $return = 1 if ($serial_info->{'type'} eq "V");
    
    return $return;
}


sub meta_lic_use25
{
    my $self = instance(shift);
    my $return = 0;

    my $serial_info = serial_info();
    $return = 1 if ($serial_info->{'type'} eq "H");
    $return = 1 if ($self->service_status("virtual_use"));

    return $return;
}



#sub meta_lic_usekav
#{
#    my $self = instance(shift);
#    my $return = 0;
#
#    my $serial_info = serial_info();
#    $return = 1 if ($self->service_status("up2date"));
#    $return = 1 if ($self->service_status("virtual_use"));
#
#    return $return;
#}

sub meta_lic_useavira
{
    my $self = instance(shift);
    my $return = 0;

    my $serial_info = serial_info();
    $return = 1 if ($self->service_status("up2date"));
    $return = 1 if ($self->service_status("virtual_use"));

    return $return;
}

sub meta_lic_secupdate
{
    my $self = instance(shift);
    my $return = 1;
    
    return $return;
}


sub meta_lic_featureupdate
{
    my $self = instance(shift);
    my $return = 0;

    my $serial_info = serial_info();
    $return = 1 if ($self->service_status("up2date"));
    $return = 1 if ($self->service_status("virtual_use"));

    return $return;
}



sub meta_lic_mailcrypt
{
    my $self = instance(shift);
    my $return = 0;

    my $serial_info = serial_info();
    $return = 1 if ($self->service_status("mailcrypt"));

    return $return;
}

            
1;
