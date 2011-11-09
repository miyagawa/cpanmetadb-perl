use strict;
use Tatsumaki::Application;
use CPANMetaDB;
use CPANMetaDB::Dist;

my $updater = CPANMetaDB::Dist::Updater->new;

my $app = Tatsumaki::Application->new([
    '/v1\.0/package/(.*)' => 'CPANMetaDB::PackageHandler',
    '/' => 'CPANMetaDB::IndexHandler',
]);

return $app->psgi_app;
