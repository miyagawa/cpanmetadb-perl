use strict;
use Tatsumaki::Application;
use CPANMetaDB;

my $app = Tatsumaki::Application->new([
    '/v1\.0/package/(.*)' => 'CPANMetaDB::PackageHandler',
    '/v1\.0/history/(.*)' => 'CPANMetaDB::HistoryHandler',
    '/versions/' => 'CPANMetaDB::VersionsHandler',
    '/' => 'CPANMetaDB::IndexHandler',
]);

return $app->psgi_app;
