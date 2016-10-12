#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Copyright (c) 2016, Laimonas Vėbra
# All rights reserved.
#
# This program is licensed under the Simplified BSD License.
# See <http://www.opensource.org/licenses/bsd-license>
#
"""Converts text from one encoding to another encoding.

Poor man's iconv. Does not buffer/block stdin on posix/linux, so
line-based two-way IPC (with a coprocess) is possible, unlike
the original iconv (fread), which blocks until EOF.
"""

import sys
import getopt
import locale

__version__ = '1.0a'
__program__ = 'iconv.py'

__usage_short = (
"""Usage:
  %s [OPTION...] [-f ENCODING] [-t ENCODING] [INPUTFILE...]
""") % __program__

__usage_full = (__usage_short +
"""
Converts text from one encoding to another encoding.

Options controlling the input and output format:
  -f ENCODING, --from-code=ENCODING
                              the encoding of the input
  -t ENCODING, --to-code=ENCODING
                              the encoding of the output
Options controlling conversion problems:
  -c                          discard unconvertible characters

Informative output:
  --help                      display this help and exit
  --version                   output version information and exit
""")


try:
    opts, files = getopt.getopt(sys.argv[1:],
                        "cf:t:",
                        ["help", "from-code", "to-code", "version"])
except getopt.GetoptError as e:
    print(e)
    print(__usage_short)
    sys.exit(2)

errors='strict'
src_enc = dst_enc = locale.getpreferredencoding()

for opt, arg in opts:
    if opt in ("--help"):
        print(__usage_full)
        sys.exit()
    elif opt in ("--version"):
        print(__program__, __version__)
        sys.exit()
    elif opt in ("-c"):
        errors='ignore'
    elif opt in ("-f", "--from-code"):
        src_enc = arg
    elif opt in ("-t", "--to-code"):
        dst_enc = arg
    else:
        assert False, "unhandled option"

if sys.version_info >= (3,1):
    sys.stdin = sys.stdin.detach()
    sys.stdout = sys.stdout.detach()

def convert(line):
    return line.decode(src_enc, errors).encode(dst_enc, errors)

if files:
    for f in files:
        f = open(f, mode='rb')
        for line in f:
            sys.stdout.write(convert(line))
        f.close()
else:
    while True:
        line = sys.stdin.readline()
        if not line:
            break
        sys.stdout.write(convert(line))
