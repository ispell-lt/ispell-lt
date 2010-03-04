#!/usr/bin/env python
# -*- coding: iso-8859-13 -*-
#
# Autorius: Albertas Agejevas, 2003
# Koregavo: Laimonas Vėbra, 2010
#
"""
ispell-lt projekto/žodyno įrankis.
Suglaudžia/sutraukia priešdėlinius veiksmažodžius, pvz.: 
    pa|eina, nu|eina, at|eina, ... -> eina/bef...

o taip ir skirtingas tokio pačio žodžio afikso žymas, pvz.:
    dviratis/D, dviratis/B -> dviratis/DB 

Žodžiai ir jų žymos glaudžiamos tik suderinamų (kalbos dalių) 
grupėse. Dabar tai: veiksmažodžiai, būdvardžiai ir likę.  Taip 
padaryta todėl, kad veiksmažodžiai gali turėti aibę priešdėlinių 
žymų ir kartu su kitos kalbos žymomis gali generuoti daug 
neteisingų formų, arba dažnos būdvardžių /N žymos ne visuomet 
tinka daiktavardžiams (ir kt.), pvz.:

    jungė/D       (daiktavardis)
    jungė/Pef...  (būt. k. l. veiksmažodis)

    jungė/DPef... generuotų neteisingas formas: 
        {priešdėliai}{daikt. 'jungė' linksniai}

    baltaodis/BDN -> ne[be]baltaodžiui (daiktavardis) -- blogai,    
                  -> ne[be]baltaodžiam (būdvardis)    -- gerai.

Naudojimas:
    ./sutrauka žodynas.txt > sutraukta.txt
    cat žodynas.txt | ./sutrauka > sutraukta.txt

"""
import os
import sys
import fileinput

from locale import setlocale, getdefaultlocale, LC_COLLATE, strxfrm

# sets modulis paseno ir nuo v2.6+ sistemoje (built-in) jį keičia
# set/frozenset tipai; importuojant pasenusį -- įspėjama (warning).
if sys.version_info < (2, 6):
    from sets import Set


wcount = 0  # constringed words count
bcount = 0  # saved bytes count


def _stats(word, cflags, var=0):
    global wcount, bcount
    
    # Statistika (sutaupyta žodžių ir vietos)... 
    #
    # Kiek sutaupoma vietos (bcount) suskliaudžiant žodį:
    # žodžio ilgis + bendrų žymų kiekis + _papildomi_ (2 arba 1)
    # priklausomai nuo varianto:
    #   - kai žodis be afiksų -- sutaupoma: '/', '\n' (2)
    #   - kai [var]iantas > 0 -- priešdėlinis veiksmažodis ir
    #                            sutaupoma:      '\n' (1)
    #                            ('/' keičia priešdėlio afikso žyma)
    #
    wcount += 1
    bcount += len(word) + len(cflags) + (2 if not (var and cflags) else 1)



def _set(arg=''):
    if sys.version_info < (2, 6):
        return Set(arg)  
    else:
        return set(arg)


