#!/bin/sh
DATE=`date +%Y%m%d`
mkdir static/versions 2>/dev/null
tail -100000 access_log | perl script/drawchart.pl > static/versions/index.html
cp static/versions/index.html static/versions/$DATE.html
