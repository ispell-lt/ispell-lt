#
#  Makefile for Lithuanian ispell dictionary
#
#  Copyright (C) 2000-2002 Albertas Agejevas
#

VERSION=1.1+cvs`date -u +%Y%m%d`
DATE=`date -u +%Y\-%m\-%d`

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

lietuviu.dict: $(WORDS)
	cat  $(WORDS) | \
	grep -v '^[[:space:]]*#\|^[[:space:]]*$$\|XXX' | \
	sed -e 's/\#.*//' | \
	sort -u | tools/sutrauka.py > lietuviu.dict

lietuviu.hash: lietuviu.dict lietuviu.aff
	buildhash lietuviu.dict lietuviu.aff lietuviu.hash

liet-utf8.dict: lietuviu.dict
	iconv -f ISO-8859-13 -t UTF-8 $< > $@

liet-utf8.aff: lietuviu.aff
	iconv -f ISO-8859-13 -t UTF-8 $< > $@

liet-utf8.hash: liet-utf8.dict liet-utf8.aff
	buildhash $^ $@

sort:
	test -n "$$LC_COLLATE" -a "$$LC_COLLATE" != "C"
	for file in $(SORTWORDS) ; do \
		sort -u $$file > tmp-$$file; \
		mv tmp-$$file $$file; \
	done

clean:
	rm -f lietuviu.dict.stat lietuviu.dict.cnt lietuviu.hash lietuviu.dict \
	lt_LT.aff lt_LT.dic *.tar.gz *.zip  *.tar.bz2 \
	aspell/lt.wl aspell/lt.cwl aspell/lt_affix.dat aspell/lt.rws \
	aspell/README aspell/configure aspell/Makefile aspell/Makefile.pre \
	aspell/lt.multi aspell/lietuviu.alias aspell/lithuanian.alias

install: lietuviu.hash
	install -c -g 0 -o 0 -m 0644 lietuviu.hash $(installdir)
	install -c -g 0 -o 0 -m 0644 lietuviu.aff $(installdir)

aspell: lietuviu.dict lt_LT.aff
	cp lt_LT.aff aspell/lt_affix.dat
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

dist-myspell: myspell
	mkdir lt_LT-$(VERSION)
	cp lt_LT.dic lt_LT.aff README.EN  INSTRUKCIJOS.txt lt_LT-$(VERSION)
	echo "DICT lt LT lt_LT" > lt_LT-$(VERSION)/dictionary.lst
	zip -r lt_LT-$(VERSION).zip lt_LT-$(VERSION)
	rm -rf lt_LT-$(VERSION)

dist-aspell: clean aspell
	echo "s/^version .*-/version "$(VERSION)"-/" > tmp.tmp
	echo "s/^source-version .*/source-version "$(VERSION)"/" >> tmp.tmp
	sed 's/+cvs/.cvs/g' tmp.tmp > tmp.sed
	sed -f tmp.sed aspell/info > aspell/tmp.info
	cp aspell/tmp.info aspell/info
	rm -f tmp.* aspell/tmp.info
	mkdir aspell-dist
	cp -fr aspell/* aspell-dist
	rm -rf aspell-dist/CVS aspell-dist/doc/CVS
	$(MAKE) -C aspell-dist dist-nogen
	mv aspell-dist/*.tar.bz2 ./
	rm -rf aspell-dist

dist-hyph:
	zip -Dj hyph_lt_LT.zip hyph/hyph_lt_LT.dic hyph/README_hyph_lt_LT.txt

dists: dist-aspell dist-myspell dist-src dist-hyph 

