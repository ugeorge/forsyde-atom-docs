MKDIR = mkdir -p
ATOM_REPO = https://github.com/forsyde/forsyde-atom.git
HADOCK_REPO = https://github.com/ugeorge/haddock.git

LATEX_PATH := api/latex
HTML_PATH  := api/html

# TODO! LATEX_REPO

# FILES = eqs-exb misc\
# 	eqs-moc moc moc-sy moc-de moc-ct moc-sdf \
# 	eqs-skel skel eqs-skel-vector skel-vector-func \
# 	skel-vector-comm

FILES = eqs-exb \
	eqs-moc moc moc-sy moc-de moc-sdf \
	eqs-skel skel eqs-skel-vector skel-vector-func

target-format=pdf/$(1)-$(2).pdf

##################### DO NOT CHANGE FROM HERE #####################

STYLE = $(wildcard tex/*.sty)
PDF_SRCS = $(foreach file,$(FILES),$(call make-pdf-targets,$(file)))
PDF_FIGS  = $(sort $(foreach file,$(FILES),$(call make-pdf-targets,$(file))))
PNG_FIGS = $(patsubst pdf/%.pdf, png/%.png, $(PDF_SRCS))

## FUNCTIONS ##

get-fig-names=$(shell grep -oP "(?<=begin{docimage}{).*(?=})" $(1))
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

.PHONY: all html latex latex-raw latex-pretty pdf png prep-pdf prep-png prep-html prep-latex

all: html latex

latex: latex-raw html latex-pretty

latex-pretty:
	@$(MKDIR) $(LATEX_PATH)-pretty
	@bash resource/prettify.sh "$(HTML_PATH)/forsyde-atom" "$(LATEX_PATH)/forsyde-atom" "$(LATEX_PATH)-pretty"
	@echo "Pretty version is in: $(LATEX_PATH)-pretty"

latex-raw: pdf prep-html prep-latex Makefile $(STYLE)
	@cd forsyde-atom \
	&& cabal sandbox init \
	&& cabal install --dependencies-only \
	&& cabal configure --with-haddock=../haddock/dist/build/haddock/haddock \
	&& (cabal haddock --haddock-options=--latex | awk 'END {print $$NF}' | xargs dirname | xargs -I {} mv {} ../$(LATEX_PATH))
	@find $(LATEX_PATH) -type f ! -name '*.tex' -delete
	@echo "Generated LaTeX API doc in $(LATEX_PATH)"


html: png prep-html Makefile $(STYLE)
	@cp -f png/* forsyde-atom/fig/
	@cd forsyde-atom \
	&& cabal sandbox init \
	&& cabal install --dependencies-only \
	&& cabal configure \
	&& (cabal haddock --hyperlink-source | awk 'END {print $$NF}' | xargs dirname | xargs -I {} mv {} ../$(HTML_PATH))
	@echo "Generated HTML API doc in $(HTML_PATH)"



pdf: prep-pdf $(PDF_FIGS)
png: pdf prep-png $(PNG_FIGS)

prep-pdf:
	@$(MKDIR) pdf
# TODO	LATEX_REPO

prep-png:
	@$(MKDIR) png

prep-html:
	@rm -rf $(HTML_PATH)	
	@$(MKDIR) $(HTML_PATH)
	@if [ ! -d forsyde-atom ]; then \
		git clone $(ATOM_REPO); \
		sed -i 's/-- extra-doc-files/extra-doc-files/g' forsyde-atom/forsyde-atom.cabal; \
		mkdir -p forsyde-atom/fig; \
	fi
	@if ! haddock --version; then cabal install haddock; fi
	@if ! hscolour --version; then cabal install hscolour; fi

prep-latex:
	@rm -rf $(LATEX_PATH)
	@$(MKDIR) $(LATEX_PATH)
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
