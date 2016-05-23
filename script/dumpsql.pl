#!/usr/bin/env perl
use strict;
use DBI;

my $cache_dir = $ENV{CACHE} || './cache';

$ENV{DSN} ||= "dbi:SQLite:dbname=$cache_dir/pause.sqlite3";
my $dbh = DBI->connect($ENV{DSN}, '', '', { AutoCommit => 1, RaiseError => 1 })
  or die "Can't connect to the database";

$dbh->begin_work;

build_packages($dbh);
build_packages_history($dbh);

$dbh->commit;

sub build_packages {
    my $dbh = shift;
    populate_table($dbh, 'packages', "$cache_dir/02packages.details.txt", 1);
}

sub build_packages_history {
    my $dbh = shift;
    populate_table($dbh, 'packages_history', "$cache_dir/packages.txt", 0);
}

sub populate_table {
    my($dbh, $name, $file, $skip_header) = @_;

    warn "---> Populating $name from $file\n";
    
    $dbh->do("DROP TABLE IF EXISTS $name");

    $dbh->do(<<SQL);
CREATE TABLE $name (
  package varchar(128),
  version varchar(16),
  distfile varchar(128)
)
SQL
    $dbh->do("CREATE INDEX idx_${name} ON $name(package)");
    $dbh->do("CREATE INDEX idx_${name}_distfile ON $name(distfile)");

    my $insert = $dbh->prepare_cached("INSERT INTO $name VALUES (?, ?, ?)");

    open my $fh, "<", $file or die "$file: $!";
    if ($skip_header) {
        while (<$fh>) {
            chomp;
            last if /^\s*$/;
        }
    }
    
    my $i;
    while (<$fh>) {
        chomp;
        my($pkg, $version, $dist) = split /\s+/;
        $insert->execute($pkg, $version, $dist);
        warn $i, "\n" if ++$i % 100000 == 0;
    }

    warn "Imported $i packages.\n";
}



