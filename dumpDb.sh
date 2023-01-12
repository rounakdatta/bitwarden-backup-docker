#!/bin/sh
if [ $# -ne 1 ]
then
    echo "usage: 0$ filename.sql"
    exit -1
fi
sqlite3 /out/db.sqlite3 ".dump" > $1
