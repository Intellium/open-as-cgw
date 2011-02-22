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


package LimesGUI::Controller::Admin::Modules::Licence_Management;

use namespace::autoclean;
use base 'LimesGUI::Controller';
use strict;
use warnings;
use Underground8::Utils;
use File::Copy;
use Error qw(:try);
use Data::FormValidator::Constraints qw(:closures :regexp_common);
use Underground8::Exception;
use Underground8::Log;



sub index : Private {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};

	update_stash($self, $c);
}

sub update_stash {
	my ($self, $c) = @_;
	my $appliance = $c->config->{'appliance'};

	$c->stash->{'sn'} = $appliance->sn;
	$c->stash->{'system'} = $appliance->system;
	$c->stash->{'renew_licence_warning'} = $appliance->report->license->renew_licence_warning;
	$c->stash->{'license_info'} = $appliance->report->license->license_info();;
	$c->stash->{'services'} = avail_lic_services();

	# new license always requires info-box to be updated
	$c->stash->{'template'} = 'admin/modules/licence_management.tt2';
}

sub upload_license_file : Local {
	my ($self, $c) = @_;
	my $appliance = $c->config->{'appliance'};
	my $limit = 10240;

	my $form_profile = {
		required => [qw(ulf)],
	};

	my $result = $self->process_form($c, $form_profile);
	if($result->success()) {
		my $upload = $c->req->upload('ulf');
		if($upload) {
			if($upload->size < $limit) {
				my $tmpfile = $upload->tempname;

				try {
					$appliance->report->license->read_license_file($tmpfile);
					copy($tmpfile, $g->{'file_license_ulf'});
				} catch Underground8::Exception::LicenseWrongSN with {
					aslog "warn", "Error uploading licence file: Wrong SN";
					my $info = error($self, $c, shift);
					$c->stash->{'box_status'}->{'custom_error'} = $c->localize('downloaded_license_file_wrong_sn') . " (" . $info . ")";
				} catch Underground8::Exception with {
					aslog "warn", "Error uploading licence file";
					my $info = error($self, $c, shift);
					$c->stash->{'redirect_url'} = $c->uri_for('/error');
					$c->stash->{'template'} = 'redirect.inc.tt2';
				} catch Error with {
					aslog "warn", "Error uploading licence file";
					my $info = error($self, $c, shift);
					$c->stash->{'box_status'}->{'custom_error'} = $c->localize('downloaded_license_file_not_recognized');
				};
			} else {
				# upload size limit exceeded
				aslog "warn", "Error uploading licence file: File too big";
				$c->stash->{'box_status'}->{'custom_error'} = $c->localize('license_file_upload_too_big');
			}
			unlink($upload);
		} else { print STDERR "*** upload failed\n"; }
	}

	update_stash($self, $c);
	$c->config->{'renew_licence_warning'} = $appliance->report->license->renew_licence_warning();

	aslog "info", "Uploaded new licence file";
	$c->stash->{'box_status'}->{'success'} = 'success';
	# $c->stash->{'no_wrapper'} = "1"; 
}

sub get_license_file : Local {
	my ($self, $c) = @_;
	my $appliance = $c->config->{'appliance'};
	$c->config->{'renew_licence_warning'} = $appliance->report->license->renew_licence_warning();

	update_stash($self, $c);
	$c->stash->{'no_wrapper'} = "1"; 

	try {
		my $xml = $appliance->report->license->create_xml();
		my $tmpfile = $appliance->report->license->get_license_file($xml);
		$appliance->report->license->read_license_file($tmpfile);

		copy($tmpfile, $g->{'file_license_ulf'});
		aslog "info", "Updated licence file information";
		$c->stash->{'box_status'}->{'success'} = 'success';
	} catch Underground8::Exception::LicenseWrongSN with {
		aslog "warn", "Error updating licence file info: Wrong SN";
		my $info = error($self, $c, shift);
		$c->stash->{'box_status'}->{'custom_error'} = $c->localize('downloaded_license_file_wrong_sn') . " (" . $info . ")";
	} catch Underground8::Exception with {
		aslog "warn", "Error updating licence file info";
		my $info = error($self, $c, shift);
		$c->stash->{'redirect_url'} = $c->uri_for('/error');
		$c->stash->{'template'} = 'redirect.inc.tt2';
	} catch Error with {
		aslog "warn", "Error updating licence file info: File not recognized";
		my $info = error($self, $c, shift);
		$c->stash->{'box_status'}->{'custom_error'} = $c->localize('downloaded_license_file_not_recognized');
	};
}

sub error {
	my ($self, $c, $E) = @_;
	aslog "warn", "Caught exception $E";
	$c->session->{'exception'} = $E;
	$c->stash->{'voucher'} = $c->req->param("voucher");
	return $E->{'_caught_exception'};
}

sub activate_voucher : Local {
	my ($self, $c) = @_;
	my $appliance = $c->config->{'appliance'};
	$c->config->{'renew_licence_warning'} = $appliance->report->license->renew_licence_warning();

	my $form_profile = {
		required => [qw(k1 k2 k3 k4 k5 k6 k7 k8)],
	};

	my $result = $self->process_form($c, $form_profile);
	if($result->success()){
		try {
			# Get key
			my ($k1, $k2, $k3, $k4, $k5, $k6, $k7, $k8) =
			(uc $c->req->param("k1"), uc $c->req->param("k2"),  uc $c->req->param("k3"), uc $c->req->param("k4"),
			 uc $c->req->param("k5"), uc $c->req->param("k6"),  uc $c->req->param("k7"), uc $c->req->param("k8"));

			my $voucher = $k1 . $k2 . $k3 . $k4 . $k5 . $k6 . $k7 . $k8;
			my $xml = $appliance->report->license->create_xml($voucher);
			my $tmpfile = $appliance->report->license->get_license_file($xml);

			$appliance->report->license->read_license_file($tmpfile);
			copy($tmpfile, $g->{'file_license_ulf'});

			aslog "info", "Activated new voucher code";
			$c->stash->{'box_status'}->{'success'} = 'success';
		} catch Underground8::Exception::LicenseWrongSN with {
			aslog "warn", "Error activating new voucher: Wrong SN";
			my $info = error($self, $c, shift);
			$c->stash->{'box_status'}->{'custom_error'} = $c->localize('downloaded_license_file_wrong_sn') . " (" . $info . ")";
		} catch Underground8::Exception::XMLRPCError with {
			aslog "warn", "Error activating new voucher: XML RPC error";
			my $info = error($self, $c, shift);
			$c->stash->{'box_status'}->{'custom_error'} = $c->localize("error_code_short_xmlrpc_$info");
		} catch Underground8::Exception with {
			aslog "warn", "Error activating new voucher";
			my $info = error($self, $c, shift);
			$c->stash->{'redirect_url'} = $c->uri_for('/error');
			$c->stash->{'template'} = 'redirect.inc.tt2';
		} catch Error with {
			aslog "warn", "Error activating new voucher: File not recognized";
			my $info = error($self, $c, shift);
			$c->stash->{'box_status'}->{'custom_error'} = $c->localize("downloaded_license_file_not_recognized");
		};
	}

	update_stash($self, $c);
	$c->stash->{'no_wrapper'} = "1"; 
}


1;
