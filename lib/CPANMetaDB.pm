package CPANMetaDB;
use strict;
use parent qw(Exporter);
our @EXPORT = qw(get app);

use Router::Simple;
use Plack::Request;
use Plack::Response;

my $router = Router::Simple->new;

sub get {
    my($path, $action) = @_;
    if (ref $action eq 'ARRAY') {
        $router->connect($path => { app => $action->[0] });
    } else {
        $router->connect($path, { action => $action });
    }
}

sub app {
    sub {
        my $env = shift;
        if (my $p = $router->match($env->{PATH_INFO})) {
            if ($p->{action}) {
                my $res = $p->{action}->(Plack::Request->new($env), $p);
                $res = $res->finalize if ref $res ne 'ARRAY';
                return $res;
            } elsif ($p->{app}) {
                $p->{app}->($env);
            }
        } else {
            [ 404, [ 'Content-Type' => 'text/plain' ], [ "Not found\n" ] ];
        }
    };
}

1;

