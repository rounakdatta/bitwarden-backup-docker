#!/bin/bash
set -e

if [ $# -ne 6 ]
then
    echo "usage: $0 username password clientid clientsecret outputfile.json attachments_dir"
    exit -1
fi

BW_EMAIL=$1
BW_PW=$2
OUTPUT_JSON=$5
ATTACHMENTS_DIR=$6

echo "starting backup for user $BW_EMAIL"

bw config server $BITWARDEN_URL
bw logout || echo "not logged in"

export NODE_TLS_REJECT_UNAUTHORIZED=0
BW_CLIENTID=$3 BW_CLIENTSECRET=$4 bw login --apikey
export BW_SESSION=$(bw unlock --raw "${BW_PW}")
echo "Session: $BW_SESSION"

bw sync

if [ $? -ne 0 ]
then
  echo "Sync failed"
  exit -1
fi

echo --- list items ---
bw list items --pretty >> $OUTPUT_JSON
if [ $? -ne 0 ]
then
  echo "List items failed"
  exit -1
fi

echo --- list folders ---
bw list folders --pretty >> $OUTPUT_JSON
if [ $? -ne 0 ]
then
  echo "List folders failed"
  exit -1
fi

echo --- list collections ---
bw list collections --pretty >> $OUTPUT_JSON
if [ $? -ne 0 ]
then
  echo "List collections failed"
  exit -1
fi

echo --- list organizations ---
bw list organizations --pretty >> $OUTPUT_JSON
if [ $? -ne 0 ]
then
  echo "List organizations failed"
  exit -1
fi

echo --- export attachments to $ATTACHMENTS_DIR ---
# need to export since following commands are running in a new bash
export ATTACHMENTS_DIR
# Thanks to https://github.com/ckabalan/bitwarden-attachment-exporter
bash <(bw list items | jq -r '.[] | select(.attachments != null) | . as $parent | .attachments[] | "bw get attachment \(.id) --itemid \($parent.id) --output \"$ATTACHMENTS_DIR/\($parent.id)/\(.fileName)\""')
if [ $? -ne 0 ]
then
  echo "Export of attachments failed"
  exit -1
fi
echo "backup done"

