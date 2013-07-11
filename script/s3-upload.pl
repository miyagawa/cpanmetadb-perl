#!/usr/bin/env perl
use strict;
use Amazon::S3;

my($key, $file, $mime) = @ARGV;
my $s3 = Amazon::S3->new({
    aws_access_key_id => $ENV{AWS_ACCESS_KEY_ID},
    aws_secret_access_key => $ENV{AWS_SECRET_ACCESS_KEY},
});

my $content = do {
    open my $fh, "<", $file or die $!;
    join '', <$fh>;
};

my $bucket = $s3->bucket("cpanmetadb.plackperl.org");
$bucket->add_key($key, $content, { content_type => $mime });

