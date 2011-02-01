#
#  Makefile for Lithuanian ispell dictionary
#
#  Copyright (C) 2000-2002 Albertas Agejevas
#

VERSION=1.3
DATE=`date -u +%Y\-%m\-%d`

FIREFOXVERSION=4.0.*
THUNDERBIRDVERSION=3.3a3pre
SEAMONKEYVERSION=2.1b2
FENNECVERSION=4.0b4

# L.V.:
# Cygwin'e pasigauna sort.exe ið system32...
#ifeq ($(shell uname -o), Cygwin)
#	SORT = /bin/sort -u
#else
#	SORT = sort -u
#endif
#
# O galø gale -- sort.py
SORT = tools/sort.py -u --clean --smart


SORTWORDS = \
	lietuviu.zodziai \
	lietuviu.jargon	\
	lietuviu.vardai	\
	lietuviu.veiksmazodziai \
	lietuviu.ivpk

WORDS = \
	$(SORTWORDS)	\
	lietuviu.ivairus

installdir=`ispell -vv | grep LIBDIR | cut -d'"' -f2`

all: lietuviu.hash myspell

utf8: liet-utf8.hash

myspell: lt_LT.dic lt_LT.aff

lt_LT.dic: lietuviu.dict
	wc -l < lietuviu.dict | tr -d ' ' > lt_LT.dic
	cat lietuviu.dict >> lt_LT.dic

lt_LT.aff: lietuviu.aff
	tools/ispell2myspell.py lietuviu.aff > lt_LT.aff

# L.V.:
# Nereikia nukabinëti komentarø ir rikiuoti þodynø; tai daro pati sutrauka.py 
#
lietuviu.dict: $(WORDS)
	cat $(WORDS) | tools/sutrauka.py > lietuviu.dict
#
# old, orig:
#cat  $(WORDS) | \
#grep -v '^[[:space:]]*#\|^[[:space:]]*$$\|XXX' | \
#sed -e 's/\#.*//' | \
#$(SORT) | tools/sutrauka.py > lietuviu.dict



lietuviu.hash: lietuviu.dict lietuviu.aff
	buildhash lietuviu.dict lietuviu.aff lietuviu.hash

liet-utf8.dict: lietuviu.dict
	iconv -f ISO-8859-13 -t UTF-8 $< > $@

liet-utf8.aff: lietuviu.aff
	iconv -f ISO-8859-13 -t UTF-8 $< > $@

liet-utf8.hash: liet-utf8.dict liet-utf8.aff
	buildhash $^ $@

# sort:
# L.V.:
# Jei jau kaþkur, kaþkada ir kaþkodël prisireikia ar prisireiktø surikiuotø 
# þodynø (nors tai sudarko komentarø blokus ir/ar þodþiø sekcijas þodynø 
# failuose, kitaip tariant visà potencialià þodynø struktûrà, todël orig. 
# failø perraðyti nevalia ar nereikëtø), tai reikëtø rikiuoti pagal lt 
# abëcëlës rikiavimo tvarkà, o tai _universaliai_ moka tik tools/sort.py
# Taip pat derëtø paðalinti tuðèias, o galbût ir komentarø eilutes; tuomet 
# orig. þodynø perraðyti tikrai nevalia.
#
# (todël surikiuoti þodynai pervadinami originalui prikabinant .sorted)
#
sort:
	for file in $(SORTWORDS) ; do \
		$(SORT) $$file > $$file.sorted; \
	done

#
# old, orig:
#test -n "$$LC_COLLATE" -a "$$LC_COLLATE" != "C"
#for file in $(SORTWORDS) ; do \
#	$(SORT) $$file > tmp-$$file; \
#	mv tmp-$$file $$file; \
#done

clean:
	rm -f lietuviu.dict.stat lietuviu.dict.cnt lietuviu.hash lietuviu.dict \
	lt_LT.aff lt_LT.dic *.tar.gz *.zip  *.tar.bz2 *.xpi \
	aspell/lt.wl aspell/lt.cwl aspell/lt_affix.dat aspell/lt.rws \
	aspell/README aspell/configure aspell/Makefile aspell/Makefile.pre \
	aspell/lt.multi aspell/lietuviu.alias aspell/lithuanian.alias
	rm -rf dictionaries install.rdf install.js tmp.*

