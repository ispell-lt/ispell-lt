#!/bin/sh
# -*- coding: utf-8 -*-
#
## Usage: compare.sh [options] <word/affs-1> <word/affs-2>
##
## Compares two ispell expanded word/aff lists and outputs diff/match info.
##
## Options:
##    -h,  --help          Show this message.
##    -r,  --ref-dict      Reference ispell dictionary. Default: REF_DICT env.
##    -a,  --alt-dict      Alternate ispell dictionary for <word/affs-2>
##                         expansion if given. Default: ALT_DICT env. or
##                         REF_DICT (--ref-dict) if ALT_DICT (--alt-dict) is
##                         not defined (specified).
##    -q, --brief          Report only then lists differ.
##    -d, --diff           Unified diff output.
##    -m, --comm           Original comm output.
##                         Default (custom) output (-12c):
##    -1,  --uniq-1        Output unique words of <word/affs-1> list.
##    -2,  --uniq-2        Output unique words of <word/affs-2> list.
##    -c,  --common        Output common words in both word/affs lists.
#
# Author: Laimonas Vėbra, 2016

TMPDIR=$(mktemp -d)

trap 'rm -rf "$TMPDIR"' EXIT


usage() {
    head -n 30 "$0" | grep "^##" | cut -c 4-
}

function OUT_U1() {
    echo "# Unique words of '$SRC_1' <=> '$SRC_2'"
    comm -23 "$F_GEN1" "$F_GEN2"
    echo
}

function OUT_U2() {
    echo "# Unique words of '$SRC_2' <=> '$SRC_1'"
    comm -13 "$F_GEN1" "$F_GEN2"
    echo
}

function OUT_CM() {
    echo "# Common words of '$SRC_1' and '$SRC_2'"
    comm -12 "$F_GEN1" "$F_GEN2"
}

function OUT_COMM() {
    comm "$F_GEN1" "$F_GEN2"
}

function OUT_DIFF() {
    diff $1 -U 10000 --label "$SRC_1" --label "$SRC_2" "$F_GEN1" "$F_GEN2"
}

function tmpfile() {
    mktemp -p "$TMPDIR"
}



##############################
## Argument parsing         ##
##############################

# The quotes around $@ are essential.
_GETOPTS=$(getopt \
               -o "hr:a:qdm12c" \
               --long "help,ref-dict:,alt-dict:,\
               brief,diff,comm,uniq-1,uniq-2,common" \
               -n "$0" -- "$@")

if [ $? != 0 ] ; then
    usage
    exit 1
fi

# The quotes around $GETOPTS are essential.
eval set -- "$_GETOPTS"

while true ; do
    case "$1" in
        -h|--help)
            usage
            exit
            ;;
        -r|--ref-dict)
            case "$2" in
                "")
                    #echo "Option x, no argument"
                    shift 2
                    ;;
                *)
                    #echo "Option x, argument '$2'"
                    REF_DICT="$2"
                    shift 2
                    ;;
            esac
            ;;
        -a|--alt-dict)
            case "$2" in
                "")
                    shift 2
                    ;;
                *)
                    ALT_DICT="$2"
                    shift 2
                    ;;
            esac
            ;;
        -q|--brief)
            OPT_BRIEF=-q
            shift
            ;;
        -d|--diff)
            OUT_DIFF=true
            shift
            ;;
        -m|--comm)
            OUT_COMM=true
            shift
            ;;
        -1|--uniq-1)
            OPT_UNIQ_1=true
            shift
            ;;
        -2|--uniq-2)
            OPT_UNIQ_2=true
            shift
            ;;
        -c|--common)
            OPT_COMMON=true
            shift
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Internal error!"
            exit 1
            ;;
    esac
done


# Test word/aff args
ARGC=("$#")
if [ $ARGC -lt 2 ]; then
    echo "Two word/aff strings must be given."
    usage
    exit 2
else
    W1="$1"
    W2="$2"
fi

if [ -z "$REF_DICT" ]; then
    echo "Unknown ref. dictionary. Set REF_DICT env. or specify --ref-dict."
    exit 3
fi

if [ -z "$ALT_DICT" ]; then
    ALT_DICT="$REF_DICT"
fi

SRC_1="$W1 ($REF_DICT)"
SRC_2="$W2 ($ALT_DICT)"

F_GEN1=$(tmpfile)
F_GEN2=$(tmpfile)

WL=$(echo "$W1" | ispell -d "$REF_DICT" -e)
[ $? -ne 0 ] && exit $?
echo "$WL" | tr ' ' '\n' | sort > "$F_GEN1"

WL=$(echo "$W2" | ispell -d "$ALT_DICT" -e)
[ $? -ne 0 ] && exit $?
echo "$WL" | tr ' ' '\n' | sort > "$F_GEN2"

if [ -n "$OPT_BRIEF" ]; then
    OUT_DIFF $OPT_BRIEF
    exit $?
fi

if [[ -n "$OPT_UNIQ_1" || -n "$OPT_UNIQ_2" || -n "$OPT_COMMON" ]]; then
    [ -n "$OPT_UNIQ_1" ] && OUT_U1
    [ -n "$OPT_UNIQ_2" ] && OUT_U2
    [ -n "$OPT_COMMON" ] && OUT_CM
elif [ -n "$OUT_DIFF" ]; then
    OUT_DIFF
elif [ -n "$OUT_COMM" ]; then
    OUT_COMM
else
    OUT_U1
    OUT_U2
    OUT_CM
fi
