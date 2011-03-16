#!/bin/sh
# usage: updated <file>

cat $1 | sort | uniq -D -t / -W 1
