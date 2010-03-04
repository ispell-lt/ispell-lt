#!/usr/bin/python
# -*- coding: iso-8859-13 -*-
"""
ispell2myspell.py -- Converts an affix table from ispell format
to OpenOffice's MySpell format.

Copyright (C) 2002 by Albertas Agejevas

Usage:  ./ispell2myspell.py lietuviu.aff > lt_LT.aff

"""

import sys
from StringIO import StringIO


inputenc = 'ISO8859-13'
# Prieš persijungiant prie UTF-8, reikia Makefile'e pataisyti MySpell ir
# aspell taisykles, kad naudotų UTF-8 žodynus.
#outputenc = 'UTF-8'
outputenc = 'ISO8859-13'


class AffixTable:

    def __init__(self, file):
        self._in = open(file, "r")
        self.flags = {}
        self.state = None
        self.flag = None
        self.combine = None

    def getTokens(self):
        "Returns a list of space separated tokens from a single line"
        while 1:
            line = self._in.readline()
            self.line = line = unicode(line, inputenc)
            if line == "":
                return None  # End of file
            hash = line.find("#")
            if hash != -1:
                line = self.line[:hash]
            result = line.split()
            if result != []:
                return result

    def readIn(self):
        "A state machine that reads in the rules"
        while 1:
            tokens = self.getTokens()
            if tokens is None:
                return

            if tokens[0] == 'prefixes':
                self.state = 'P'
                self.flag = None
                continue

            if tokens[0] == 'suffixes':
                self.state = 'S'
                self.flag = None
                continue

            if not (self.state == 'S' or self.state == 'P'):
                continue

            if tokens[0] == 'flag':
                opt = ''.join(tokens[1:])
                i = 0
                self.combine = None
                if opt[i] == "*":
                    self.combine = 'Y'
                    i += 1
                if opt[i] == "~":
                    i += 1
                self.flag = opt[i]

                self.flags[self.state + self.flag] = {'combine': self.combine,
                                                      'rules': []}
                continue

            for i in range(len(tokens)):
                if tokens[i] == '>':
                    break
                if len(tokens[i]) > 1 and tokens[i][0] != '[':
                    tokens[i] = '[' + tokens[i] + ']'

                # Strangely enough, zero means empty string in MySpell *.aff
                context = cut = paste = 0
                rule = ''.join(tokens)
                sep = rule.index('>')
                context = rule[:sep].lower()
                sep += 1
                if rule[sep] == '-':
                    comma = rule.index(',')
                    cut = rule[sep+1:comma].lower()
                    sep = comma + 1
                paste = rule[sep:].lower()
                if paste == '""':
                    paste = 0

                rule = (context, cut, paste)

                rules = self.flags[self.state + self.flag]['rules']

                # Add only if it's not yet there
                try:
                    rules.index(rule)
                except:
                    rules.append(rule)

    def printMySpell(self, file):
        """Prints the affix table in MySpell format.

        The charset and the character probabilities are hardcoded for
        Lithuanian."""

        print >> file, "SET %s" % outputenc
        print >> file, (u"TRY iastnokreuldv\u0117mgpj\u0161by\u017e\u016bczf"
                        u"\u010dh\u0105\u012f\u0173\u0119wxq")
        print >> file

        for flag in self.flags.keys():

            if flag[0] == 'P':
                fx = 'PFX'
            else:
                fx = 'SFX'

            print >> file, fx, flag[1],

            if self.flags[flag]['combine']:
                print >> file, 'Y',
            else:
                print >> file, 'N',

            print >> file, len(self.flags[flag]['rules'])

            for context, cut, paste in self.flags[flag]['rules']:
                print >> file, u"%s %s %-7s %-15s %s" % (fx, flag[1], cut,
                                                  paste, context)
            print >> file


def main():

    if len(sys.argv) > 1:
        file = sys.argv[1]
    else:
        print __doc__
        sys.exit(1)

    converter = AffixTable(file)
    converter.readIn()
    buf = StringIO()
    converter.printMySpell(buf)
    sys.stdout.write(buf.getvalue().encode(outputenc))


if __name__ == '__main__':
    main()

