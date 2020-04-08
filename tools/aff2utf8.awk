#!/bin/gawk -f
# -*- coding: utf-8 -*-
#
# Converts lithuanian (latin7) ispell affix file to utf-8.
#
# Copyright (c) 2016, Laimonas Vėbra
# All rights reserved.
#
# This program is licensed under the Simplified BSD License.
# See <http://www.opensource.org/licenses/bsd-license>
#
# Usage: gawk [-v PY_ICONV=/path/to/iconv.py] -f aff2utf8.awk <lietuviu.aff>

function conv(s) {
    if (s == "")
	return ""
    print s |& converter
    converter |& getline res
    return res
}

function exists(f) {
    # Suppress stdout of system(): we certainly don't want it on our stdout
    return (system("which " f " > /dev/null") == 0)
}

BEGIN {
    IGNORECASE = 1
   
    # Fallback converter if we don't find suitable one or can't use iconv.
    # (set PY_ICONV env. or assign var.: -v PY_ICONV=abs_or_rel/path/to/iconv.py)
    if (!PY_ICONV)
        PY_ICONV = ENVIRON["PY_ICONV"]
   
    if (index(ENVIRON["OS"], "windows") > 0) {
        if (exists("iconv")) {
            converter = "iconv -f ISO-8859-13 -t UTF8"
        }
    } else {
	# On linux/posix iconv (fread) blocks until EOF.
        # (two-way IPC with iconv coprocess won't work)
        # Maybe we have `luit' (from x11-utils, etc)?
        if (exists("luit")) {
            converter = "luit -c -encoding ISO-8859-13"
        }
    }

    if (!converter) {
        if (PY_ICONV) {
            converter = "python3 -u " PY_ICONV " -f ISO-8859-13 -t UTF-8"
        } else {
            print "No suitable converter found and PY_ICONV is not set."\
                > "/dev/stderr"
            exit 1
        }
    }
    
    #PROCINFO[iconv, "pty"] = 1
}

FNR == 1 { 
    ("sed -ne 's/altstringtype\\(.*\\)/\\1/p' " FILENAME) | getline val
    alt_fmt = val
}

# swap (def and alt) formatter values
/^\s*defstringtype/{
    match($0, /defstringtype(.*)/, m); def_fmt = m[1]
    print "defstringtype", alt_fmt
    next
}
/^\s*altstringtype/{
    print "altstringtype", def_fmt
    next
}

# swap altstringchars (utf-8 <=> latin7)
match($0, /^([#[:space:]]*altstringchar\s+)(\S+)\s+(\S+)(.*)/, m) {
    print m[1], m[3], m[2], conv(m[4])
    next
}

# convert to utf-8 all other lines
{
    print conv($0)
}

END {
    close(converter)
}


