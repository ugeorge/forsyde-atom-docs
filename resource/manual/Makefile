# Directory structure
UTILSDIR	= ..
STYDIR		= ..
BIBDIR		= ../docfiles
REPODIR         = ../..

# Project-specific settings
REPORTS = $(REPODIR)/getting-started $(REPODIR)/hybrid
DOCNAME = manual
TITLEPG = title

# Dependencies
DEPDIR   := $(REPODIR)/.deps

ATOM_VER := 0.2.2
ATOM_LIB := $(DEPDIR)/forsyde-atom-v$(ATOM_VER)
ATOM_URL := -b $(ATOM_VER) https://github.com/forsyde/forsyde-atom.git

LATEX_LIB := $(DEPDIR)/forsyde-latex
LATEX_URL := -b dev-atom https://github.com/forsyde/forsyde-latex.git

HADDOCK_LIB := $(DEPDIR)/haddock
HADDOCK_URL := https://github.com/ugeorge/haddock.git

# Tools
MAKE = make
RM = rm -f
CP = cp
MV = mv
MKDIR = mkdir -p
OPEN = evince

BIBFILES     = $(wildcard $(BIBDIR)/*.bib)
TEXFILES     = $(wildcard $(UTILSDIR)/*.tex)
STYLEFILES   = $(wildcard $(STYDIR)/*.sty)

.PHONY: manual reports $(REPORTS) title doc view clean superclean

# Targets
manual: reports title doc

reports: $(REPORTS)
title: $(TITLEPG).pdf
doc: ../../$(DOCNAME).pdf

view: manual
	@$(OPEN) ../../$(DOCNAME).pdf


api-deps:
	@mkdir -p $(DEPDIR)
	@if [ ! -d $(LATEX_LIB) ]; then \
		git clone $(LATEX_URL) $(LATEX_LIB); \
	fi
	@if [ ! -d $(ATOM_LIB) ]; then \
		git clone $(ATOM_URL) $(ATOM_LIB); \
	fi
	cd $(LATEX_LIB) && ./install.sh
	@if [ ! -d $(HADDOCK_LIB) ]; then \
		git clone $(HADDOCK_URL) $(HADDOCK_LIB); \
	fi
	cd $(LATEX_LIB) && ./install.sh



clean:
	@$(RM) *.aux *~ *.log *.gz *.dvi *.blg *.bbl *.tmp \
		*.thm *.toc *.lo* *# *.mtc* *.out *.xml \
		*.maf *.bcf comment.cut

superclean: clean
	@$(RM) -f $(TITLEPG).pdf
	@$(RM) -f ../../$(DOCNAME).pdf
	@for report in $(REPORTS); do \
		@$(MAKE) -C $@ clean-docs \
	done

# Rules

$(REPORTS):
	@$(MAKE) -C $@ report

$(TITLEPG).pdf:
	pdflatex --shell-escape $(TITLEPG)  > /dev/null


../../$(DOCNAME).pdf: $(DOCNAME).tex \
		$(TEXFILES) $(STYLEFILES) $(BIBFILES) \
                $(DOCNAME).bbl Makefile
	pdflatex --shell-escape $(DOCNAME) > /dev/null
	biber $(DOCNAME)  > /dev/null
	pdflatex $(DOCNAME)  > /dev/null
	@while ( grep "Rerun to get cross-references" 	\
	$(DOCNAME).log > /dev/null ); do		\
	        echo '** Re-running LaTeX **';		\
	        pdflatex $(DOCNAME) > /dev/null;        \
	done
	@mv $(DOCNAME).pdf ../../

$(DOCNAME).bbl : $(DOCNAME).tex $(BIBFILES)
	pdflatex $(DOCNAME).tex > /dev/null
	biber $(DOCNAME) > /dev/null

