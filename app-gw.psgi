use Plack::Builder;
use Digest::SHA qw(sha1_hex);
use File::Slurper qw(read_lines);

my $salt = int(rand(2**32));
my %travis_ip = map { $_ => 1 } read_lines("./travis-ip.txt");

sub almost_uniq_hash {
    my $ip = shift;
    $ip =~ s/(\d+)\.?/sprintf("%02x", $1)/ge;

    my $val = join "-", $ip, (hex($ip) % $salt);
    substr(sha1_hex($val), 0, 16);
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
        $_[0]->{HTTP_USER_AGENT} .= " travis" if $travis_ip{$_[0]->{HTTP_FASTLY_CLIENT_IP}};
        $app->($_[0]);
    };
};

builder {
    enable 'Runtime';
    enable $head;
    enable $munge_addr;
    enable 'ContentLength';
    mount '/static/versions/' => sub {
        my $env = shift;
        return [ 301, ['Location' => "http://$env->{HTTP_HOST}/versions/"], [] ];
    };
    mount '/' => $app;
};