install: lietuviu.hash
	install -c -g 0 -o 0 -m 0644 lietuviu.hash $(installdir)
	install -c -g 0 -o 0 -m 0644 lietuviu.aff $(installdir)

aspell: lietuviu.dict lt_LT.aff
	cp lt_LT.aff aspell/lt_affix.dat
	echo "s/^version .*-/version "$(VERSION)"-/" > tmp.sed
	echo "s/^source-version .*/source-version "$(VERSION)"/" >> tmp.sed
	sed -f tmp.sed aspell/info > aspell/tmp.info
	cp aspell/tmp.info aspell/info
	rm -f tmp.sed aspell/tmp.info
	cd aspell; ../tools/proc
	cd aspell; ./configure
	cp lietuviu.dict aspell/lt.wl
	$(MAKE) -C aspell lt.rws

dist-src: 
	mkdir ispell-lt-$(VERSION)
	mkdir ispell-lt-$(VERSION)/tools
	mkdir ispell-lt-$(VERSION)/aspell
	mkdir ispell-lt-$(VERSION)/aspell/doc
	mkdir ispell-lt-$(VERSION)/hyph
	for file in `cat MANIFEST` ; do \
		cp $$file ispell-lt-$(VERSION)/$$file; \
	done
	tar zcvf ispell-lt-$(VERSION).tar.gz ispell-lt-$(VERSION)
	rm -rf ispell-lt-$(VERSION)

dist-aspell: clean aspell
	mkdir aspell-dist
	mkdir aspell-dist/doc
	cp README.EN aspell-dist/doc/README.txt
	cp -fr aspell/* aspell-dist
	cat COPYING >> aspell-dist/Copyright
	$(MAKE) -C aspell-dist dist-nogen
	mv aspell-dist/*.tar.bz2 ./
	rm -rf aspell-dist

dist-myspell: myspell
	mkdir lt_LT-$(VERSION)
	cp lt_LT.dic lt_LT.aff README.EN  INSTRUKCIJOS.txt lt_LT-$(VERSION)
	echo "DICT lt LT lt_LT" > lt_LT-$(VERSION)/dictionary.lst
	zip -r lt_LT-$(VERSION).zip lt_LT-$(VERSION)
	rm -rf lt_LT-$(VERSION)

dist-xpi: myspell
	mkdir -p dictionaries
	cp lt_LT.dic dictionaries/lt.dic
	cp lt_LT.aff dictionaries/lt.aff
	echo "s/ <.*$$//" > tmp.sed
	echo "s/^.*$$/    <em:contributor>&<\\\\\\\\\/em:contributor>/" >> tmp.sed
	tail -n+7 THANKS | sed -f tmp.sed > tmp.thanks
	sed -i ":a;$$!N;s/\n/\\\n/;ta;" tmp.thanks
	sed "s/.*/s\\/@CONTRIBUTORS@\\/&\\//" tmp.thanks > tmp.sed
	echo "s/@VERSION@/"$(VERSION)"/" >> tmp.sed
	echo "s/@FIREFOXVERSION@/"$(FIREFOXVERSION)"/" >> tmp.sed
	echo "s/@THUNDERBIRDVERSION@/"$(THUNDERBIRDVERSION)"/" >> tmp.sed
	echo "s/@SEAMONKEYVERSION@/"$(SEAMONKEYVERSION)"/" >> tmp.sed
	echo "s/@FENNECVERSION@/"$(FENNECVERSION)"/" >> tmp.sed
	sed -f tmp.sed mozilla/install.rdf.in > install.rdf
	sed "s/@VERSION@/"$(VERSION)"/" mozilla/install.js.in > install.js
	zip mozilla-spellcheck-lt-$(VERSION).xpi install.rdf install.js README.EN COPYING dictionaries/lt.*
	rm -rf dictionaries install.rdf install.js

dist-hyph:
	zip -Dj hyph_lt_LT.zip hyph/hyph_lt_LT.dic hyph/README_hyph_lt_LT.txt

dists: dist-aspell dist-myspell dist-src dist-xpi dist-hyph
