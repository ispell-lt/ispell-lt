#!/bin/bash

VERSION="1.0"
TAG="RELEASE_1_0"
MYSPELLDIR="lt_LT-$VERSION"
ISPELLDIR="ispell-lt-$VERSION"
TAG="RELEASE_1_0"

#make

#mkdir $MYSPELLDIR
#cp lt_LT.dic lt_LT.aff README.EN  INSTRUKCIJOS.txt $MYSPELLDIR
#echo "DICT lt LT lt_LT" > $MYSPELLDIR/dictionary.lst
#zip -r lt_LT.zip $MYSPELLDIR
#mv lt_LT.zip $MYSPELLDIR.zip
#rm -rf $MYSPELLDIR

#cvs -d :ext:sraige.mif.vu.lt:/var/lib/cvs co -r $TAG -d $ISPELLDIR ispell-lt
tar zcvf $ISPELLDIR.tar.gz $ISPELLDIR
#rm -rf $ISPELLDIR