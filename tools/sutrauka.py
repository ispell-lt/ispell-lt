#!/usr/bin/env python
# -*- coding: iso-8859-13 -*-
"""
Sutraukia skirtingus afiksus prie vieno žodžio:
baigtis/D
baigtis/T  ----> baigtis/DT

Be šito MySpell varikliukas pamiršta vieną iš formų.

Naudojimas panašus kaip cat programos: stdin arba failų vardai.

$Id: sutrauka.py,v 1.5 2005/01/03 16:22:10 kebil Exp $
"""
from sets import Set
import fileinput
import sys
from locale import setlocale, getdefaultlocale, LC_COLLATE, strxfrm

def sutrauka(lines, outfile=sys.stdout, myspell=True):
    words = {}

    try:
        setlocale(LC_COLLATE, getdefaultlocale())
    except:
        print >> sys.stderr, "Could not set locale"

    i=0
    for line in lines:
        i += 1
        if not i % 5000:
            sys.stderr.write(".")
            sys.stderr.flush()
        line = line.strip()
        line = line.split("#")[0]
        if not line:
            continue
        sp = line.split("/")
        word = sp[0]
        if len(sp) > 1:
            flags = Set(sp[1])
        else:
            flags = Set()

        if word not in words:
            words[word] = flags
        else:
            words[word].update(flags)

    sys.stderr.write("\n")
    i = 0
    prefcount = 0
    for word in words.keys():
        i += 1
        if not i % 5000:
            sys.stderr.write(".")
            sys.stderr.flush()
        for flag, pref in priesdeliai:
            if word.startswith(pref):
                rd = word[len(pref):]
                rd2 = None
                if pref.endswith("si"):
                    rd2 = word[len(pref)-2:]
                if (word in words and rd in words and
                    rd2 not in words and words[word] <= words[rd]
                    and Set("TYEPU") & words[word]):
                    words[rd].update(words[word])
                    words[rd].add(flag)
                    del words[word]
                    prefcount += 1

    print >> sys.stderr
    #print >> sys.stderr, prefcount, "sutraukimai"

    rez = []
    for word, flags in words.items():
        if flags:
            f = list(flags)
            f.sort()
            end = "/" + "".join(f)
        else:
            end = ""
        rez.append((strxfrm(word), word + end))
    rez.sort()

    if myspell:
        print >> outfile, len(rez)

    for word in rez:
        print >> outfile, word[1]

priesdeliai = (
    ("a", "ap"),
    ("b", "at"),
    ("c", "į"),
    ("d", "iš"),
    ("e", "nu"),
    ("f", "pa"),
    ("g", "par"),
    ("h", "per"),
    ("i", "pra"),
    ("j", "pri"),
    ("k", "su"),
    ("l", "už"),
    ("m", "apsi"),
    ("n", "atsi"),
    ("o", "įsi"),
    ("p", "išsi"),
    ("q", "nusi"),
    ("r", "pasi"),
    ("s", "parsi"),
    ("t", "persi"),
    ("u", "prasi"),
    ("v", "prisi"),
    ("w", "susi"),
    ("x", "užsi"),
    )


if __name__ == "__main__":
    sutrauka(fileinput.input(), myspell=False)
