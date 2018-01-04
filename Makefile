MKDIR = mkdir -p
ATOM_REPO = https://github.com/ugeorge/forsyde-atom.git
HADOCK_REPO = https://github.com/ugeorge/haddock.git

API_PATH:=api
HTML_PATH:=$(API_PATH)/html
LATEX_PATH:=$(API_PATH)/latex
PRETTY_PATH:=$(LATEX_PATH)/pretty

# TODO! LATEX_REPO

# FILES = eqs-exb misc\
# 	eqs-moc moc moc-sy moc-de moc-ct moc-sdf \
# 	eqs-skel skel eqs-skel-vector skel-vector-func \
# 	skel-vector-comm

FILES = eqs-exb misc \
	eqs-moc moc moc-sy moc-de moc-ct moc-sdf \
	eqs-skel skel eqs-skel-vector skel-vector-func

target-format=pdf/$(1)-$(2).pdf

##################### DO NOT CHANGE FROM HERE #####################

include .env
# export $(shell sed 's/=.*//' envfile)

STYLE = $(wildcard tex/*.sty)
PDF_SRCS = $(foreach file,$(FILES),$(call make-pdf-targets,$(file)))
PDF_FIGS  = $(sort $(foreach file,$(FILES),$(call make-pdf-targets,$(file))))
PNG_FIGS = $(patsubst pdf/%.pdf, png/%.png, $(PDF_SRCS))

DUMP_SRC = atom-docplots/Main.hs
DUMP_BIN = atom-docplots/dist/build/atom-docplots/atom-docplots

ATOM_VER    = $(shell cd forsyde-atom && git describe --tags | sed 's|-.*$$||g')

## FUNCTIONS ##

# Check that given variables are set and all have non-empty values,
# die with an error otherwise.
# 1. Variable name(s) to test.
# 2. (optional) Error message to print.
check_defined = \
    $(strip $(foreach 1,$1, \
        $(call __check_defined,$1,$(strip $(value 2)))))
__check_defined = \
    $(if $(value $1),, \
      $(error Undefined $1$(if $2, ($2))))

# Extracts figure names from TeX files
# 1. path to TeX file
get-fig-names=$(shell grep -oP "(?<=begin{docimage}{).*(?=})" $(1))

# Makes target PDF names with figure names extracted.
# 1. path to TeX file
make-pdf-targets=$(patsubst %,$(call target-format,$(1),%),$(call get-fig-names, tex/$(1).tex))

## TEMPLATES ##


define compile-latex

	@echo $(2)
	@TEXINPUTS=:./:tex/ pdflatex "\def\currimage{$(subst $(1)-,,$(basename $(notdir $(2))))} \input{tex/$(1).tex}" 1> log || cat log
	@mv $(1).pdf $(2)
	@rm $(1).*
endef

define pdf-template
  $(2) : tex/$(1).tex
	$(foreach image,$(2),$(call compile-latex,$(1),$(image)))
endef

## TARGETS ##

.PHONY: manual html latex-raw latex-pretty pdf png prep-pdf prep-png prep-html prep-latex prep-atom

manual:
	@test -f manual/input/ForSyDe-Atom.tex || echo \
		"Manual not set up yet. Run 'make prep-manual'"


latex-pretty:
	@test -d $(HTML_PATH) || echo "Run 'make html' first"
	@test -d $(LATEX_PATH) || echo "Run 'make latex-raw' first"
	@$(MKDIR) $(PRETTY_PATH)
	@bash resource/prettify.sh $(HTML_PATH) $(LATEX_PATH) $(PRETTY_PATH)
	@echo "Pretty version is in: $(PRETTY_PATH)"

latex-raw: prep-html prep-latex Makefile $(STYLE)
	@cd forsyde-atom \
	&& cabal sandbox init \
	&& cabal install --dependencies-only \
	&& cabal configure --with-haddock=../haddock/dist/build/haddock/haddock \
	&& (cabal haddock --haddock-options=--latex | awk 'END {print $$NF}' | xargs dirname | xargs -I {} mv {} ../$(LATEX_PATH))
	@find $(LATEX_PATH) -type f ! \( -iname \*.tex -o -iname \*.sty \) -delete
	@echo "Generated LaTeX API doc in $(LATEX_PATH)"


html: png prep-html Makefile $(STYLE)
	@cp -f png/* forsyde-atom/fig/
	@cd forsyde-atom \
	&& cabal sandbox init \
	&& cabal install --dependencies-only \
	&& cabal configure \
	&& (cabal haddock --hyperlink-source | awk 'END {print $$NF}' | xargs dirname | xargs -I {} mv {} ../$(HTML_PATH))
	@echo "Generated HTML API doc in $(HTML_PATH)"



pdf: prep-pdf $(STYLE) $(PDF_FIGS)
png: pdf prep-png $(PNG_FIGS)

prep-pdf: dump-plots
	@$(MKDIR) pdf
# TODO	LATEX_REPO

dump-plots: $(DUMP_BIN)
	@cd atom-docplots && cabal build -j4
	./$(DUMP_BIN)
	@rm -rf tex/data
	@mv data tex

$(DUMP_BIN): prep-atom
	@cd atom-docplots \
	  && cabal sandbox init \
	  && cabal sandbox add-source ../forsyde-atom \
	  && cabal install \
	  && cabal build -j4

prep-png:
	@$(MKDIR) png

prep-html: prep-atom
	@$(MKDIR) $(API_PATH)
	@rm -rf $(HTML_PATH)
	@if ! haddock --version; then cabal install haddock; fi
	@if ! hscolour --version; then cabal install hscolour; fi

prep-atom:
	@if [ ! -d forsyde-atom ]; then \
		git clone $(ATOM_REPO); \
		sed -i 's/-- extra-doc-files/extra-doc-files/g' forsyde-atom/forsyde-atom.cabal; \
		mkdir -p forsyde-atom/fig; \
		touch forsyde-atom/fig/phony.png; \
	fi


prep-latex:
	@$(MKDIR) $(API_PATH)
	@rm -rf $(LATEX_PATH)
	@if [ ! -d haddock ]; then \
		git clone $(HADOCK_REPO); \
		cd haddock \
		&& cabal sandbox init \
		&& cabal sandbox add-source haddock-library \
		&& cabal sandbox add-source haddock-api \
		&& cabal sandbox add-source haddock-test \
		&& cabal install -j4 --dependencies-only \
		&& cabal configure \
		&& cabal build -j4; \
	fi

prep-manual: html latex-raw latex-pretty 
	@:$(call check_defined, EXAMP_PATH, full path to forsyde-atom-examples)
	@test -d $(EXAMP_PATH) || echo \
		"Please define EXAMP_PATH. The current one is not a valid path : $(EXAMP_PATH)"
#	@cp -rf resource/manual .
	@cp -f $(PRETTY_PATH)/*.tex manual/input/
	@mkdir -p manual/fig
	@cp -f pdf/*.pdf manual/fig/
	@echo "\\\newcommand*{\\AtomExamplesRoot}{$(EXAMP_PATH)}" > manual/sty/atom-vars.sty
	@echo "\\\newcommand*{\\AtomVersion}{kkkkkk}" | sed 's/kkkkkk/'"$(ATOM_VER)"'/g' >> manual/sty/atom-vars.sty

## RULES ##

# generate rules for PDF figures
$(foreach file,$(FILES),\
	$(eval $(call pdf-template,$(file),$(call make-pdf-targets,$(file)))))

# Rule for PNG figures: convert
png/%.png: pdf/%.pdf
	@echo $@
	@convert -density 150 $< -quality 90 $@

## EXTRA TARGETS ##

clean:
	rm log
	rm -rf api

remove: clean
	rm -rf pdf png forsyde-atom forsyde-latex haddock

.env:
	@if [ ! -f .env ]; then \
		echo "Where is the forsyde-atom-examples dir? "; \
		read thePath; \
		readlink -f $thePath > .env; \
	fi

test:
	echo 
