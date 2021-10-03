#!/bin/bash
# This is designed to upload pics after Walk and Talk events

THISYEAR=$(date +'%Y')

scp $@ b.rn:b.robnugen.com/blog/$THISYEAR/walk_and_talk

ssh b.rn "scripts/create_thumbs.pl /home/thundergoblin/b.robnugen.com/blog/$THISYEAR/walk_and_talk"
