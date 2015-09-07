##
##  Makefile for Lithuanian ispell dictionary
##

VERSION = 1.3.1-$(shell date -u +%Y\.%m\.%d)

FIREFOXVERSION     = 43.*
THUNDERBIRDVERSION = 43.*
SEAMONKEYVERSION   = 2.38.*
## Fennec is the codename of Firefox for Android
FENNECVERSION      = 40.0

D_BUILD	  = build
D_CONF	  = etc
D_DIST    = dist
D_SRC     = src
D_TMP     = tmp
D_TOOLS   = tools
D_INSTALL = `ispell -vv | grep LIBDIR | cut -d '"' -f2`

## Directories; konkretus target'as pagal reikmes 
## pri(si)lipdo: etc/, build/, dist/, kt.
D_ASPELL  = aspell
D_HYPH    = hyph
D_MYSPELL = myspell
D_MOZILLA = mozilla
D_OOFFICE = openoffice


dist_pkg_hyph    := hyph_lt_LT.zip
dist_pkg_ispell  := ispell-lt-$(VERSION)
dist_pkg_myspell := myspell-lt-$(VERSION).zip
dist_pkg_mozilla := mozilla-spellcheck-lt-$(VERSION).xpi
dist_pkg_ooffice := openoffice-spellcheck-lt-$(VERSION).oxt


DICTS = lietuviu.zodziai \
	lietuviu.jargon \
	lietuviu.vardai \
	lietuviu.veiksmazodziai \
	lietuviu.ivpk \
	lietuviu.ivairus


## kai kas permetama į gilesnius katalogus (fizinių target'ų paieška)
vpath % $(D_BUILD)
vpath % $(D_BUILD)/$(D_MYSPELL)


## dinamiškai suformuojami/keičiami, tad nereikėtų išoriškai nustatyti
override D_DST   =
override D_DST_T =


SORT := $(PYCMD) $(D_TOOLS)/sort.py -u --clean --smart
FIND := find

#####################
## Kvazi funkcijos ##
#####################

## ar (executable) failas randamas PATH kelyje; toks
## universalus variantas, tinkantis ir win ir *nix
exists = $(shell which $1 > $(DEV_NULL) 2> $(DEV_NULL) && echo 1)

## Nors GnuWin turi dos2unix, tačiau gana archaišką versiją v0.9, kuri 
## kreivai veikia su temp failais. stdio.h:P_tmpdir reikšmė (turbūt /tmp) 
## neteisingai interpretuojama ir tmpnam() gražina failų pavadinimus root'e.
## (jei ateityje GnuWin atnaujins versiją, tai vertėtų naudotis šia programa)
dos2unix = tr -d '\r' < $1 > $1.new; mv -f $1.new $1

## kiek saugesnio šalinimo komanda; neiššokama aukščiau esamojo katalogo
deldir = $(FIND) . -depth -path './$(1)' -type d -exec rm -rf '{}' ';'
## man find: "processing filenames in such a way that file or directory  
## names containing single or double quotes, spaces or newlines are 
## correctly handled."
#deldir = $(FIND) . -path './$1' -type d -print0 | xargs -0 rm -rf



###################
## Init, patikra ##
###################


## L.V.:
## Apskritai, Windows/Cygwin aplinkoje, kartais kyla problemų. Kad ir dėl \r\n. 
## Aspell, pavyzdžiui, sutrinka skaitydamas config ir turbūt kt. failus su
## \r\n, o įvairūs (python, perl) script'ai, native aplinkoje, žinoma, išveda
## \r\n. Na ir kiti suderinamumo aspektai. 
## (tai OS/ENV check kodas neišvengiamas...)
ifneq (%COMSPEC%, $(shell echo %COMSPEC%))
    MSWIN  = 1
    SHELL_CMD = 1
    DEV_NULL = NUL
else
    cs := $(shell echo $$COMSPEC)
    ifneq ($$COMSPEC, $(cs))
        SHELL_SH = 1
        DEV_NULL = /dev/null
        ifneq (, $(findstring system32, $(cs)))
            MSWIN = 1
        endif
    endif
endif


