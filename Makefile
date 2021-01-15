#  Copyright (c) 2020 by Laboratoire Spécification et Vérification (LSV),
#  CNRS UMR 8643 & ENS Paris-Saclay.
#  Written by Amélie Ledein
#  Adapted by Neven Villani

%.cmo: %.ml
	ocamlc -g -c $<

%.cmi: %.mli
	ocamlc -g -c $<

# build artifacts
CAMLOBJS=error.cmo cAST.cmo pigment.cmo reduce.cmo cprint.cmo \
	cparse.cmo clex.cmo verbose.cmo generate.cmo compile.cmo \
	main.cmo

# src files
CAMLSRC=$(addsuffix .ml,$(basename $(CAMLOBJS)))

# archive directory
PJ=VILLANI_NEVEN-FULL

# non-generated files
SRC=clex.mll cAST.ml cAST.mli cparse.mly \
	pigment.ml pigment.mli cprint.ml cprint.mli \
	generate.ml generate.mli reduce.ml reduce.mli \
	verbose.ml verbose.mli compile.ml compile.mli \
	error.ml main.ml
AUX=Makefile README.md check.py
DOCS=report.pdf semantics.pdf
TESTS=tests failures verify

# main build
mcc: $(CAMLOBJS)
	ocamlc -g -o mcc unix.cma $(CAMLOBJS)

clean:
	rm -f mcc *.cmi *.cmo || echo "Nothing to remove"
	rm -f cparse.ml cparse.mli clex.ml || echo "Nothing to remove"
	rm -f cparse.output || echo "Nothing to remove"
	rm -f depend || echo "Nothing to remove"
	rm -rf $(PJ).tar.gz $(PJ) || echo "Nothing to remove"
	find . -name '*.s' -type f -exec rm {} +
	find tests ! -name '*.*' -type f -exec rm {} +
	find failures ! -name '*.*' -type f -exec rm {} +
	rm docs/*.log docs/*.aux docs/*.out || echo "Nothing to remove"

# create and compress final assignment
project:
	make clean
	mkdir $(PJ)
	cp -r $(TESTS) $(PJ)/
	cp $(SRC) $(PJ)/
	cp $(AUX) $(PJ)/
	cp -r $(DOCS) $(PJ)/
	tar czf $(PJ).tar.gz $(PJ)

# automatic tester
test: mcc
	python3 check.py

# LaTeX arguments
TEX_ARGS=--interaction=nonstopmode --halt-on-error
PDFLATEX_ARGS=$(TEX_ARGS)
LUALATEX_ARGS=$(TEX_ARGS) --shell-escape

semantics:
	cd docs ; \
		pdflatex $(PDFLATEX_ARGS) semantics.tex
	mv docs/semantics.pdf .

report:
	cd docs ; \
		lualatex $(LUALATEX_ARGS) report.tex
	mv docs/report.pdf .

# lex & parse
cparse.ml: cparse.mly
	ocamlyacc -v cparse.mly

clex.ml: clex.mll
	ocamllex clex.mll

compile.cmi: compile.mli
compile.cmo: compile.ml compile.cmi

depend: Makefile $(wildcard *.ml) $(wildcard *.mli) cparse.ml clex.ml
	ocamldep *.mli *.ml > depend

-include depend
