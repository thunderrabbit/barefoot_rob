#!/bin/bash
# This is designed to get files that exist on my server
# but not included in this repo
#
# 12 April 2021
#

rsync -r --remove-source-files bfr:barefoot_rob/content/ ~/barefoot_rob/content/
