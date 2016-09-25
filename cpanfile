requires 'Plack', '1.0041';
requires 'Plack::Request';
requires 'Router::Simple';
requires 'Digest::SHA1';
requires 'CPAN::Common::Index', '0.006';
requires 'CPAN::DistnameInfo';

requires 'DBI';
requires 'DBD::SQLite';
requires 'DBIx::Simple';

requires 'Starman';
requires 'Server::Starter', 0.14;
requires 'Net::Server::SS::PreFork';

requires 'Amazon::S3';
requires 'CPAN::DistnameInfo';
requires 'File::pushd';

on test => sub {
    requires 'YAML';
};
