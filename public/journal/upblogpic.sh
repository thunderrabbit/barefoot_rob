#!/bin/bash
# This is designed to make it easier to copy images from finder to b.robnugen.com

echo remember you can
echo ssh b.rn 'mkdir -p ~/b.robnugen.com/blog/2019'

scp $@ b.rn:b.robnugen.com/blog/2019


