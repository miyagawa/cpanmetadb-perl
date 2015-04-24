use strict;

use CPANMetaDB;
use CPAN::Common::Index::LocalPackage;
use Plack::App::File;

my $cache_dir = $ENV{CACHE} || '.';

# make sure both source and cache .txt exists outside the web process
# so that it won't get into the race condition on the search time
my $index = CPAN::Common::Index::LocalPackage->new({
    source => "$cache_dir/02packages.details.txt.gz",
    cache => $cache_dir,
});

# Usually a no-op, but just in case the process boots when the cache doesn't exist
eval { $index->refresh_index };

my $root = Plack::App::File->new(file => "public/index.html")->to_app;
my $version = Plack::App::File->new(file => "public/versions/index.html")->to_app;

get '/' => [ $root ];
get '/versions/' => [ $version ];

get '/v1.0/package/:package' => sub {
    my($req, $params) = @_;
    
    my $package = $params->{package};

    my $result = $index->search_packages({ package => $package })
      or return Plack::Response->new(404,  ["Content-Type" => "text/plain"], "Not found\n");

    (my $distfile = $result->{uri}) =~ s!^cpan:.*distfile/!!;
    $distfile = substr($distfile, 0, 1) . "/" . substr($distfile, 0, 2) . "/" . $distfile;

    my $data = "---\ndistfile: $distfile\nversion: $result->{version}\n";

    my $res = Plack::Response->new(200);
    $res->content_type('text/yaml');
    $res->header('Cache-Control' => 'max-age=1800');
    $res->header('Surrogate-Control' => 'max-age=7200');
    $res->body($data);
    $res;
};

get '/v1.0/history/:package' => sub {
    my($req, $params) = @_;

    my $package = $params->{package};

    my $data = '';

    open my $fh, '<', "$cache_dir/packages.txt" or die $!;
    while (<$fh>) {
        if (/^$package\s/) {
            $data .= $_;
        }
    }

    unless ($data) {
        return Plack::Response->new(404, ["Content-Type" => "text/palin"], "Not found\n");
    }

    my $res = Plack::Response->new(200);
    $res->content_type('text/plain');
    $res->header('Cache-Control' => 'max-age=1800');
    $res->header('Surrogate-Control' => 'max-age=7200');
    $res->body($data);
    $res;
};

use Plack::Builder;

builder {
    enable "Static",
      path => qr{\.(?:css|js|html)$}, root => 'public';
    app;
}
