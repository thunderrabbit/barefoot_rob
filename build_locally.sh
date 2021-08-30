#!/bin/bash

if [ -z "$1" ]
  then
    echo "Usage: $0 <open browser? y / N>  <show drafts? y / N>"
fi

WANT_BROWSER=$1
SHOW_DRAFTS=$2

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
