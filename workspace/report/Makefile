# =============================================================================
# ECE260B Project Report — LaTeX build (sources in ./src)
# =============================================================================
#   make compile   — pdflatex + bibtex + pdflatex x2
#   make clean     — remove auxiliary files (keeps main.pdf)
#   make distclean — clean + remove main.pdf
#
# Requires: pdflatex, bibtex (TeX Live / MiKTeX)
# Optional: latexmk (if LATEXMK=1 or set in environment)
# =============================================================================

SRCDIR   := src
MAIN     := main
TEX      := $(SRCDIR)/$(MAIN).tex
PDF      := $(SRCDIR)/$(MAIN).pdf

LATEXMK  ?= 0

.PHONY: compile clean distclean fiximgpaths help

help:
	@echo "Targets:"
	@echo "  make compile     - Build $(PDF)"
	@echo "  make clean       - Remove LaTeX aux files in $(SRCDIR)/"
	@echo "  make distclean   - clean + remove $(PDF)"
	@echo "  make fiximgpaths - Rename Step N images/ dirs (spaces) to StepN_images/ (see README)"
	@echo ""
	@echo "Optional: LATEXMK=1 make compile  (uses latexmk if installed)"

# Overleaf exports often use "Step 1 images/" etc.; spaces confuse some pdfTeX setups.
# After re-importing sources, run: make fiximgpaths
# then ensure main.tex uses Step1_images/, Step3_images/, Step4_images/ in \\includegraphics.
fiximgpaths:
	@cd $(SRCDIR) && [ -d "Step 1 images" ] && mv "Step 1 images" Step1_images && echo "renamed: Step 1 images -> Step1_images" || true
	@cd $(SRCDIR) && [ -d "Step 3 images" ] && mv "Step 3 images" Step3_images && echo "renamed: Step 3 images -> Step3_images" || true
	@cd $(SRCDIR) && [ -d "Step 4 images" ] && mv "Step 4 images" Step4_images && echo "renamed: Step 4 images -> Step4_images" || true

compile:
	@if [ ! -f "$(TEX)" ]; then \
		echo "ERROR: $(TEX) not found. Populate $(SRCDIR)/ with your LaTeX sources first."; \
		exit 1; \
	fi
ifeq ($(LATEXMK),1)
	@command -v latexmk >/dev/null 2>&1 || { echo "latexmk not found; use: make compile"; exit 1; }
	cd $(SRCDIR) && latexmk -pdf -interaction=nonstopmode -halt-on-error $(MAIN).tex
else
	cd $(SRCDIR) && pdflatex -interaction=nonstopmode -file-line-error $(MAIN).tex
	cd $(SRCDIR) && bibtex $(MAIN)
	cd $(SRCDIR) && pdflatex -interaction=nonstopmode -file-line-error $(MAIN).tex
	cd $(SRCDIR) && pdflatex -interaction=nonstopmode -file-line-error $(MAIN).tex
endif
	@echo ""
	@echo ">>> Output: $(PDF) <<<"

clean:
	rm -f $(SRCDIR)/*.aux $(SRCDIR)/*.bbl $(SRCDIR)/*.blg $(SRCDIR)/*.log \
	      $(SRCDIR)/*.out $(SRCDIR)/*.toc $(SRCDIR)/*.lof $(SRCDIR)/*.lot \
	      $(SRCDIR)/*.fdb_latexmk $(SRCDIR)/*.fls $(SRCDIR)/*.synctex.gz \
	      $(SRCDIR)/*.bcf $(SRCDIR)/*.run.xml

distclean: clean
	rm -f $(PDF)
