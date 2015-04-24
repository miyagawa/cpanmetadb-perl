use Plack::Builder;
use Digest::SHA1 qw(sha1_hex);

my $salt = int(rand(2**32));

sub almost_uniq_hash {
    my $ip = shift;
    $ip =~ s/(\d+)\.?/sprintf("%02x", $1)/ge;

    my $val = join "-", $ip, (hex($ip) % $salt);
    substr(sha1_hex($val), 0, 16);
}

sub maybe_travis {
    local $_ = shift;
    /^199\.91\.17[01]\./ or /^199\.182\.120\./; # Travis CI
}

my $app = require "./app.pl";

my $head = sub {
    my $app = shift;
    sub {
        my $env = shift;
        if ($env->{REQUEST_METHOD} eq 'HEAD' && $env->{PATH_INFO} eq '/') {
            return [ 200, [], [] ];
        }
        $app->($env);
    };
};

my $munge_addr = sub {
    my $app = shift;
    sub {
        $_[0]->{REMOTE_ADDR} = almost_uniq_hash($_[0]->{HTTP_FASTLY_CLIENT_IP});
        $_[0]->{HTTP_USER_AGENT} .= " travis" if maybe_travis($_[0]->{HTTP_FASTLY_CLIENT_IP});
        $app->($_[0]);
    };
};

builder {
    enable 'Runtime';
    enable $head;
    enable $munge_addr;
    enable 'ContentLength';
    mount 'http://sunaba.plackperl.org/' => sub {
        return [ 404, ['Content-Type', 'text/plain'], ['Not Found'] ];
    };
    mount '/static/versions/' => sub {
        my $env = shift;
        return [ 301, ['Location' => "http://$env->{HTTP_HOST}/versions/"], [] ];
    };
    mount '/' => $app;
};
