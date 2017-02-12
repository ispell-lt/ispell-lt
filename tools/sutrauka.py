#!/usr/bin/env python
# -*- coding: iso-8859-13 -*-
#
# Autorius: Albertas Agejevas, 2003
# Koregavo: Laimonas Vėbra, 2010-2016
#
# Veikia su Python v2.3+, v3.0+
#
"""
ispell-lt projekto/žodyno įrankis.
Suglaudžia/suskliaudžia pasikartojančius žodžius (suliejant jų afiksų
žymas, jei tokių turi), o taip pat priešdėlinius veiksmažodžius, pvz.:
    pa|eina, nu|eina, at|eina, ... -> eina/bef...

ir išveda surikiuotų žodžių sąrašą, tinkamą galutiniam žodynui.

Žodžiai skliaudžiami tik suderinamose (kalbos dalių) grupėse (dabar
tai: veiksmažodžiai, būdvardžiai ir likę).

Naudojimas:
    ./sutrauka žodynas.txt > sutraukta.txt
    cat žodynas.txt | ./sutrauka > sutraukta.txt

"""
import os
import sys
import locale
import fileinput
from itertools import chain


enc = "ISO8859-13"
loc = "lt_LT" + "." + enc

# Windows setlocale() nepriima POSIX lokalės
if os.name is "nt":
    loc = "Lithuanian"

_setlocale_failed = False
try:
    locale.setlocale(locale.LC_COLLATE, loc)
except:
    _setlocale_failed = True
    sys.stderr.write(
        "Could not set locale '%s', default: '%s'. "
        "Won't be able to sort dictionary words correctly.\n"
        % (loc, locale.getdefaultlocale()))

# Nuo v2.4 set tipai built-in, o sets modulis deprecated nuo v2.6
if sys.version_info < (2, 4):
    from sets import Set
    set = Set

# Py2 ir Py3 dict iteratorių suderinimas
if sys.version_info < (3,):
    items = dict.iteritems
else:
    items = dict.items


# global stat vars: constringed words and saved bytes count
c_wcount = 0
c_bsaved = 0

