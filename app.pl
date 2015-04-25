use strict;

use CPANMetaDB;
use CPAN::Common::Index::LocalPackage;
use Plack::App::File;
use DBI;
use DBIx::Simple;

my $cache_dir = $ENV{CACHE} || './cache';

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

sub _format_line {
    my(@row) = @_;

    # from PAUSE::mldistwatch::rewrite02
    my $one = 30;
    my $two = 8;
    if (length $row[0] > $one) {
        $one += 8 - length $row[1];
        $two = length $row[1];
    }

    sprintf "%-${one}s %${two}s  %s\n", @row;
}

get '/v1.0/history/:package' => sub {
    my($req, $params) = @_;

    my $package = $params->{package};

    my $db = DBIx::Simple->connect("dbi:SQLite:dbname=$cache_dir/pause.sqlite3");
    my $res = $db->query("SELECT package,version,distfile FROM packages_history WHERE package=?", $package);

    my $data = '';

    for my $row ($res->arrays) {
        $data .= _format_line(@$row);
    }

    $db->disconnect;

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
