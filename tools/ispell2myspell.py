#!/usr/bin/python
"""
ispell2myspell.py -- Converts an affix table from ispell format
to OpenOffice's MySpell format.

Copyright (C) 2002 by Albertas Agejevas 

Usage:  ./ispell2myspell.py lietuviu.aff > lt_LT.aff

$Id: ispell2myspell.py,v 1.1 2002/09/02 23:39:59 alga Exp $
"""

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
            self.line = line = self._in.readline()
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
                rule = (context, cut, paste)

                rules = self.flags[self.state + self.flag]['rules']

                # Add only if it's not yet there
                try:
                    rules.index(rule)
                except:
                    rules.append(rule)

    def printMySpell(self):
        """Prints the affix table in MySpell format.

        The charset and the character probabilities are hardcoded for
        Lithuanian."""

        print "SET ISO8859-13"
        print "TRY iastnokreuldv�mgpj�by��czf�h"\
              "����wxq"
#        print "#%s %s %-7s %-15s %-10s" % ('AFF', 'F', 'cut', 'paste', 'context')
        for flag in self.flags.keys():
            
            if flag[0] == 'P':
                print 'PFX',
            else:
                print 'SFX',
            print flag[1],

            if self.flags[flag]['combine']:
                print 'Y',
            else:
                print 'N',

            print len(self.flags[flag]['rules'])

            for context, cut, paste in self.flags[flag]['rules']:
                if flag[0] == 'P':
                    fx = 'PFX'
                else:
                    fx = 'SFX'

                print "%s %s %-7s %-15s %-10s" % (fx, flag[1], cut,
                                                  paste, context)
            print
            

if __name__ == '__main__':
    from locale import *
    setlocale(LC_ALL, "")

    import sys
    if len(sys.argv) > 1:
        file = sys.argv[1]
    else:
        file = '../lietuviu.aff'
    converter = AffixTable(file)
    converter.readIn()
    converter.printMySpell()