uname_o := $(shell uname -o 2> $(DEV_NULL))



ifdef MSWIN
    ifeq (Cygwin, $(uname_o))
        CYGWIN = 1
    else
    ifeq (MinGW, $(uname_o))
        ## GnuWin32 rinkinys
        GNUWIN = 1
    else
    ifeq (Msys, $(uname_o))
        ## MinGW msys rinkinys
        MSYS = 1
    else
        $(info On WINDOWS you will need Cygwin or MinGW/Msys or GnuWin32 \
	       utils and unix shell)
    endif
    endif
    endif


    ifndef SHELL_SH
        ## reiškia PATH nerado sh.exe; dar yra šansų, kad yra koks *sh
        ## (paskutinė galimybė -- reikalavimas; reikia Unix shell'o)
        ifeq (1, $(call exists,bash))
            SHELL = bash.exe
        else
        ifeq (1, $(call exists,dash))
            SHELL = dash.exe
        else
        ifeq (1, $(call exists,zsh))
          SHELL = zsh.exe
        endif
        endif
        endif

        ifeq ($$SHELL, $(shell echo $$SHELL))
            $(error Unix shell not found. \
                    Install bash/dash/zsh or/and set PATH appropriately)
        endif
    endif

    #$(info using shell: $(SHELL))
    SHELL_SH = 1

    ifdef GNUWIN
        ## atskirus langus išmeta gal tik win-zsh; nepakenks, jei script'ai 
        ## bus kviečiami su išskirtinai nurodytu interpretatoriumi
        PYCMD = python
        PLCMD = perl
    endif

    ## Kai ką, pvz. find gali pasigauti iš system32; reikia nurodyti visą 
    ## kelią. Kabutės būtinos, nes GnuWin programos gražina ne posix path 
    ## ir backslash'ai yra (su)interpretuojami shell'o.
    BINDIR := $(shell dirname `which uname`)
    FIND := '$(BINDIR)/find'
endif
      

## jei nėra (i|a)spell -- eliminuosime atitinkamus target'us
ifeq (1, $(call exists,buildhash))
    HAVE_ISPELL = 1
else
    $(info buildhash not found; make targets omitted: \
	   '%.hash', 'utf8' 'install'.)
endif


ifeq (1, $(call exists,aspell))
    HAVE_ASPELL = 1
else
    $(info aspell not found; make targets omitted: \
	   'aspell', 'dist-aspell'.)
endif



##############################################
## Žodynų (ispell/myspell/aspell) target'ai ##
##############################################


## numatytasis (pirmasis) target'as: ispell hash'as ir myspell
.PHONY: all
ifdef HAVE_ISPELL
    all: lietuviu.hash
endif
all: myspell


## ispell
ifdef HAVE_ISPELL

%.hash: %.dict %.aff
	buildhash $^ $@

.PHONY: utf8
utf8: liet-utf8.hash

.PHONY: install
install: lietuviu.hash
	install -c -g 0 -o 0 -m 0644 lietuviu.hash $(D_INSTALL)
	install -c -g 0 -o 0 -m 0644 lietuviu.aff $(D_INSTALL)
endif




lietuviu.dict: $(DICTS)
	cat $(DICTS) | $(PYCMD) $(D_TOOLS)/sutrauka.py > $@

liet-utf8.dict: lietuviu.dict
	iconv -f ISO-8859-13 -t UTF-8 $< > $@

liet-utf8.aff: lietuviu.aff
	iconv -f ISO-8859-13 -t UTF-8 $< > $@


## myspell
.PHONY: myspell
myspell: lt_LT.dic lt_LT.aff

## ---------------------------------------------------------------------------
lt_LT.%: D_DST := $(D_BUILD)/$(D_MYSPELL)
## ---------------------------------------------------------------------------
lt_LT.dic: lietuviu.dict
	mkdir -p $(D_DST)
	wc -l < $< | tr -d ' ' > $(D_DST)/$@
	cat $< >> $(D_DST)/$@

lt_LT.aff: lietuviu.aff
	mkdir -p $(D_DST)
	$(PYCMD) $(D_TOOLS)/ispell2myspell.py $^ > $(D_DST)/$@


