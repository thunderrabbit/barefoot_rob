#!/bin/bash

if [ -z "$1" ]
  then
    echo "Usage: $0 <open browser? y / N>  <show drafts? y / N>"
fi

WANT_BROWSER=$1
SHOW_DRAFTS=$2

echo removing thousands of entries so Hugo can monitor changes live
rm -rf content/journal/19*
rm -rf content/journal/200*
rm -rf content/journal/201*
rm -rf content/journal/2020/*

rm -rf public/*

if [[ "$WANT_BROWSER" =~ ^[yY] ]]
  then
    xdg-open http://localhost:1313/
fi

if [[ "$SHOW_DRAFTS" =~ ^[yY] ]]
  then
    hugo server -D
  else
    hugo server
fi
