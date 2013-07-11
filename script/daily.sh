#!/bin/sh

source /u/apps/cpanmetadb-perl/shared/.env

DATE=`date +%Y%m%d`
TMPFILE=/tmp/$DATE.$$.js

tail -100000 log/access_log | carton exec script/drawchart.pl > $TMPFILE

carton exec script/s3-upload.pl $TMPFILE stats/current.js application/javascript
carton exec script/s3-upload.pl $TMPFILE stats/$DATE.js application/javascript
