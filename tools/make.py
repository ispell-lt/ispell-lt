#!/usr/bin/env python2.3
# -*- coding: iso-8859-13 -*-

"""
Pythoninis pakaitalas Makefile'ui -- kad darbui su MySpell žodynu
nereikėtų ispell ar cygwino.

$Id: make.py,v 1.2 2003/11/24 23:51:16 alga Exp $
"""
import os.path
import sys
from sutrauka import sutrauka
from spell import find_ispell_home
from ispell2myspell import AffixTable
from locale import setlocale, LC_ALL

def sortlines(*filenames):
    lines = []
    for file in filenames:
        if not hasattr(file, 'readlines'):
            file = open(file)
        lines += list(file.readlines())
    lines.sort()
    return lines



def main(argv):
    setlocale(LC_ALL, "")

    find_ispell_home()

    print "Konvertuoju afiksus..."
    aff = AffixTable("lietuviu.aff")
    aff.readIn()
    myAff = open("lt_LT.aff", "w")
    aff.printMySpell(myAff)
    myAff.close()

    print "Konvertuoju žodyną..."
    files = ['lietuviu.dict']
    if os.path.exists('lietuviu.privatus'):
        files.append('lietuviu.privatus')
    zodziai = sortlines(*files)
    myDic = open("lt_LT.dic", "w")
    sutrauka(zodziai, myDic)
    myDic.close()

if __name__ == '__main__':
    main(sys.argv)
