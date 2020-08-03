MKDIR        := mkdir -p
ATOM_REPO    := git@github.com:ugeorge/forsyde-atom.gi
EXAMP_REPO   := git@github.com:ugeorge/forsyde-atom-examples.git

HTML_PATH:=api/html
LATEX_PATH:=api/latex
PRETTY_PATH:=api/latex-pretty

FILES = eqs-exb misc \
	eqs-moc moc moc-sy moc-de moc-re moc-ct moc-sdf moc-ddf \
	eqs-skel skel eqs-skel-vector skel-vector-func \
	skel-vector-comm

target-format=pdf/$(1)-$(2).pdf

##################### DO NOT CHANGE FROM HERE #####################

WORKSPACE = gh-pages forsyde-atom examples api
WWW_PATH = gh-pages/api
ATOM_LIB = forsyde-atom/dist
DUMP_SRC = atom-docplots/Main.hs
DUMP_BIN = atom-docplots
CABAL = stack exec --no-ghc-package-path -- cabal


STYLE = $(wildcard tex/*.sty)
FLX_DUMP = $(sort $(foreach file,$(DUMP_SRC),$(call make-flx-targets,$(file))))
PDF_SRCS = $(foreach file,$(FILES),$(call make-pdf-targets,$(file)))
PDF_FIGS = $(sort $(foreach file,$(FILES),$(call make-pdf-targets,$(file))))
PNG_FIGS = $(patsubst pdf/%.pdf, png/%.png, $(PDF_SRCS))
ATOM_SRCS = $(shell find forsyde-atom/src -type f -name '*.hs') forsyde-atom/forsyde-atom.cabal

# ATOM_VER = $(shell cd forsyde-atom && git describe --tags | sed 's|-.*$$||g')
ATOM_VER = $(shell sed -n -e 's/^version: *//p' forsyde-atom/forsyde-atom.cabal)

#### FUNCTIONS ####

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

# Extracts plot file names from TeX files
# 1. path to TeX file
get-plot-names=$(shell grep -oP "(?<=labels = \[).*(?=\])" $(1) | sed 's/"//g' | sed 's/,//g')

# Makes target PDF names with figure names extracted.
# 1. path to Haskell file
make-flx-targets=$(patsubst %, tex/data/%.flx, $(call get-plot-names, $(1)))

#### TEMPLATES ####

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

define flx-template
  $(2) : $(1) $(ATOM_LIB)
	cd atom-docplots && stack install
	$(DUMP_BIN)
	@rm -rf tex/data
	@mv data tex
endef

#### TARGETS ####


.PHONY: workspace html pdf png gh-pages remove check

workspace:
#	checking dependencies
	@echo "* checking dependencies..."
	@if ! stack --version; then echo "Could not find stack! Aborting."; exit 1; fi
	@test -f $(shell kpsewhich --all forsyde.sty) \
	    || (echo "Could not find ForSyDe-LaTex. Please install it from https://forsyde.github.io/forsyde-latex/"; exit 1)
#       creating folders
	@echo "* creating folders..."
	@if [ ! -d forsyde-atom ]; then git clone $(ATOM_REPO) -b docs; fi
	@if [ ! -d gh-pages ]; then git clone $(ATOM_REPO) -b gh-pages gh-pages; fi
	@if [ ! -d examples ]; then git clone $(EXAMP_REPO) examples; fi
	@$(MKDIR) api
	@$(MKDIR) png
	@$(MKDIR) pdf
#       preparing forsyde-atom for generating documentation
	@echo "* preparing ForSyDe-Atom for generating docs..."
	@sed -i 's/-- extra-doc-files/extra-doc-files/g' forsyde-atom/forsyde-atom.cabal;
	@mkdir -p forsyde-atom/fig;
	@touch forsyde-atom/fig/phony.png;

pdf: check $(FLX_DUMP) $(STYLE) $(PDF_FIGS)

png: pdf $(PNG_FIGS)

html: png Makefile $(STYLE)
	@rm -rf $(HTML_PATH)
	@cp -f png/* forsyde-atom/fig/
	cd forsyde-atom \
	&& ($(CABAL) haddock --haddock-html-location='https://hackage.haskell.org/package/$$pkg-$$version/docs' \
	--haddock-hyperlink-source --haddock-quickjump  \
	| awk 'END {print $$NF}' | xargs dirname \
	| xargs -I {} mv {} ../$(HTML_PATH)) \
	&& echo "Generated HTML API doc in '$(HTML_PATH)'"

www: html
	@rm -rf $(WWW_PATH)/*
	@cp -r $(HTML_PATH)/* $(WWW_PATH)/
	@for f in $(WWW_PATH)/*.html; do\
	    grep -Pzo "(?s)(?<=\<body\>).*?(?=\</body\>)" $$f > tmp && mv tmp $$f; \
	    echo "---\nlayout: haddock\n---\n" | cat - $$f > tmp && mv tmp $$f; \
	done
	@echo "Integrated HTML page into ForSyDe website at '$(WWW_PATH)'"

# www-distro: www
# 	@rsync --include "*/" --exclude="*" --include="*.hs" forsyde-atom/src/ gh-pages/src/
# 	@cd gh-pages && git add src && git commit -m "updated documentation (*auto)" && git push origin master
# 	@cd work && git stash && git pull origin master
#	    perl -0777 -i -pe 's/<div id="synopsis.*?<\/div>//g' $$f ; \

#### RULES ####

# generate rules for ForSyDe-Latex plot data
$(eval $(call flx-template,$(DUMP_SRC),$(call make-flx-targets,$(DUMP_SRC))))

# generate rules for PDF figures
$(foreach file,$(FILES),\
	$(eval $(call pdf-template,$(file),$(call make-pdf-targets,$(file)))))

# Rule for PNG figures: convert
png/%.png: pdf/%.pdf
	@echo $@
#	@convert -density 150 $< -quality 90 $@
	pdftoppm $< $(basename $@) -png -f 1 -singlefile

$(ATOM_LIB): $(ATOM_SRCS)
	cd forsyde-atom \
	&& stack install


# .PHONY: manual html latex-raw latex-pretty pdf png prep-pdf prep-png prep-html prep-latex prep-atom

# manual:
# 	@test -f manual/input/ForSyDe-Atom.tex || echo \
# 		"Manual not set up yet. Run 'make prep-manual'"
# 	make -C manual REPODIR=$(EXAMP_PATH)


# latex-pretty:
# 	@test -d $(HTML_PATH) || echo "Run 'make html' first"
# 	@test -d $(LATEX_PATH) || echo "Run 'make latex-raw' first"
# 	@$(MKDIR) $(PRETTY_PATH)
# 	@bash resource/prettify.sh $(HTML_PATH) $(LATEX_PATH) $(PRETTY_PATH)
# 	@echo "Pretty version is in: $(PRETTY_PATH)"

# latex-raw: prep-html prep-latex Makefile $(STYLE)
# 	@cd forsyde-atom \
# 	&& cabal sandbox init \
# 	&& cabal install --dependencies-only \
# 	&& cabal configure --with-haddock=../haddock/dist/build/haddock/haddock \
# 	&& (cabal haddock --haddock-options=--latex | awk 'END {print $$NF}' | xargs dirname | xargs -I {} mv {} ../$(LATEX_PATH))
# 	@find $(LATEX_PATH) -type f ! \( -iname \*.tex -o -iname \*.sty \) -delete
# 	@echo "Generated LaTeX API doc in $(LATEX_PATH)"


#	&& (stack haddock \
#	    | awk 'END {print $$NF}' | xargs dirname | xargs -I {} mv {} ../$(HTML_PATH)) \

# ###### PREPS

# prep-pdf: dump-plots
# 	@$(MKDIR) pdf
# 	@test -f $(shell kpsewhich --all forsyde.sty) || echo \
# "Installation did not succeed! Refer to the user manual for installing the package manually."

# dump-plots: $(DUMP_BIN)
# 	@cd atom-docplots && cabal build -j4
# 	./$(DUMP_BIN)
# 	@rm -rf tex/data
# 	@mv data tex

# $(DUMP_BIN): prep-atom
# 	@cd atom-docplots \
# 	  && cabal sandbox init \
# 	  && cabal sandbox add-source ../forsyde-atom \
# 	  && cabal install \
# 	  && cabal build -j4

# prep-png:
# 	@$(MKDIR) png

# prep-html: prep-atom
# 	@$(MKDIR) $(API_PATH)
# 	@rm -rf $(HTML_PATH)
# 	@if ! haddock --version; then cabal install haddock; fi
# 	@if ! hscolour --version; then cabal install hscolour; fi

# prep-atom:
# 	@if [ ! -d forsyde-atom ]; then \
# 		git clone $(ATOM_REPO); \
# 		sed -i 's/-- extra-doc-files/extra-doc-files/g' forsyde-atom/forsyde-atom.cabal; \
# 		mkdir -p forsyde-atom/fig; \
# 		touch forsyde-atom/fig/phony.png; \
# 	fi


# prep-latex:
# 	@$(MKDIR) $(API_PATH)
# 	@rm -rf $(LATEX_PATH)
# 	@if [ ! -d haddock ]; then \
# 		git clone $(HADOCK_REPO); \
# 		cd haddock \
# 		&& cabal sandbox init \
# 		&& cabal sandbox add-source haddock-library \
# 		&& cabal sandbox add-source haddock-api \
# 		&& cabal sandbox add-source haddock-test \
# 		&& cabal install -j4 --dependencies-only \
# 		&& cabal configure \
# 		&& cabal build -j4; \
# 	fi

# prep-manual: html latex-raw latex-pretty 
# 	@:$(call check_defined, EXAMP_PATH, full path to forsyde-atom-examples)
# 	@test -d $(EXAMP_PATH) || echo \
# 		"Please define EXAMP_PATH. The current one is not a valid path : $(EXAMP_PATH)"
# #	@cp -rf resource/manual .
# 	@cp -f $(PRETTY_PATH)/*.tex manual/input/
# 	@mkdir -p manual/fig
# 	@cp -f pdf/*.pdf manual/fig/
# 	@echo "\\\newcommand*{\\AtomExamplesRoot}{$(EXAMP_PATH)}" > manual/sty/atom-vars.sty
# 	@echo "\\\newcommand*{\\AtomVersion}{kkkkkk}" | sed 's/kkkkkk/'"$(ATOM_VER)"'/g' >> manual/sty/atom-vars.sty

# prep-manual-quick: pdf 
# 	@:$(call check_defined, EXAMP_PATH, full path to forsyde-atom-examples)
# 	@test -d $(EXAMP_PATH) || echo \
# 		"Please define EXAMP_PATH. The current one is not a valid path : $(EXAMP_PATH)"
# 	@cp -rf resource/manual .
# 	@mkdir -p manual/fig
# 	@cp -f pdf/*.pdf manual/fig/
# 	@echo "\\\newcommand*{\\AtomExamplesRoot}{$(EXAMP_PATH)}" > manual/sty/atom-vars.sty
# 	@echo "\\\newcommand*{\\AtomVersion}{kkkkkk}" | sed 's/kkkkkk/'"$(ATOM_VER)"'/g' >> manual/sty/atom-vars.sty



## EXTRA TARGETS ##

clean:
	rm -f log tmp
	rm -rf api

remove: clean
	rm -rf $(WORKSPACE)
	cd atom-docplots && cabal sandbox delete && rm -rf dist

check:
	@for dir in $(WORKSPACE); do test -d ${dir} \
	    || (echo "Could not find $dir. Please run 'make workspace'"; exit 1); \
	done

test:
	cd forsyde-atom \
	&& stack haddock  2>&1 | grep 'doc/index' | grep 'forsyde-atom' | xargs dirname | xargs -I {} ls {}/forsyde-atom-$(ATOM_VER)
	echo $(ATOM_VER)

COMMIT_MSG1 ?= $(shell bash -c 'read -p "Message for forsyde-atom-docs: " msg; echo $$msg')
COMMIT_MSG2 ?= $(shell bash -c 'read -p "Message for forsyde-atom: " msg; echo $$msg')

dev-push:
	@git add .
	@git commit -m "$(COMMIT_MSG1)"
	@git push origin master
	cd forsyde-atom \
	&& git add src forsyde-atom.cabal \
	&& git commit -m "$(COMMIT_MSG2)" \
	&& git push origin docs
