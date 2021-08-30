#!/bin/bash
# This is designed to show what files exist on my server under ~/barefoot_rob
# but not included in the local repo
#
# 13 April 2021
#
# -F specifies a config file that does not show the ssh key visual fingerprint
# bfr is my journal Micropub server endpoint defined in .ssh/config_no_visual_keys
# git ls-files -o  shows untracked files on a line per line basis but does not handle spaces in filesnames  https://stackoverflow.com/a/8506155/194309

# REMOTE_BFR_DIR should match ~/journal/untracked_remote_bfr_file_getter.sh
REMOTE_BFR_DIR='~/barefoot_rob_master/content'    #REMOTE_BFR_DIR must be in single quotes so ~ does not expand locally.


ssh -F ~/.ssh/config_no_visual_keys bfr "cd $REMOTE_BFR_DIR; git ls-files -o"
