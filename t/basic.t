use strict;
use HTTP::Request::Common;
use Test::More;
use Plack::Test;
use Plack::Util;
use YAML;
use t::Util;

my $app = Plack::Util::load_psgi("./app.psgi");
my $test = Plack::Test->create($app);

subtest 'GET /', sub {
    my $res = $test->request(GET "/");
    is $res->code, 200;
    like $res->content, qr!<title>CPAN Meta DB</title>!;
};

subtest 'GET /', sub {
    my $res = $test->request(GET "/");
    is $res->code, 200;
    like $res->content, qr!<title>CPAN Meta DB</title>!;
};

subtest 'GET /v1.0/package', sub {
    my $res = $test->request(GET "/v1.0/package/Plack");
    is $res->code, 200;

    my $data = eval { YAML::Load($res->content) };
    ok !$@, 'parsable YAML';

    cmp_ok $data->{version}, '>', 1;
    like $data->{distfile}, qr!MIYAGAWA/Plack-.*\.tar\.gz$!;
};

subtest 'GET /v1.0/package for perl', sub {
    my $res = $test->request(GET "/v1.0/package/strict");

    my $data = eval { YAML::Load($res->content) };
    ok !$@, 'parsable YAML';

    like $data->{distfile}, qr!/perl-.*\.tar\.(gz|bz2)$!;
};

subtest 'GET /v1.0/package for non-existing', sub {
    my $res = $test->request(GET "/v1.0/package/__xyzzy_");
    is $res->code, 404;
};

done_testing;
