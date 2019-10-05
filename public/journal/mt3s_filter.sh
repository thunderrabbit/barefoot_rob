#!/bin/bash
# 
# USAGE:
#   $0 [year] |less     # visually confirm correct output
#   $0 [year] |bash     # execute output.  dangerous!
#   
# Warning: 
#   The output of this script is NOT protected against 
#   funny characters in filenames or other bugs/unusual output.
#   That's why this script does NOT change any file!
#   It outputs a guess at the commands to perform the desired change.
#   YOU MUST VISUALLY INSPECT THE OUTPUT BEFORE EXECUTING IT
#  


# set variable values.
# also set values inside is_mt3 and process_files.

# set these values

year=${1:-2018}
mt3_dest_dir=~/mt3/site/content/blog
export mt3_dest_dir

# return value is an exit status
is_mt3() {
  local f="$1"
    
  # set these values
  local num_lines=4
  local string="mt3"

  # grep's exit code tells if we want this file,
  # meaning, has a line that:
  #   starts with "tags"
  #   contains $string
  head -n$num_lines "$f"   \
    |grep ^tags            \
    |grep "$string"        \
    >/dev/null

  return $?;                                # grep's exit code
}
  

# do a thing if file is an mt3 file
process_file() {
  local g="$1"
   
  if is_mt3 "$g"   # need quotes in case filename has whitespace
  then
    local d=`dirname "$g"`
    local mt3_ddd="$mt3_dest_dir/$d"

    # Crude echo command, that does NOT escape anything!
    # Output is very vulnerable to funny chars in filename [;"\/]
    # Need a year/month from the file's subdir, in the dest dir.
    #
    # Test if directory exists.
    # Note during debug, directories will seem to be repeatedly created
    # because they do not yet exist
    if [ ! -d "$mt3_ddd" ]
    then
       echo
       echo mkdir -p \"$mt3_ddd\"
    fi
    echo cp \"$g\"    \"$mt3_ddd\"
  fi
}


# these must be exported, so the bash command in the "find" below
# has access to them.
export -f is_mt3
export -f process_file


echo mkdir -p \"$mt3_dest_dir\"
 

# main()
# only the shell can execute shell functions,
# and so -exec has to run a shell:
find $year -type f -exec bash -c 'process_file {}' \;


