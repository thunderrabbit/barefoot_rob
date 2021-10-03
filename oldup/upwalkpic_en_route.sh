#!/bin/bash
# This is designed to make it easier to copy images from finder to b.robnugen.com/journal/YYYY/walk/

THISYEAR=$(date +'%Y')

echo remember you can
echo ssh b.rn "'mkdir -p ~/b.robnugen.com/journal/$THISYEAR/route_plans'"

scp $@ b.rn:b.robnugen.com/quests/walk-to-niigata/$THISYEAR/route_plans
