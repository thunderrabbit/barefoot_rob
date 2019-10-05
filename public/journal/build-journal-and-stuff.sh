#!/bin/bash

if [ -z "$1" ]
  then
    echo "Usage: $0 <commit message for main site>"
    exit
fi

COMMIT_MESSAGE=$@

echo "Will use \"${COMMIT_MESSAGE}\" as the commit message"

echo "pushing"
git push bitbucket master
git push norigin master &
git push github master &

cd ~/journal-hugo/content/journal
git pull

cd ~/journal-hugo/
git add content/journal/
git commit -m "$COMMIT_MESSAGE"
git push bb master
git push origin master
git push origin netlify

echo "building"
hugo

echo "deploying"
echo "changing directory"
cd public
echo "sleeping"
sleep 2
echo "adding"
git add .
echo "sleeping"
sleep 2
echo "committing"
git commit -m "Published on `date`"
echo "sleeping"
sleep 2
echo "pushing"
git push origin master
