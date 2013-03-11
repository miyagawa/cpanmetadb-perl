use Plack::Builder;

my $app = do "./app.psgi";

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

builder {
    enable $head;
    enable sub {
        my $app = shift;
        sub { $_[0]->{REMOTE_ADDR} = $_[0]->{HTTP_FASTLY_CLIENT_IP}; $app->($_[0]) };
    };
    mount 'http://sunaba.plackperl.org/' => sub {
        return [ 404, ['Content-Type', 'text/plain'], ['Not Found'] ];
    };
    mount '/' => $app;
};
