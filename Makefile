#  Copyright (c) 2020 by Laboratoire Spécification et Vérification (LSV),
#  CNRS UMR 8643 & ENS Paris-Saclay.
#  Written by Amélie Ledein

%.cmo: %.ml
	ocamlc -g -c $<

%.cmi: %.mli
	ocamlc -g -c $<

.PHONY: all

# Compilation parameters:
CAMLOBJS=error.cmo cAST.cmo pigment.cmo reduce.cmo cprint.cmo \
	cparse.cmo clex.cmo verbose.cmo genlab.cmo generate.cmo compile.cmo \
	main.cmo
CAMLSRC=$(addsuffix .ml,$(basename $(CAMLOBJS)))
PJ=NVILLANI-COCass
FILES=clex.mll cAST.ml cAST.mli cparse.mly \
	  pigment.ml pigment.mli \
	  generate.ml generate.mli \
	  reduce.ml reduce.mli \
	  compile.ml compile.mli \
	  cprint.ml cprint.mli \
	  error.ml verbose.ml genlab.ml main.ml \
	  Makefile README.md test.py
TESTS=assets failures verify

all: mcc

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

projet:
	make clean
	mkdir $(PJ)
	cp -r $(TESTS) $(PJ)/
	cp $(FILES) $(PJ)/
	tar czf $(PJ).tar.gz $(PJ)

test: mcc
	./test.py

tex:
	pdflatex --interaction=nonstopmode --halt-on-error semantics.tex

cparse.ml: cparse.mly
	ocamlyacc -v cparse.mly

clex.ml: clex.mll
	ocamllex clex.mll

compile.cmi: compile.mli
compile.cmo: compile.ml compile.cmi

depend: Makefile $(wildcard *.ml) $(wildcard *.mli) cparse.ml clex.ml
	ocamldep *.mli *.ml > depend

-include depend
