use Plack::Builder;

my $app = do "./app.psgi";

builder {
    enable "Head";
    mount 'http://sunaba.plackperl.org/' => sub {
        return [ 404, ['Content-Type', 'text/plain'], ['Not Found'] ];
    };
    mount '/' => $app;
};
