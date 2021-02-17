#!/bin/bash

echo stop the presses
echo
echo We are now using acast for podcasts
echo
echo 1. Decide on event title
echo 2. Create event via Emacs
echo 3. Find image matching the content
echo 4. Create placeholder for podcast on acast.com
echo 5. Upload image to b.robnugen.com
echo 6. add image to event on Emacs and acast.com
echo 7. add image credit to both places
echo 8. write a blurb in both places
echo 9. Post event on robnugen.com
echo 10. Wait for event date

echo 1. Light a candle to bless the event
echo 2. Record audio locally
echo 3. Rename audio file yyyy_mmm_dd_title.wav
echo 4. Upload to otter.ai
echo 5. wait for transcription

echo 1. Download otter.ai.txt file for the .wav file
echo 2. Open .wav file with audacity via 'aud' at command line which fixes a display bug
echo 3. Trim and clean up the audio file
echo 4. Trim and clean up the text file
echo 5. Export .mp3 file as before
echo 6. Upload .mp3 file to acast
echo 7. Create blog entry for the podcast
echo 8. Embed text file of transcript
echo 9. Point past episodes in about.md to blog entry on rnc
echo 10. repeat

echo cd ~/barefoot_rob
echo ./up_weekly_alignments.sh


#-2021-feb-17-# #
#-2021-feb-17-# #
#-2021-feb-17-# #
#-2021-feb-17-# # This is designed to make it easier to copy Weekly Alignment .mp3 and .ogg files from finder to b.robnugen.com
#-2021-feb-17-# #
#-2021-feb-17-# # My user story:
#-2021-feb-17-# #
#-2021-feb-17-# # * I created two (n) files, which are on my local file system at /path/file_mc_file.mp3  and /path/file_mc_file.ogg
#-2021-feb-17-# # * I send these to a year-based directory on my server
#-2021-feb-17-# # * I see a bit of text based on the file names (and number of files)
#-2021-feb-17-# #
#-2021-feb-17-# #
#-2021-feb-17-# # <audio controls>
#-2021-feb-17-# # <source src="//b.robnugen.com/rob/presentations/weekly-alignments/2020/file_mc_file.ogg" type="audio/ogg">
#-2021-feb-17-# # <source src="//b.robnugen.com/rob/presentations/weekly-alignments/2020/file_mc_file.mp3" type="audio/mpeg">
#-2021-feb-17-# # Your browser does not support this audio content.
#-2021-feb-17-# # </audio>
#-2021-feb-17-# #
#-2021-feb-17-# #
#-2021-feb-17-# # My reality:
#-2021-feb-17-# #
#-2021-feb-17-# # Grab the name, assume it is same for both files, slap on the extensions, and poop it out.
#-2021-feb-17-# #
#-2021-feb-17-# # N.B. WE IGNORE any but the first filename argument
#-2021-feb-17-#
#-2021-feb-17-# echo remember you can
#-2021-feb-17-# echo ssh b.rn 'mkdir -p ~/b.robnugen.com/rob/presentations/weekly-alignments/$THISYEAR'
#-2021-feb-17-#
#-2021-feb-17-#
#-2021-feb-17-# if [ $# -ne 1 ]
#-2021-feb-17-#   then
#-2021-feb-17-#       echo Usage: $0 /path/file_mc_file.mp3 or .ogg         because we only use one file and assume same name for uploading two files
#-2021-feb-17-#       exit
#-2021-feb-17-# fi
#-2021-feb-17-#
#-2021-feb-17-# # constants
#-2021-feb-17-# remote_path="/home/thundergoblin/b.robnugen.com/rob/presentations/weekly-alignments"
#-2021-feb-17-# remote_server="b.rn"
#-2021-feb-17-# real_domain="b.robnugen.com"
#-2021-feb-17-# url_path="${remote_path#*$real_domain}"    # # = remove everything up to and including b.robnugen.com
#-2021-feb-17-#
#-2021-feb-17-# echo "url_path = $url_path"
#-2021-feb-17-#
#-2021-feb-17-# filename="$1"
#-2021-feb-17-# echo "filename = $filename"
#-2021-feb-17-# filename_no_ext="$filename"
#-2021-feb-17-# filename_no_ext=${filename_no_ext%.ogg}    # % = remove .ogg if we sent a .ogg file
#-2021-feb-17-# filename_no_ext=${filename_no_ext%.mp3}    # % = remove .mp3 if we sent a .mp3 file
#-2021-feb-17-# echo "filename_no_ext = $filename_no_ext"  # assumes filename is the same name for both .ogg and .mp3
#-2021-feb-17-#
#-2021-feb-17-# year=$(date +%Y)
#-2021-feb-17-# echo "year = $year"
#-2021-feb-17-# filename_no_ext_no_path=$(basename $filename_no_ext)
#-2021-feb-17-# echo "filename_no_ext = $filename_no_ext"
#-2021-feb-17-#
#-2021-feb-17-# # You don't need these, but they're cool incantations to have available.
#-2021-feb-17-# relative_filepath=$(dirname $filename_no_ext_no_path)
#-2021-feb-17-# absolute_filepath="$( cd "$(dirname "$filename_no_ext_no_path")"; pwd -P )"
#-2021-feb-17-#
#-2021-feb-17-# ssh "$remote_server" "mkdir -p $remote_path/$year"
#-2021-feb-17-#
#-2021-feb-17-# scp "$filename_no_ext.ogg" "$remote_server:$remote_path/$year/"
#-2021-feb-17-# scp "$filename_no_ext.mp3" "$remote_server:$remote_path/$year/"
#-2021-feb-17-#
#-2021-feb-17-#
#-2021-feb-17-# echo ""
#-2021-feb-17-# echo ""
#-2021-feb-17-# echo "<audio controls>"
#-2021-feb-17-# echo "  <source src=\"//$real_domain$url_path/$year/$filename_no_ext_no_path.ogg\" type=\"audio/ogg\">"
#-2021-feb-17-# echo "  <source src=\"//$real_domain$url_path/$year/$filename_no_ext_no_path.mp3\" type=\"audio/mpeg\">"
#-2021-feb-17-# echo "  Your browser does not support this audio content."
#-2021-feb-17-# echo "</audio>"
#-2021-feb-17-# echo ""
#-2021-feb-17-# echo ""
#-2021-feb-17-#
#-2021-feb-17-#
#-2021-feb-17-#
#-2021-feb-17-#
#-2021-feb-17-#
#-2021-feb-17-#
