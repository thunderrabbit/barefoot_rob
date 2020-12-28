#!/bin/bash

if [ -z "$1" ]
  then
    echo "Usage: $0 <Do you like new browser tab? Y / N>"
    exit
fi

WANT_BROWSER=$1

rm -rf content/journal/19*
rm -rf content/journal/200*
rm -rf content/journal/201*

rm -rf content/public/*

if [[ "$WANT_BROWSER" =~ ^[yY] ]]
  then
    xdg-open http://localhost:1313/
fi

hugo server