## aspell
ifdef HAVE_ASPELL

.PHONY: aspell
## ---------------------------------------------------------------------------
aspell: D_DST := $(D_BUILD)/$(D_ASPELL)
## ---------------------------------------------------------------------------
aspell: lt_LT.aff lietuviu.dict
	mkdir -p $(D_DST)
	cp -f $(D_CONF)/$(D_ASPELL)/lt.dat $(D_DST)
	cp -f lietuviu.dict $(D_DST)/lt.wl
	cp -f $(D_BUILD)/$(D_MYSPELL)/lt_LT.aff $(D_DST)/lt_affix.dat
ifdef MSWIN
	$(call dos2unix,$(D_DST)/lt.wl)
	$(call dos2unix,$(D_DST)/lt_affix.dat)
endif
	sed -e 's/@VERSION@/$(VERSION)/' \
	    $(D_CONF)/$(D_ASPELL)/info.in > $(D_DST)/info
	@cp -f $(D_TOOLS)/proc.pl $(D_DST)
	@cp -f COPYING $(D_DST)/Copyright
	cd $(D_DST); LC_ALL=C $(PLCMD) ./proc.pl
	cd $(D_DST); ./configure
	$(MAKE) -C $(D_DST) lt.rws
	@rm -f $(D_DST)/proc.pl
endif



# L.V.:
# Jei jau kažkur, kažkada ir kažkodėl prisireikia ar prisireiktų surikiuotų 
# žodynų (nors tai sudarko komentarų blokus ir/ar žodžių sekcijas žodynų 
# failuose, kitaip tariant visą potencialią žodynų struktūrą, todėl orig. 
# failų perrašyti nevalia ar nereikėtų), tai reikėtų rikiuoti pagal lt 
# abėcėlės rikiavimo tvarką, o tai _universaliai_ moka tik tools/sort.py
# Taip pat derėtų pašalinti tuščias, o galbūt ir komentarų eilutes; tuomet 
# orig. žodynų perrašyti tikrai nevalia.
#
# (todėl surikiuoti žodynai pervadinami originalui prikabinant .sorted)
#
sort:
	for file in $(DICTS) ; do \
		$(SORT) $$file > $$file.sorted; \
	done



.PHONY: clean-build
clean-build: clean-ispell
	$(call deldir,$(D_BUILD))

.PHONY: clean-dist
clean-dist:
	$(call deldir,$(D_DIST))

.PHONY: clean-tmp
clean-tmp:
	$(call deldir,$(D_TMP))


.PHONY: clean-aspell
clean-aspell:
	$(call deldir,$(D_BUILD)/$(D_ASPELL))

.PHONY: clean-myspell
clean-myspell:
	$(call deldir,$(D_BUILD)/$(D_MYSPELL))

.PHONY: clean-ispell
clean-ispell:
	-rm -f liet-utf8.*
	rm -f lietuviu.dict lietuviu.stat lietuviu.hash


.PHONY: clean
clean: clean-build clean-dist clean-tmp


#############################
## Distribucijos target'ai ##
#############################

.PHONY: dists
dists: dist-src dist-myspell dist-hyph dist-xpi dist-oxt
ifdef HAVE_ASPELL
    dists: dist-aspell 
endif

.PHONY: dist-src
## ---------------------------------------------------------------------------
dist-src: D_DST   := $(D_DIST)/$(D_SRC)
dist-src: D_DST_T := $(D_TMP)/$(dist_pkg_ispell)
## ---------------------------------------------------------------------------
dist-src: MANIFEST 
	mkdir -p $(D_DST)
ifdef GNUWIN
	mkdir -p $(D_DST_T)
	cpio -p -du $(D_DST_T) < $(D_BUILD)/MANIFEST 2> /dev/null
