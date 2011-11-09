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
    $self->finish($data);
}


1;

