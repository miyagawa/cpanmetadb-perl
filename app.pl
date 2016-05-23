use strict;

use CPANMetaDB;
use CPAN::Common::Index::LocalPackage;
use CPAN::DistnameInfo;
use Plack::App::File;
use DBI;
use DBIx::Simple;
use DBD::SQLite;
use YAML;

my $ttl = 3600 * 24 * 3;
my $cache_dir = $ENV{CACHE} || './cache';

my $root = Plack::App::File->new(file => "public/index.html")->to_app;
my $version = Plack::App::File->new(file => "public/versions/index.html")->to_app;

get '/' => [ $root ];
get '/versions/' => [ $version ];

get '/v1.0/package/:package' => sub {
    my($req, $params) = @_;

    my $package = $params->{package};

    my $db = DBIx::Simple->connect("dbi:SQLite:dbname=$cache_dir/pause.sqlite3");
    my $res = $db->query("SELECT package,version,distfile FROM packages WHERE package=? LIMIT 1", $package);

    my $result = $res->hash;
    $db->disconnect;

    unless ($result) {
        return Plack::Response->new(
            404,
            ["Content-Type" => "text/plain", "Surrogate-Control" => "max-age=$ttl"],
            "Not found\n",
        );
    }

    my $dist = CPAN::DistnameInfo->new($result->{distfile})->dist;
    my $data = "---\ndistfile: $result->{distfile}\nversion: $result->{version}\n";

    my $res = Plack::Response->new(200);
    $res->content_type('text/yaml');
    $res->header('Cache-Control' => 'max-age=1800');
    $res->header('Surrogate-Key' => "v1.0/package $package $dist $result->{distfile}");
    $res->header('Surrogate-Control' => "max-age=$ttl, stale-if-error=10800, stale-while-revalidate=30");
    $res->body($data);
    $res;
};

get '/v1.1/package/:package' => sub {
    my($req, $params) = @_;

    my $package = $params->{package};

    my $db = DBIx::Simple->connect("dbi:SQLite:dbname=$cache_dir/pause.sqlite3");
    my $res = $db->query(
        "SELECT package,version,distfile FROM packages WHERE distfile IN " .
        "(SELECT distfile FROM packages WHERE package=? LIMIT 1)",
        $package,
    );

    my @results = $res->hashes;
    $db->disconnect;

    my($result) = grep { $_->{package} eq $package } @results;

    unless ($result) {
        return Plack::Response->new(
            404,
            ["Content-Type" => "text/plain", "Surrogate-Control" => "max-age=$ttl"],
            "Not found\n",
        );
    }

    my $dist = CPAN::DistnameInfo->new($result->{distfile})->dist;

    my $data = {
        distfile => $result->{distfile},
        version  => $result->{version},
        provides => {},
    };

    for my $row (@results) {
        $data->{provides}{$row->{package}} = $row->{version};
    }

    my $res = Plack::Response->new(200);
    $res->content_type('text/yaml');
    $res->header('Cache-Control' => 'max-age=1800');
    $res->header('Surrogate-Key' => "v1.1/package $package $dist $result->{distfile}");
    $res->header('Surrogate-Control' => "max-age=$ttl, stale-if-error=10800, stale-while-revalidate=30");
    $res->body(YAML::Dump($data));
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

    my @rows = $res->arrays;
    for my $row (@rows) {
        $data .= _format_line(@$row);
    }

    $db->disconnect;

    unless ($data) {
        return Plack::Response->new(404, ["Content-Type" => "text/palin"], "Not found\n");
    }

    my $distfile = $rows[-1][2];
    my $dist = CPAN::DistnameInfo->new($distfile)->dist;

    my $res = Plack::Response->new(200);
    $res->content_type('text/plain');
    $res->header('Cache-Control' => 'max-age=1800');
    $res->header('Surrogate-Key' => "v1.0/history $package $dist $distfile");
    $res->header('Surrogate-Control' => "max-age=$ttl, stale-if-error=10800, stale-while-revalidate=30");
    $res->body($data);
    $res;
};

use Plack::Builder;

builder {
    enable "Static",
      path => qr{\.(?:css|js|html)$}, root => 'public';
    app;
}
