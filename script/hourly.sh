#!/bin/bash
. /etc/profile
. /u/apps/cpanmetadb-perl/shared/.env

export CACHE=/u/apps/cpanmetadb-perl/shared/cache
export DOCS=/var/www/cpanmetadb-data.plackperl.org/htdocs
mkdir -p $CACHE

TS=`date +%s`

(cd $CACHE && wget -q http://www.cpan.org/modules/02packages.details.txt.gz -N)
gunzip -c $CACHE/02packages.details.txt.gz > $CACHE/02packages.details.txt.$TS
diff -u $CACHE/02packages.details.txt $CACHE/02packages.details.txt.$TS > $CACHE/02packages.diff.$TS
ln -f $CACHE/02packages.details.txt.$TS $CACHE/02packages.details.txt
rm $(ls $CACHE/02packages.details.txt.* | grep -Ev ".gz|.$TS")

carmel exec script/pause-visit /home/web/PAUSE-git -o $DOCS 2>&1
gzip -c $DOCS/packages.txt > $DOCS/packages.txt.gz

cp $DOCS/packages.txt $CACHE/packages.txt.$TS
ln -f $CACHE/packages.txt.$TS $CACHE/packages.txt
rm $(ls $CACHE/packages.txt.* | grep -Ev ".$TS")

export DSN=dbi:SQLite:dbname=$CACHE/pause.sqlite3.$TS
carmel exec script/dumpsql.pl
ln -f $CACHE/pause.sqlite3.$TS $CACHE/pause.sqlite3
rm $(ls $CACHE/pause.sqlite3.* | grep -Ev ".$TS")

carmel exec script/purge $CACHE/02packages.diff.$TS
rm $CACHE/02packages.diff.*