# cpio (bent jau v2.6, GnuWin) keikiasi (function not implemented) turbūt 
# ketindamas nustatyti teises ir kuriamiems katalogams kažkodėl nustato 0444;
# (vėliau rm -rf negali pašalinti tokių katalogų)
# Negana to, GnuWin tar'as (v1.13) dar pats nemoka gzip'inti...
	cd $(D_DST_T); $(FIND) . -type d -exec chmod 0777 '{}' ';'
	cd $(D_DST_T)/../; tar -cvf $(dist_pkg_ispell).tar $(dist_pkg_ispell)
	cd $(D_DST_T)/../; gzip  -f $(dist_pkg_ispell).tar
	mv -f $(D_DST_T)/../$(dist_pkg_ispell).tar.gz $(D_DST)
else
# Modernioje aplinkoje viskas gerokai paprasčiau; tiesa, tam reikia bent jau 
# gnu tar 1.20 (2008 m)
	tar -czvf $(D_DST)/$(dist_pkg_ispell).tar.gz \
	    --transform=s,^,$(dist_pkg_ispell)/, \
	    -T $(D_BUILD)/MANIFEST
endif


.PHONY: dist-myspell
## ---------------------------------------------------------------------------
dist-myspell: D_DST    := $(D_DIST)/$(D_MYSPELL)
dist-myspell: D_DST_T  := $(D_TMP)/$(D_MYSPELL)
dist-myspell: D_DST_TS := $(D_DST_T)/"myspell-lt-$(VERSION)"

## ---------------------------------------------------------------------------
dist-myspell: myspell
	mkdir -p $(D_DST)
	mkdir -p $(D_DST_TS)
	cp -f $(D_BUILD)/$(D_MYSPELL)/lt_LT.dic \
	      $(D_BUILD)/$(D_MYSPELL)/lt_LT.aff \
	      $(D_DST_TS)
	cp -f README.EN $(D_DST_TS)/README
	cp -f AUTHORS COPYING ChangeLog $(D_DST_TS)
	cp -f $(D_CONF)/$(D_MYSPELL)/dictionary.lst $(D_DST_TS)
	cd $(D_DST_T); zip -r $(dist_pkg_myspell) ./
	mv -f $(D_DST_T)/$(dist_pkg_myspell) $(D_DST)
	$(call deldir,$(D_DST_T))


