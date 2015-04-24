#!/bin/bash
. /etc/profile
. /u/apps/cpanmetadb-perl/shared/.env

DATE=`date +%Y%m%d`
TMPFILE=/tmp/$DATE.$$.js

tail -100000 log/access_log | carmel exec script/drawchart.pl > $TMPFILE

carmel exec script/s3-upload.pl stats/current.js $TMPFILE application/javascript
carmel exec script/s3-upload.pl stats/$DATE.js $TMPFILE application/javascript