def sutrauka(lines, outfile=sys.stdout, myspell=True):
    i = 0
    adjes = {}
    verbs = {}
    words = {}


    vflags = _set("TYEP")  # verb flags -- veiksmažodžių gr. žymos.
    aflags = _set("AB")    # adjective flags -- būdvardžių gr. žymos.

    # Debug
    #f = open('./sutrauka.err', 'w')
    
    # win lokalės atpažinimo/nustatymo problemos...
    locale = getdefaultlocale()
    if os.name is "nt":
        locale = "Lithuanian"

    try:
        setlocale(LC_COLLATE, locale)
    except:
        sys.stderr.write("Could not set locale\n")


    sys.stderr.write("\n--- " + sys.argv[0] + ' ' + 
                     '-' * (60 - len(sys.argv[0]) - 5) + 
                     "\nReading ")        

    for line in lines:
        # Skaitymo progresas...
        if not lines.lineno() % 5000:
            sys.stderr.write(".")
            sys.stderr.flush()

        # Ignoruojamos tuščios ir komentaro eilutės.
        line = line.strip()
        line = line.split("#")[0]
        if not line:
            continue
        
        # Eilutė skeliama į žodį ir jo žymų rinkinį.
        sp = line.split("/")
        word = sp[0]
        if len(sp) > 1:
            wflags = _set(sp[1])
        else:
            wflags = _set()
       
        # Veiksmažodžiai ir būdvardžiai į atskirus dict.
        if vflags & wflags:
            d = verbs
        elif aflags & wflags:
            d = adjes
        else:
            d = words

        # Žodis pridedamas į dict arba jei jau yra -- suliejamos žymos
        if word not in d:
            d[word] = wflags
        else:
            swflags = d[word]  # stored word flags
           
            # Debug
            #f.write("Skliaudžiamas žodis '{0}':\n\t"
            #        "aff: {1}\n\taff: {2}\n".format(word, wflags, swflags))

            _stats(word, swflags & wflags)
            swflags.update(wflags)


    sys.stderr.write("\nProcessing ")

    # Suskliaudžiami priešdėliniai veiksmažodžiai
    d = verbs
    for word in d.keys():
        # Apdorojimo progresas...
        i += 1
        if not (i % 5000):
            sys.stderr.write(".")
            sys.stderr.flush()
       
        # Žodis (jau) galėjo būti pašalintas iš words dict...
        if word not in d:
            continue

        # Žodžio afiksų žymų rinkinys.
        wflags = d[word]
                
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
                # (word without reflexive prefix part)
                #
                wrpword = word[len(pref)-2:] if pref.endswith("si") else None
    
                # Žodis be priešdėlio, pvz.: per|šoko -> šoko.
                # (word without prefix) 
                wpword = word[len(pref):]                
                
                if wpword in d:
                    wpflags = d[wpword]
   
                    if wrpword not in words:
                        # and wflags.issubset(wpflags))
                        #
                        # Skliaudžiant priešdėlinius veiksmažodžius dėl /X /N 
                        # priešdėlinių dalelyčių (ispell apribojimo jas 
                        # pridedant/jungiant) prarandamos kelios priešdėlinio 
                        # veiksmažodžio formos, pvz:
                        #   pavartyti/X  >  te|pa|vartyti, tebe|pa|vartyti, 
                        #                   be|pa|vartyti, ...
                        # vs
                        #    vartyti/Xf  >  tevartyti, tebevartyti, 
                        #                   bevartyti, ...
                        #
                        # Todėl skliaudžiant nebūtina tikrinti ar sutampa žodžių
                        # (priešdėlinio ir šakninio) žymų aibės; praradimas vyksta, 
                        # net jei jos sutampa, o netikrinant, t.y. susitaikius su
                        # ir taip vykstančiu priešdėlinių darinių/formų: 
                        #  [tebe, be, te, nebe] {priešdėlis} žodis 
                        #
                        # praradimu, žodyną suglaudinamas dar virš 50 kB.
                        #
                        # ARBA atvirkščiai -- siekiant, kad nebūtų praradimų, kaip 
                        # tik nereikėtų tokių žodžių (jei priešdėlinis žodis turi 
                        # /X, /N žymas) glaudinti.
                        
                        # Debug
                        #    f.write("\nNeskliaudžiamas žodis '{0}|{1}', nes nesiderina afiksai:"
                        #            "\n\t(su priešd.) aff: {2}"
                        #            "\n\t(be priešd.) aff: {3}\n".format(pref, wpword, wflags, wpflags))
                        
                        _stats(word, wflags & wpflags, 1)

                        # Suliejamos afiksų žymos ir pridedama priešdėlio žyma.
                        wpflags.update(wflags)
                        wpflags.add(pflag)
                 
                        # Žodis sukliaustas (prie šakninio žodžio sulietos 
                        # žymos, pridėta priešdėlio afikso žyma).  Pašaliname 
                        # priešdėlinį žodį iš 'verbs' dict ir baigiame 
                        # priešdėlių ciklą, nes priešdėliai unikalūs ir žodžio
                        # pradžia nebegali sutapti su jokiu kitu priešdėliu.
                        del d[word]
                        break

    sys.stderr.write(" done.\nWords constringed: {0}, "
                     "bytes saved: {1}.\n".format(wcount, bcount) + 
                     '-' * 60 + '\n')

    res = []
    for word, flags in words.items() + verbs.items() + adjes.items():
        if flags:
            f = list(flags)
            f.sort()
            end = "/" + "".join(f)
        else:
            end = ""

        res.append((strxfrm(word), word + end))

    res.sort()

    # myspell'o žodyno pradžioje -- žodžių kiekis.
    if myspell:
        print >> outfile, len(res)

    for word in res:
        print >> outfile, word[1]

prefixes = (
    ("a", "ap"),
    ("a", "api"),
    ("b", "at"),
    ("b", "ati"),
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