ifdef HAVE_ASPELL
.PHONY: dist-aspell
## ---------------------------------------------------------------------------
dist-aspell: D_DST   := $(D_DIST)/$(D_ASPELL)
dist-aspell: D_DST_T := $(D_TMP)/$(D_ASPELL)
## ---------------------------------------------------------------------------
dist-aspell: aspell
	mkdir -p $(D_DST)
	mkdir -p $(D_DST_T)/doc
	cp -fr $(D_BUILD)/$(D_ASPELL)/* $(D_DST_T)
	cp -f README.EN $(D_DST_T)/doc/README
	cp -f AUTHORS ChangeLog $(D_DST_T)
	$(MAKE) -C $(D_DST_T) dist-nogen
	mv -f $(D_DST_T)/*.tar.bz2 $(D_DST)
	$(call deldir,$(D_DST_T))
endif


.PHONY: dist-hyph
## ---------------------------------------------------------------------------
dist-hyph: D_DST   := $(D_DIST)/$(D_HYPH)
dist-hyph: D_DST_T := $(D_TMP)/$(D_HYPH)
## ---------------------------------------------------------------------------
dist-hyph:
	mkdir -p $(D_DST)
	mkdir -p $(D_DST_T)
	cp -f $(D_CONF)/$(D_HYPH)/hyph_lt_LT.dic \
	      $(D_CONF)/$(D_HYPH)/README_hyph_lt_LT.txt \
	      $(D_DST_T)
	cd $(D_DST_T); zip -r $(dist_pkg_hyph) ./
	mv -f $(D_DST_T)/$(dist_pkg_hyph) $(D_DST)
	$(call deldir,$(D_DST_T))



## Priedas Mozillos produktams
.PHONY: dist-xpi
## ---------------------------------------------------------------------------
dist-xpi: CT      := em:contributor
dist-xpi: D_DST   := $(D_DIST)/$(D_MOZILLA)
dist-xpi: D_DST_T := $(D_TMP)/$(D_MOZILLA)
## ---------------------------------------------------------------------------
dist-xpi: myspell
	mkdir -p $(D_DST)
	mkdir -p $(D_DST_T)/dictionaries
	cp -f $(D_BUILD)/$(D_MYSPELL)/lt_LT.dic $(D_DST_T)/dictionaries/lt.dic
	cp -f $(D_BUILD)/$(D_MYSPELL)/lt_LT.aff $(D_DST_T)/dictionaries/lt.aff
	cp -f README.EN $(D_DST_T)/README
	cp -f COPYING $(D_DST_T)
	tail -n+4 AUTHORS | sed -E -e \
	    's/^\s*\<(.*)\>\s*<.*$$/    <$(CT)>\1<\/$(CT)>/' > \
	    $(D_TMP)/contributors.txt
	sed \
	    -e '\_@CONTRIBUTORS@_ { r $(D_TMP)/contributors.txt' \
	    -e 'd }' \
	    -e 's/@VERSION@/$(VERSION)/' \
	    -e 's/@FIREFOXVERSION@/$(FIREFOXVERSION)/' \
	    -e 's/@THUNDERBIRDVERSION@/$(THUNDERBIRDVERSION)/' \
	    -e 's/@SEAMONKEYVERSION@/$(SEAMONKEYVERSION)/' \
	    -e 's/@FENNECVERSION@/$(FENNECVERSION)/' \
	    $(D_CONF)/$(D_MOZILLA)/install.rdf.in > $(D_DST_T)/install.rdf
	cd $(D_DST_T); zip -r $(dist_pkg_mozilla) ./
	mv -f $(D_DST_T)/$(dist_pkg_mozilla) $(D_DST)
	$(call deldir,$(D_DST_T))
	@rm -f $(D_TMP)/contributors.txt


## Priedas OpenOffice ir LibreOffice paketams
.PHONY: dist-oxt
## ---------------------------------------------------------------------------
dist-oxt: D_DST   := $(D_DIST)/$(D_OOFFICE)
dist-oxt: D_DST_T := $(D_TMP)/$(D_OOFFICE)
## ---------------------------------------------------------------------------
dist-oxt: myspell
	mkdir -p $(D_DST)
	mkdir -p $(D_DST_T)/META-INF
	cp -f $(D_BUILD)/$(D_MYSPELL)/lt_LT.dic $(D_DST_T)/lt.dic
	cp -f $(D_BUILD)/$(D_MYSPELL)/lt_LT.aff $(D_DST_T)/lt.aff
	cp -f $(D_CONF)/$(D_OOFFICE)/manifest.xml $(D_DST_T)/META-INF
	cp -f $(D_CONF)/$(D_OOFFICE)/dictionaries.xcu $(D_DST_T)
	sed -e 's/@VERSION@/$(VERSION)/' \
	      $(D_CONF)/$(D_OOFFICE)/description.xml.in > \
	      $(D_DST_T)/description.xml
	cp -f $(D_CONF)/$(D_HYPH)/hyph_lt_LT.dic $(D_DST_T)/hyph_lt.dic
	cp -f $(D_CONF)/$(D_HYPH)/README_hyph_lt_LT.txt \
	      $(D_DST_T)/README_hyph
	cp -f README.EN $(D_DST_T)/README
	cp -f AUTHORS COPYING $(D_DST_T)
	cd $(D_DST_T); zip -r $(dist_pkg_ooffice) ./
	mv -f $(D_DST_T)/$(dist_pkg_ooffice) $(D_DST)
	$(call deldir,$(D_DST_T))



MANIFEST:
	mkdir -p $(D_BUILD)
	python -c \
	'from distutils.core import setup; \
	 setup(name = "-", version = "-", url = "-", \
	       author = "-", author_email = "-")' \
	sdist --no-defaults \
	      --manifest-only \
              --template $(D_CONF)/MANIFEST.in --manifest $(D_BUILD)/MANIFEST
	sed -i -e '1d' $(D_BUILD)/MANIFEST
ifdef MSWIN
	sed -i -e 's/\\/\//g' $(D_BUILD)/MANIFEST
	$(call dos2unix,$(D_BUILD)/MANIFEST)
endif
                	

