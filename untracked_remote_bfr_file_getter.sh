#!/bin/bash
# This is designed to get files that exist on my server
# but not included in this repo
#
# 12 April 2021
#

# rsync caused havoc by wiping too much or leaving everything

REMOTE_UNTRACKED_FILES="$1"

# REMOTE_BFR_DIR should match ~/journal/untracked_remote_bfr_file_shower.sh
REMOTE_BFR_DIR='~/barefoot_rob/content'         # must be in single quotes so ~ does not expand locally.
LOCAL_BFR_DIR=~/barefoot_rob/content         # must not be in any quotes so ~ does expand locally.
REMOTE_JUSTIN_CASE='~/untracked_files_copied_to_local_box'  # must be in single quotes so ~ does not expand locally.

while read -r line; do
    mkdir -p $(dirname $LOCAL_BFR_DIR/$line);
    scp -F ~/.ssh/config_no_visual_keys bfr:$REMOTE_BFR_DIR/$line $LOCAL_BFR_DIR/$line
    if [ $? -eq 0 ]; then
        echo copy OK
      	echo moving remote file to $REMOTE_JUSTIN_CASE
      	# https://stackoverflow.com/a/9393147/194309 -n keeps ssh from breaking while loop
      	ssh -n -F ~/.ssh/config_no_visual_keys bfr "mv $REMOTE_BFR_DIR/$line $REMOTE_JUSTIN_CASE"
    else
        echo copy FAIL
        echo trying next file
    fi
done <<< "$REMOTE_UNTRACKED_FILES"
