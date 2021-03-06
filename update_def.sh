#!/bin/bash
export DEVICE=$1
export LATEST=$(basename $2)

cd android_loup_ota

export TIMESTAMP=$(date -d $(cut -d'-' -f3 <<< $LATEST) +%s)
jq ".[\"./$DEVICE\"] +=[{ \"filename\" : \"$LATEST\" , \"timestamp\" : $TIMESTAMP }]" devices.json > tmp.json
mv tmp.json devices.json

git config --global user.email "e.noyer.silva@gmail.com"
git config --global user.name "bitrvmpd"

git add .
git commit -am "Updated devices.json"
git push origin opendelta

exit 0
