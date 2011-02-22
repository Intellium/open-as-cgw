package Underground8::Service::Avira;
use base Underground8::Service;

use strict;
use warnings;

use Underground8::Utils;
use Underground8::Service::Avira::SLAVE;

#Constructor
sub new ($$)
{
    my $class = shift;
    my $self = $class->SUPER::new();
    $self->{'_slave'} = new Underground8::Service::Avira::SLAVE();
    $self->{'_archive_recursion'} = 0;
    $self->{'_archive_maxfilesize'} = '10M';
    $self->{'_archive_maxfiles'} = 2500;

    return $self;
}

#### Accessors ####
sub archive_recursion {
    my $self = instance(shift);
    if (@_) {
        $self->{'_archive_recursion'} = shift;
        $self->change;
    }
    return $self->{'_archive_recursion'};
}

sub commit {
    my $self = shift;

    my $archive_recursion = $self->{'_archive_recursion'};

    my $files;
    push @{$files}, $g->{'file_avira_serverconf'};
    push @{$files}, $g->{'file_avira_updaterconf'};
    push @{$files}, $g->{'file_avira_mirrorconf'};
    my $md5_first = $self->create_md5_sums($files);

    $self->slave->write_config($archive_recursion);

    my $md5_second = $self->create_md5_sums($files);
    if ($self->compare_md5_hashes($md5_first, $md5_second)) {
        $self->slave->service_restart();
    }
    $self->unchange;

}


1;
