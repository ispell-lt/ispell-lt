#!/bin/sh
# syntax: guess <word>

ISPELL=ispell
DICT="-d lietuviu"

for i in `echo $1 | $ISPELL $DICT -c`; do
    echo "** $i"
    echo $i | $ISPELL $DICT -e | fmt | head
done
