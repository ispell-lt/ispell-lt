#
#  Makefile for Lithuanian ispell dictionary
#
#  Copyright (C) 2000-2002 Albertas Agejevas
#

SORTWORDS =	\
	lietuviu.zodziai \
	lietuviu.jargon	\
	lietuviu.vardai	\
	lietuviu.veiksmazodziai\
	lietuviu.ivpk

WORDS =	\
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
	lt_LT.aff lt_LT.dic

install: lietuviu.hash
	install -c -g 0 -o 0 -m 0644 lietuviu.hash $(installdir)
	install -c -g 0 -o 0 -m 0644 lietuviu.aff $(installdir)
