#
#  Makefile for Lithuanian ispell dictionary
#   
#  (C) 2000 Albertas Agejevas
#

WORDS = lietuviu.base lietuviu.vardai lietuviu.words lietuviu.jargon lietuviu.verbs
installdir=`ispell -vv | grep LIBDIR | cut -d'"' -f2`

all: lietuviu.hash

lietuviu.dict: $(WORDS)
	cat  $(WORDS) | \
	grep -v '^[[:space:]]*#\|^[[:space:]]*$$' | \
	sort > lietuviu.dict

lietuviu.hash: lietuviu.dict lietuviu.aff
	buildhash lietuviu.dict lietuviu.aff lietuviu.hash

sort:
	# sort all files except base
	for file in lietuviu.vardai lietuviu.words lietuviu.jargon lietuviu.verbs; do \
		sort $$file | uniq > tmp-$$file; \
		mv tmp-$$file $$file; \
	done

clean:
	rm -f *~ lietuviu.dict.stat lietuviu.dict.cnt lietuviu.hash lietuviu.dict

install: lietuviu.hash
	install -c -g 0 -o root -m 0644 lietuviu.hash $(installdir)
	install -c -g 0 -o root -m 0644 lietuviu.aff $(installdir)
