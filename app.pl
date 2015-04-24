use strict;
use Mojolicious::Lite;

use CPAN::Common::Index::LocalPackage;

my $cache_dir = $ENV{CACHE} || '.';

# static files
get '/' => sub {
    my $c = shift;
    $c->reply->static('index.html');
};

get '/versions/' => sub {
    my $c = shift;
    $c->reply->static('versions/index.html');
};

# make sure both source and cache .txt exists outside the web process
# so that it won't get into the race condition on the search time
my $index = CPAN::Common::Index::LocalPackage->new({
    source => "$cache_dir/02packages.details.txt.gz",
    cache => $cache_dir,
});

# Usually a no-op, but just in case the process boots when the cache doesn't exist
eval { $index->refresh_index };

get '/v1.0/package/:package' => sub {
    my $self = shift;
    my $package = $self->param('package');

    my $result = $index->search_packages({ package => $package })
      or return $self->render(text => "Not found\n", status => 404);

    (my $distfile = $result->{uri}) =~ s!^cpan:.*distfile/!!;
    $distfile = substr($distfile, 0, 1) . "/" . substr($distfile, 0, 2) . "/" . $distfile;

    my $data = "---\ndistfile: $distfile\nversion: $result->{version}\n";

    $self->res->headers->content_type('text/yaml');
    $self->res->headers->header('Cache-Control' => 'max-age=1800');
    $self->res->headers->header('Surrogate-Control' => 'max-age=7200');

    $self->render(text => $data);
};

get '/v1.0/history/:package' => sub {
    my $self = shift;

    my $package = $self->param('package');

    my $data = '';

    open my $fh, '<', "$cache_dir/packages.txt" or die $!;
    while (<$fh>) {
        if (/^$package\s/) {
            $data .= $_;
        }
    }

    unless ($data) {
        return $self->render(text => "Not found\n", status => 404);
    }

    $self->res->headers->content_type('text/plain');
    $self->res->headers->header('Cache-Control' => 'max-age=1800');
    $self->res->headers->header('Surrogate-Control' => 'max-age=7200');

    $self->render(text => $data);
};

app->start;


