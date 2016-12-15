#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Copyright (c) 2016, Laimonas Vėbra
# All rights reserved.
#
# This program is licensed under the Simplified BSD License.
# See <http://www.opensource.org/licenses/bsd-license>
#
# Based on original work of Albertas Agejevas, (c) 2002
"""
Converts ispell affix file to OpenOffice's MySpell format. 
See <https://www.openoffice.org/lingucomponent/affix.readme>
"""

import re
import sys
import getopt
import codecs

__version__ = '1.0a'
__program__ = 'ispell2myspell.py'

__usage_short = (
"""Usage:
  %s [OPTION...] ISPELL_AFF_FILE > MYSPELL_AFF_FILE
""") % __program__

__usage_full = (__usage_short +
"""
Converts ispell affix file to OpenOffice's MySpell format.

Options:
  -h, --help                  Display this help and exit
  -c MYCONFIG, --cfg=MYCONFIG
                              MySpell aff file without affix table.
                              (this file is included in MYSPELL_AFF_FILE)
  -d ENCODING, --dec=ENCODING
                              the encoding of the input (ISPELL_AFF_FILE).
                              (decode input from ENCODING to Unicode)
  -e ENCODING, --enc=ENCODING
                              the encoding of the output (MYSPELL_AFF_FILE).
                              (encode output from Unicode to ENCODING)  
  -s, --sort                  
                              Sort affix flags. Default: original order.

  -v, --version               Output version information and exit.

Notes:
  MYCONFIG must be in utf-8 (it's converted to --enc).
  
  Input encoding can be specified in ISPELL_AFF_FILE comments according
  to PEP263 spec., e.g.:  # -*- coding: <encoding> -*-

  --dec overrides ISPELL_AFF_FILE encoding.

""")

            

class AffixTable:
    
    def __init__(self, ispell_aff_file, src_enc):
        self.affs = {}

        self.type_re = re.compile(r"(prefixes|suffixes)", re.I)
        self.flag_re = re.compile(r"flag([*~]?)(.):", re.I)
        self.rule_re = re.compile(r"(.+?)>(?:-(.+?),)?(.+)", re.I)

        self._in = codecs.open(ispell_aff_file, "r", src_enc)
        self._read_in()
        
    def _get_line(self):
        """
        Gets and returns next non-empty lowercased line (with comments stripped
        and whitespaces removed) or "" if EOF.
        """
        line = None
        while not line:
            line = self._in.readline()
            self.raw_line = line
            if line == "": # EOF
                break
            line = self._format(line)
        self.line = line
        return self.line

    def _format(self, s):
        "Removes spaces, comments (#.*) from a string."
        return re.sub(r"(#.*)|(\s+)", '', s)


    def _read_in(self):
        "Reads in and parses affix file"
        rules = []
        atype = None

        def _nul(s):
            if s:
                return s.strip("\"'") or 0
            return 0
            
        while self._get_line():

            m = self.type_re.search(self.line)
            if m:
                atype = m.group(1)
                if self.affs.get(atype) is None:
                    self.affs[atype] = {}
                    self.affs[atype]['flags'] = []
                continue
            if not atype:
                continue

            m = self.flag_re.search(self.line)
            if m:
                rules = []
                opt, flag = m.groups()
                # original affix flags order 
                self.affs[atype]['flags'].append(flag)
                self.affs[atype][flag] = {
                    'rules': rules,
                    'combine': opt == '*',
                    'compound': opt == '~',
                    }
                continue

            if '>' in self.line:
                cond, repl = self.raw_line.lower().split('>', 1)
                # wrap non-separated chars in [] (alternatives in ispell)
                cond = re.sub(r"\s*([^\[\]\s]{2,})\s", r"[\1]", cond)
                m = self.rule_re.search(self._format(cond + '>' + repl))
                if m:
                    (cond, strip, add) = m.groups()
                    # null/empty string for myspell aff strip/add parts is 0
                    rule = (_nul(strip), _nul(add), cond)
                    if rule not in rules:
                        rules.append(rule)

    def dump_myspell_aff(self, myspell_cfg_file=None, dst_enc=None, sort=False):
        "Dumps MySpell affix table to stdout."

        out = sys.stdout
        if sys.version_info >= (3,0):
            out = sys.stdout.buffer
        out = codecs.getwriter(dst_enc)(out)

        ml = []
        if myspell_cfg_file:
            my_aff = codecs.open(myspell_cfg_file, "r", "utf-8")
            for line in my_aff:
                if re.match(r'^\s*#|SET', line, re.I):
                    continue
                ml.append(line)
            my_aff.close()
                    
        
        out.write("SET %s\n" % dst_enc.upper())

        # dump base myspell config (aff) file
        out.writelines(ml)

        # dump myspell affix table
        for (_atype, atype) in [('prefixes', 'PFX'), ('suffixes', 'SFX')]:

            flags = self.affs[_atype]['flags']
            if sort:
                flags.sort()

            for flag in flags:
                aff = self.affs[_atype][flag]
                # affix header
                out.write("\n%s %s %s %d\n" %
                              (atype, flag, ("N", "Y")[aff['combine']],
                                   len(aff['rules'])))
                # affix rules
                for (strip, add, cond) in aff['rules']:
                    out.write("%s %s %-7s %-15s %s\n" %
                                  (atype, flag, strip, add, cond))

def _encoding_name(enc):
    codecs.lookup(enc)
    try:
        enc = codecs.lookup(enc).name
    except:
        pass
    return enc

def main():
    try:
        opts, files = getopt.getopt(sys.argv[1:],
                        "hc:d:e:sv",
                        ["help", "cfg=", "dec=", "enc=", "sort", "version"])
    except getopt.GetoptError:
        print(sys.exc_info()[1])
        print(__usage_short)
        sys.exit(2)

    sort_aff = False
    src_enc = dst_enc = None
    myspell_cfg_file =  None
    
    for opt, arg in opts:
        if opt in ("-h, --help"):
            print(__usage_full)
            sys.exit()
        elif opt in ("-v, --version"):
            print(__program__, __version__)
            sys.exit()
        elif opt in ("-c, --cfg"):
            myspell_cfg_file = arg
        elif opt in ("-d", "--dec"):
            src_enc = arg
        elif opt in ("-e", "--enc"):
            dst_enc = arg
        elif opt in ("-s", "--sort"):
            sort_aff = True
        else:
            assert False, "unhandled option"


    if len(files) >= 1:
        ispell_aff_file = files[0]
    else:
        print("Missing input argument (ISPELL_AFF_FILE).")
        print(__usage_short)
        sys.exit(1)

    # coding lookup (PEP263)
    if not src_enc:
        f = codecs.open(ispell_aff_file, "r", 'ascii', 'ignore')
        for n in range(2):
            m = re.match(r"^\s*#.*?coding[:=]\s*([-_.a-zA-Z0-9]+)",
                             f.readline(), re.I)
            if m:
                src_enc = m.group(1)
                break
        f.close()
        
    if src_enc:
        src_enc = _encoding_name(src_enc)
    else:
        print("Unknown ispell aff file encoding: "
                  "missing --enc arg and not specified in file.")
        sys.exit(3)
                
    if dst_enc:
        dst_enc = _encoding_name(dst_enc)
    else:
        dst_enc = src_enc
        sys.stderr.write("Output (myspell aff) encoding not specified; "
                             "assuming the same as input '%s'.\n" % dst_enc) 
        
    conv = AffixTable(ispell_aff_file, src_enc)
    conv.dump_myspell_aff(myspell_cfg_file, dst_enc, sort_aff)


if __name__ == '__main__':
    main()
