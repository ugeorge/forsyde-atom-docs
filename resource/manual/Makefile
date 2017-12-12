# Directory structure
TEXDIR:=./input
STYDIR:=./sty
BIBDIR:=./
REPODIR:=/home/ugeorge/Work/forsyde-atom-examples

# Project-specific settings
REPORTS = $(REPODIR)/getting-started $(REPODIR)/hybrid
DOCNAME = manual
TITLEPG = title

# Tools
MAKE = make
RM = rm -f
CP = cp
MV = mv
MKDIR = mkdir -p
OPEN = evince

BIBFILES     = $(wildcard $(BIBDIR)/*.bib)
TEXFILES     = $(wildcard $(TEXDIR)/*.tex)
STYLEFILES   = $(wildcard $(STYDIR)/*.sty)

.PHONY: manual reports $(REPORTS) title doc view clean superclean

# Targets
manual: reports title doc

reports: $(REPORTS)
title: $(TITLEPG).pdf
doc: $(DOCNAME).pdf

view: manual
	@$(OPEN) $(DOCNAME).pdf


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
	@$(RM) -f $(DOCNAME).pdf
	@for report in $(REPORTS); do \
		@$(MAKE) -C $@ clean-docs \
	done

# Rules

$(REPORTS):
	@$(MAKE) -C $@ report

$(TITLEPG).pdf:
	pdflatex --shell-escape $(TITLEPG)  $(LOGFILE)


$(DOCNAME).pdf: $(DOCNAME).tex \
		$(TEXFILES) $(STYLEFILES) $(BIBFILES) \
                $(DOCNAME).bbl Makefile
	pdflatex --shell-escape $(DOCNAME) $(LOGFILE)
	biber $(DOCNAME)  $(LOGFILE)
	makeindex $(DOCNAME)  $(LOGFILE)
	pdflatex $(DOCNAME)  $(LOGFILE)
	@while ( grep "Rerun to get cross-references" 	\
	$(DOCNAME).log $(LOGFILE) ); do		\
	        echo '** Re-running LaTeX **';		\
	        pdflatex $(DOCNAME) $(LOGFILE);        \
	done

$(DOCNAME).bbl : $(DOCNAME).tex $(BIBFILES)
	pdflatex $(DOCNAME).tex $(LOGFILE)
	biber $(DOCNAME) $(LOGFILE)

