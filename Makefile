#
#  Makefile for Lithuanian ispell dictionary
#
#  Copyright (C) 2000-2002 Albertas Agejevas
#

VERSION=1.1
#+cvs`date -u +%Y%m%d`
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

sort:
	test -n "$$LC_COLLATE" -a "$$LC_COLLATE" != "C"
	for file in $(SORTWORDS) ; do \
		sort -u $$file > tmp-$$file; \
		mv tmp-$$file $$file; \
	done

clean:
	rm -f lietuviu.dict.stat lietuviu.dict.cnt lietuviu.hash lietuviu.dict \
	lt_LT.aff lt_LT.dic *.tar.gz *.zip  *.tar.bz2\
	aspell/lt.wl aspell/lt.cwl aspell/lt_affix.dat
#	$(MAKE) -C aspell distclean
	rm -f aspell/Makefile aspell/lt.rws

install: lietuviu.hash
	install -c -g 0 -o 0 -m 0644 lietuviu.hash $(installdir)
	install -c -g 0 -o 0 -m 0644 lietuviu.aff $(installdir)

aspell: myspell
	cp lt_LT.aff aspell/lt_affix.dat
	cd aspell; ./configure
	cp lietuviu.dict aspell/lt.wl
	$(MAKE) -C aspell lt.rws

dist-src: 
	mkdir ispell-lt-$(VERSION)
	mkdir ispell-lt-$(VERSION)/tools
	mkdir ispell-lt-$(VERSION)/aspell
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

dist-aspell: aspell
	echo "s/^version = .*-/version = "$(VERSION)"-/" > tmp.sed
	sed -f tmp.sed aspell/Makefile.pre > tempfile
	cp tempfile aspell/Makefile.pre
	sed -f tmp.sed aspell/Makefile > tempfile
	cp tempfile aspell/Makefile
	echo "s/^Version .*-/Version "$(VERSION)"-/" > tmp.sed
	echo "s/^20.*-.*-.*/"$(DATE)"/" >> tmp.sed
	sed -f tmp.sed aspell/README > tempfile
	cp tempfile aspell/README
	rm -f tempfile tmp.sed
	$(MAKE) -C aspell dist-nogen
	mv aspell/*.tar.bz2 ./

dists: dist-myspell dist-aspell dist-src 

