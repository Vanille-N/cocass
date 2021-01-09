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
PJ=NVILLANI-COCass

# non-generated files
FILES=clex.mll cAST.ml cAST.mli cparse.mly \
	  pigment.ml pigment.mli \
	  generate.ml generate.mli \
	  reduce.ml reduce.mli \
	  compile.ml compile.mli \
	  cprint.ml cprint.mli \
	  error.ml verbose.ml verbose.mli main.ml \
	  Makefile README.md test.py

# test-related directories
TESTS=assets failures verify

# main beild
mcc: $(CAMLOBJS)
	ocamlc -g -o mcc unix.cma $(CAMLOBJS)

clean:
	rm -f mcc *.cmi *.cmo
	rm -f cparse.ml cparse.mli clex.ml
	rm -f cparse.output
	rm -f depend
	rm -rf $(PJ).tar.gz $(PJ)
	find . -name '*.s' -type f -exec rm {} +
	find assets ! -name '*.*' -type f -exec rm {} +
	find failures ! -name '*.*' -type f -exec rm {} +
	rm docs/*.log docs/*.aux docs/*.out

# create and compress final assignment
projet:
	make clean
	mkdir $(PJ)
	cp -r $(TESTS) $(PJ)/
	cp $(FILES) $(PJ)/
	tar czf $(PJ).tar.gz $(PJ)

# automatic tester
test: mcc
	./check.py

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
