package Underground8::Service::Avira::SLAVE;
use base Underground8::Service::SLAVE;
use Template;
use Underground8::Exception;
use Underground8::Exception::FileOpen;
use Underground8::Utils;

use strict;
use warnings;


sub write_config {
    my $self = instance(shift);

    my $archive_recursion = shift;

    my $template = Template->new ({ INCLUDE_PATH => $g->{'cfg_template_dir'}, }); 
    my $options = { archive_recursion => $archive_recursion, };
    my $config_content;
    $template->process($g->{'template_avira_serverconf'},$options,\$config_content) 
        or throw Underground8::Exception($template->error);

    open (AVIRA_LIMES,'>',$g->{'file_avira_serverconf'})
        or throw Underground8::Exception::FileOpen($g->{'file_avira_serverconf'});
    print AVIRA_LIMES $config_content;
    close (AVIRA_LIMES); 

    $config_content = "";
    $options = {};
    $template->process($g->{'template_avira_updaterconf'},$options,\$config_content) 
        or throw Underground8::Exception($template->error);
    open (AVIRA_LIMES,'>',$g->{'file_avira_updaterconf'})
        or throw Underground8::Exception::FileOpen($g->{'file_avira_updaterconf'});
    print AVIRA_LIMES $config_content;
    close (AVIRA_LIMES); 

    $config_content = "";
    $options = {};
    $template->process($g->{'template_avira_mirrorconf'},$options,\$config_content) 
        or throw Underground8::Exception($template->error);
    open (AVIRA_LIMES,'>',$g->{'file_avira_mirrorconf'})
        or throw Underground8::Exception::FileOpen($g->{'file_avira_mirrorconf'});
    print AVIRA_LIMES $config_content;
    close (AVIRA_LIMES); 

}

sub service_restart ($) {
    my $self = instance(shift);
    my $output = safe_system($g->{'cmd_avira_server_restart'});
    my $output = safe_system($g->{'cmd_sambucus_server_restart'});
}
 

1;

