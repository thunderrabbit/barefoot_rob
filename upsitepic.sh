#!/bin/bash
# This is designed to make it easier to copy images from finder to b.robnugen.com

THISYEAR=$(date +'%Y')

echo remember you can
echo ssh b.rn "'mkdir -p ~/b.robnugen.com/sites/rnc/$THISYEAR'"

scp $@ b.rn:b.robnugen.com/sites/rnc/$THISYEAR

ssh b.rn "scripts/create_thumbs.pl /home/thundergoblin/b.robnugen.com/sites/rnc/$THISYEAR"
