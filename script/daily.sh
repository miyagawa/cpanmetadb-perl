#!/bin/bash

. /u/apps/cpanmetadb-perl/shared/.env
export PERL_CARTON_PATH=/u/apps/cpanmetadb-perl/shared/local

DATE=`date +%Y%m%d`
TMPFILE=/tmp/$DATE.$$.js

tail -100000 log/access_log | carton exec script/drawchart.pl > $TMPFILE

carton exec script/s3-upload.pl stats/current.js $TMPFILE application/javascript
carton exec script/s3-upload.pl stats/$DATE.js $TMPFILE application/javascript
