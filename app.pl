use strict;

use CPANMetaDB;
use CPAN::Common::Index::LocalPackage;
use CPAN::DistnameInfo;
use Plack::App::File;
use DBI;
use DBIx::Simple;
use DBD::SQLite;

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
        return Plack::Response->new(404,  ["Content-Type" => "text/plain"], "Not found\n");
    }

    my $dist = CPAN::DistnameInfo->new($result->{distfile})->dist;
    my $data = "---\ndistfile: $result->{distfile}\nversion: $result->{version}\n";

    my $res = Plack::Response->new(200);
    $res->content_type('text/yaml');
    $res->header('Cache-Control' => 'max-age=1800');
    $res->header('Surrogate-Key' => "v1.0/package $package $dist $result->{distfile}");
    $res->header('Surrogate-Control' => 'max-age=86400, stale-if-error=3600');
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
    $res->header('Surrogate-Control' => 'max-age=3600, stale-if-error=3600');
    $res->body($data);
    $res;
};

use Plack::Builder;

builder {
    enable "Static",
      path => qr{\.(?:css|js|html)$}, root => 'public';
    app;
}
