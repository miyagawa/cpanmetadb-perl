package t::Util;
use strict;
use File::Basename;

BEGIN {
    $ENV{CACHE} = dirname(__FILE__) . "/cache";
}

sub import {
    unless (-e "$ENV{CACHE}/pause.sqlite3") {
        system 't/setup';
    }
}

1;
