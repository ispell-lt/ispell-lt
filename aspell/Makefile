#
#   Komandø, kurios sukuria þodynus, apraðymas
#
# $Id: Makefile,v 1.4 2003/05/08 09:53:54 tokul Exp $
#
all:
	cat ../lietuviu.ivairus | grep -v ^# | ispell -e \
	    -d ../lietuviu > ivairus.aspell
	cat ivairus.aspell | aspell --local-data-dir=./ \
	    --lang=lt create master ./lt.ivairus.rws
	cat ../lietuviu.jargon | grep -v ^# | ispell -e \
	    -d ../lietuviu > jargon.aspell
	cat jargon.aspell | aspell --local-data-dir=./ \
	    --lang=lt create master ./lt.jargon.rws
	cat ../lietuviu.zodziai | grep -v ^# | ispell -e \
	    -d ../lietuviu > zodziai.aspell
	cat zodziai.aspell | aspell --local-data-dir=./ \
	    --lang=lt create master ./lt.zodziai.rws
	cat ../lietuviu.vardai | grep -v ^#  | ispell -e \
	    -d ../lietuviu > vardai.aspell
	cat vardai.aspell | aspell --local-data-dir=./ \
	    --lang=lt create master ./lt.vardai.rws
#	cat ../lietuviu.veiksmazodziai | grep -v ^# | ispell -e \
#	    -d ../lietuviu > veiksmazodziai.aspell
#	cat veiksmazodziai.aspell | aspell --local-data-dir=./ \
#	    --lang=lt create master ./lt.veiksmazodziai.rws

install:
	echo "Reikia pataisyti"

clean:
	rm -f *.aspell *.rws
