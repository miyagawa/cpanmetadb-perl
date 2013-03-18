#!/bin/sh
cd `dirname $0`
DATE=`date +%Y%m%d`
mkdir ../static/versions 2>/dev/null
tail -100000 ../access_log | perl drawchart.pl > ../static/versions/current.js
cp ../static/versions/current.js ../static/versions/$DATE.js

