all:
	cat ../lietuviu.budvardziai | grep -v ^# | ispell -e \
	    -l ../lietuviu.aff > budvardziai.aspell
	cat budvardziai.aspell | aspell --local-data-dir=./ \
	    --lang=lt create master ./lt.budvardziai.rws
	cat ../lietuviu.daiktavardziai | grep -v ^#  | ispell -e \
	    -l ../lietuviu.aff > daiktavardziai.aspell
	cat daiktavardziai.aspell | aspell --local-data-dir=./ \
	    --lang=lt create master ./lt.daiktavardziai.rws
	cat ../lietuviu.ivairus | grep -v ^# | ispell -e \
	    -l ../lietuviu.aff > ivairus.aspell
	cat ivairus.aspell | aspell --local-data-dir=./ \
	    --lang=lt create master ./lt.ivairus.rws
	cat ../lietuviu.jargon | grep -v ^# | ispell -e \
	    -l ../lietuviu.aff > jargon.aspell
	cat jargon.aspell | aspell --local-data-dir=./ \
	    --lang=lt create master ./lt.jargon.rws
	cat ../lietuviu.nekaitomi | grep -v ^# | ispell -e \
	    -l ../lietuviu.aff > nekaitomi.aspell
	cat nekaitomi.aspell | aspell --local-data-dir=./ \
	    --lang=lt create master ./lt.nekaitomi.rws
	cat ../lietuviu.tarpt.budvardziai | grep -v ^# | ispell -e \
	    -l ../lietuviu.aff > tarpt.budvardziai.aspell 
	cat tarpt.budvardziai.aspell | aspell --local-data-dir=./ \
	    --lang=lt create master ./lt.tarpt.budvardziai.rws
	cat ../lietuviu.tarpt.daiktavardziai | grep -v ^# | ispell -e \
	    -l ../lietuviu.aff > tarpt.daiktavardziai.aspell
	cat tarpt.daiktavardziai.aspell | aspell --local-data-dir=./ \
	    --lang=lt create master ./lt.tarpt.daiktavardziai.rws
#	cat ../lietuviu.tarpt.veiksmazodziai | grep -v ^# | ispell -e \
#	    -l ../lietuviu.aff > tarpt.veiksmazodziai.aspell
#	cat tarpt.veiksmazodziai.aspell | aspell --local-data-dir=./ \
#	    --lang=lt create master ./lt.tarpt.veiksmazodziai.rws
	cat ../lietuviu.vardai | grep -v ^#  | ispell -e \
	    -l ../lietuviu.aff > vardai.aspell
	cat vardai.aspell | aspell --local-data-dir=./ \
	    --lang=lt create master ./lt.vardai.rws
#	cat ../lietuviu.veiksmazodziai | grep -v ^# | ispell -e \
#	    -l ../lietuviu.aff > veiksmazodziai.aspell
#	cat veiksmazodziai.aspell | aspell --local-data-dir=./ \
#	    --lang=lt create master ./lt.veiksmazodziai.rws

install:
	echo "Reikia pataisyti"

clean:
	rm -f *.aspell *.rws