prefixes = (
    ("a", "ap"), ("a", "api"),
    ("b", "at"), ("b", "ati"),
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



def _stats(word, wflags, swflags, pverb=False):
    global c_wcount, c_bsaved
    # Statistika (sutaupyta žodžių ir vietos).
    #
    # Kiek sutaupoma vietos (bcount) suskliaudžiant žodį:
    # žodžio ilgis + bendrų žymų kiekis + _papildomai_ 1 arba 2 baitai,
    # priklausomai nuo varianto:
    #   - kai žodis be žymų arba priešd. veiksmažodis (pverb): '\n' (1)
    #   - visais kitais atvejais sutaupoma: '/', '\n' (2)
    c_wcount += 1

    if (pverb or not wflags):
        le = 2
    else:
        le = 1

    c_bsaved += len(word) + len(wflags & swflags) + le

def _msg(s, *args):
    if args:
        s = s % args
    sys.stderr.write(s)
    sys.stderr.flush()

def _progress(i, step=5000):
    if (i % step == 0):
        _msg('.')

def _sort(wlist):
    if _setlocale_failed:
        wlist.sort()
    elif sys.version_info < (2, 4):
        wlist.sort(locale.strcoll)
    elif sys.version_info < (3,):
        wlist.sort(cmp=locale.strcoll)
    elif sys.version_info >= (3,):
        from functools import cmp_to_key
        wlist.sort(key=cmp_to_key(locale.strcoll))


def sutrauka(lines, outfile=sys.stdout, myspell=True):
    i = 0
    adjes = {}
    verbs = {}
    words = {}
    wcount = 0

    # Skliaudžiamųjų žodžių klasės (pagal afiksų žymų rinkinius):
    vflags = set("TYEPRO")  # verb flags
    aflags = set("AB")      # adjective flags

    _msg("\n--- %s %s\nReading ", sys.argv[0], '-' * (55 - len(sys.argv[0])))

    for line in lines:
        _progress(lines.lineno())

        # Ignoruojamos tuščios ir komentaro eilutės.
        line = line.split("#")[0]
        line = line.strip()
        if not line:
            continue

        wcount += 1

        # Eilutė skeliama į žodį ir jo žymų rinkinį.
        sp = line.split("/")
        word = sp[0]
        if len(sp) > 1:
            wflags = set(sp[1])
        else:
            wflags = set()

        # Veiksmažodžiai ir būdvardžiai į atskirus dict.
        if vflags & wflags:
            d = verbs
        elif aflags & wflags:
            d = adjes
        else:
            d = words

        # Žodis pridedamas į dict arba jei jau yra -- suliejamos žymos
        swflags = d.get(word) # stored word flags
        if swflags is not None:
            _stats(word, wflags, swflags)
            swflags.update(wflags)
        else:
            d[word] = wflags


    _msg("\nProcessing ")

    # Priešdėlinių veiksmažodžių suskliaudimas.
    # XXX: dėl skirtingo py2 ir py3 dict vidinio eiliškumo, skiriasi ir
    # suglaudinimo rezultatas.
    # Neišspręsta problema: priklausomai nuo to, kurie žodžiai ir kokiu
    # eiliškumu išrenkami, skliaudžiant sudurtinių priešd. veiksmažodžius,
    # iš dict pašalinamas skliaudžiamasis žodis ir tai vėliau nebeleidžia
    # suskliausti kitų žodžių.
    # Pvz.:
    #    su|panašinti -> pa|našinti/k -> našinti/fk
    # vs
    #    pa|našinti -> našinti/f;
    #    (vėliau 'supanašinti' nebesuskliaudžiamas, nes nebėra 'panašinti')
    #
    # Norint vieningo rezultato su py2/py3, reikia surikiuoti sąrašą:
    #    lverbs = list(verbs); lverbs.sort()
    # nors problema išlieka: algoritmas ne visai korektiškai suskliaudžia
    # sudurtinių priešdėlių veiksmažodžius.
    for word in list(verbs):
        i += 1
        _progress(i)

        # Žodžio afiksų žymų rinkinys.
        wflags = verbs[word]

        # Kiekvienam žodyno žodžiui derinami/tikrinami visi priešdėliai.
        for pflag, pref in prefixes:

            if word.startswith(pref):
                # Jei pref sangrąžinis priešdėlis, tai žodis atmetus paprastąjį
                # (nesangrąžinį) priešdėlį, pvz.: iš{si}|urbia -> siurbia.
                # Kai toks žodis yra žodyne, tai situacija netriviali, nes
                # žodyne yra trys žodžio formos: su priešdėliu, be priešdėlio
                # ir be sangrąžinio priešdėlio.  Tampa nebeaišku kokį priešdėlį
                # (sangrąžinį ar ne) ir kokiam žodžiui pritaikyti; tokių
                # žodžių savaime suskliausti neįmanoma, pvz.:
                #     iš{si}|urbia, siurbia, urbia (iš|siurbia ar išsi|urbia?)
                #     at{si}|joja, sijoja, joja;   (at|sijoja ar atsi|joja?)
                #
                # Kol kas tokie žodžiai neskliaudžiami.
                if pref.endswith("si"):
                    # word without reflexive prefix part
                    wrp_word = word[len(pref)-2:]
                else:
                    wrp_word = None


                # Žodis be priešdėlio, pvz.: per|šoko -> šoko.
                # (word without prefix)
                wp_word = word[len(pref):]
                wp_wflags = verbs.get(wp_word)

                if (wp_wflags is not None and wrp_word not in verbs):
                    # Skliaudžiant priešdėlinius veiksmažodžius su /N /S /X
                    # afiksų žymomis, dėl ispell apribojimo jungiant afiksus,
                    # prarandamos kelios priešdėlinės formos, pvz:
                    #
                    #   pavartyti/X  >  te|pa|vartyti, tebe|pa|vartyti,
                    #                   be|pa|vartyti, ...
                    # vs
                    #    vartyti/Xf  >  tevartyti, tebevartyti, bevartyti, ...
                    #
                    # Susitaikius su vykstančiu priešdėlinių formų:
                    #  [/N /S /X afiksai] {priešdėlis} žodis
                    # praradimu, žodynas suglaudinamas virš 50 kB.
                    #
                    # ARBA atvirkščiai: siekiant, kad nebūtų praradimų, kaip
                    # tik nereikėtų tokių žodžių (jei priešdėlinis žodis turi
                    # /S /X /N žymas) glaudinti.
                    _stats(word, wflags, wp_wflags, pverb=True)

                    # Suliejamos afiksų žymos ir pridedama priešdėlio žyma.
                    wp_wflags.update(wflags)
                    wp_wflags.add(pflag)

                    # Žodis sukliaustas (prie šakninio žodžio sulietos
                    # žymos, pridėta priešdėlio afikso žyma).  Pašaliname
                    # priešdėlinį žodį iš 'verbs' dict ir baigiame
                    # priešdėlių ciklą, nes priešdėliai unikalūs ir žodžio
                    # pradžia nebegali sutapti su jokiu kitu priešdėliu.
                    del verbs[word]
                    break

    # beafiksinių žodžių pašalinimas, jei jie yra kitose afiksinių klasėse
    for word, flags in items(words.copy()):
        if (not flags and (word in verbs or word in adjes)):
            _stats(word, flags, set())
            # _msg("Deleting %s\n", word)
            del words[word]
    
    wlist = []
    NS = set('NS')
    for word, flags in chain(items(words), items(verbs), items(adjes)):
        if flags:
            # /S perdengia /N, todėl abiejų nereikia
            if NS < flags:
                flags.remove('N')
            fl = list(flags)
            fl.sort()
            word += "/" + "".join(fl)

        wlist.append(word + '\n')

    _sort(wlist)

    _msg(" done.\nWords before: %d, words after: %d.\n"
            "(words constringed: %d, bytes saved: %d)\n%s\n",
             wcount, len(wlist), c_wcount, c_bsaved, '-' * 60)

    # myspell'o žodyno pradžioje -- žodžių kiekis.
    if myspell:
        outfile.write(len(wlist) + '\n')

    outfile.writelines(wlist)



if __name__ == "__main__":
    outfile = sys.stdout
    # Nuo v2.5+ fileinput galima nurodyti openhook'ą (dekodavimas iš
    # norimos koduotės). Aktualu tik py3 (py2 dirba su byte strings;
    # perkodavimas į unikodą nebūtinas), tačiau openhook'as neveikia
    # su stdin.
    if sys.version_info >= (3,):
        import io
        if not sys.argv[1:]:
            # jei nėra argumentų, tai duomenys iš stdin
            sys.stdin = io.TextIOWrapper(sys.stdin.buffer, encoding=enc)
        outfile = io.TextIOWrapper(sys.stdout.buffer, encoding=enc)
        _fileinput = fileinput.input(openhook=fileinput.hook_encoded(enc))
    else:
        _fileinput = fileinput.input()

    sutrauka(_fileinput, outfile=outfile, myspell=False)
