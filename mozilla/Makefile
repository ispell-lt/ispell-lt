all:
	install -d bin/components/myspell
	cp ../lt_LT.aff bin/components/myspell/lt.aff
	cp ../lt_LT.dic bin/components/myspell/lt.dic
	zip lt.zip bin/components/myspell/lt.*
	zip lt.zip license/*
	zip lt.zip install.js
	mv lt.zip lt.xpi

install:
	echo "This does nothing"

clean:
	rm -f *.xpi bin/components/myspell/lt.*
