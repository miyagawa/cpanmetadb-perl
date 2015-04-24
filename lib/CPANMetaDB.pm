package CPANMetaDB;
use strict;

package CPANMetaDB::IndexHandler;
use parent qw(Tatsumaki::Handler);

sub get {
    my $self = shift;
    my $file = do {
        open my $fh, "<", "index.html";
        join '', <$fh>;
    };
    $self->response->content_type('text/html; charset=utf-8');
    $self->finish($file);
}

package CPANMetaDB::VersionsHandler;
use parent qw(Tatsumaki::Handler);

sub get {
    my $self = shift;
    my $file = do {
        open my $fh, "<", "static/versions/index.html";
        join '', <$fh>;
    };
    $self->response->content_type('text/html; charset=utf-8');
    $self->finish($file);
}

package CPANMetaDB::PackageHandler;
use parent qw(Tatsumaki::Handler);
use CPANMetaDB::Dist;

sub get {
    my($self, $package) = @_;

    my $dist = CPANMetaDB::Dist->lookup($package);
    unless ($dist) {
        $self->response->code(404);
        return $self->finish('Not found');
    }

    my $data = "---\ndistfile: $dist->{distfile}\nversion: $dist->{version}\n";

    $self->response->content_type('text/x-yaml');
    $self->response->header('Cache-Control' => 'max-age=1800');
    $self->response->header('Surrogate-Control' => 'max-age=7200');
    $self->finish($data);
}

package CPANMetaDB::HistoryHandler;
use parent qw(Tatsumaki::Handler);

sub get {
    my($self, $package) = @_;

    my $data = '';

    open my $fh, '<', $ENV{PACKAGES_HISTORY_TXT} or die $!;
    while (<$fh>) {
        if (/^$package\s/) {
            $data .= $_;
        }
    }

    unless ($data) {
        $self->response->code(404);
        return $self->finish('Not found');
    }

    $self->response->content_type('text/plain');
    $self->response->header('Cache-Control' => 'max-age=1800');
    $self->response->header('Surrogate-Control' => 'max-age=7200');

    $self->finish($data);
}

1;

