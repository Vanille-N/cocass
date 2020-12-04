#  Copyright (c) 2020 by Laboratoire Spécification et Vérification (LSV),
#  CNRS UMR 8643 & ENS Paris-Saclay.
#  Written by Amélie Ledein

%.cmo: %.ml
	ocamlc -g -c $<

%.cmi: %.mli
	ocamlc -g -c $<

.PHONY: all ProjetCOCass.tar.gz

# Compilation parameters:
CAMLOBJS=error.cmo cAST.cmo pigment.cmo reduce.cmo cprint.cmo \
	cparse.cmo clex.cmo verbose.cmo genlab.cmo generate.cmo compile.cmo \
	main.cmo
CAMLSRC=$(addsuffix .ml,$(basename $(CAMLOBJS)))
PJ=ProjetCOCass
FILES=clex.mll cAST.ml cAST.mli cparse.mly \
	  pigment.ml pigment.mli \
	  generate.ml generate.mli \
	  reduce.ml reduce.mli \
	  compile.ml compile.mli \
	  cprint.ml cprint.mli \
	  error.ml verbose.ml genlab.ml main.ml Makefile

all: mcc

projet: ProjetCOCass.tar.gz

mcc: $(CAMLOBJS)
	ocamlc -g -o mcc unix.cma $(CAMLOBJS)

clean:
	rm -f mcc *.cmi *.cmo
	rm -f cparse.ml cparse.mli clex.ml
	rm -f cparse.output
	rm -f depend
	rm -rf ProjetCOCass.tar.gz $(PJ)
	rm -rf Test/
	rm -rf assets/*.s
	rm -rf failures/*.s
	find assets ! -name '*.*' -type f -exec rm {} +
	find failures ! -name '*.*' -type f -exec rm {} +
	rm -rf NVILLANI-COCass

test: projet.tar.gz
	-mkdir Test
	-rm -rf Test/*
	cp ProjetCOCass.tar.gz Test/
	(cd Test/; tar -xvzf ProjetCOCass.tar.gz; cd ProjetCOCass/; cp ~/Papers/compile.ml .; make; cp mcc ~/bin)

ProjetCOCass.tar.gz:
	rm -rf $(PJ) && mkdir $(PJ)
	cp $(FILES) $(PJ)
	-mkdir $(PJ)/Exemples
	cp assets/*.c $(PJ)/Exemples
	cp cprint_skel.ml $(PJ)/cprint.ml
	cp compile_skel.ml $(PJ)/compile.ml
	tar -cvzf $@ $(PJ)

final:
	make clean
	mkdir NVILLANI-COCass
	mkdir NVILLANI-COCass/Exemples
	cp assets/* NVILLANI-COCass/Exemples/
	mkdir NVILLANI-COCass/Erreurs
	cp failures/* NVILLANI-COCass/Erreurs/
	cp $(FILES) NVILLANI-COCass/
	tar czf NVILLANI-COCass.tar.gz NVILLANI-COCass

P1=../boostrap
P2=../../2/boostrap
p2_links:
	@echo Populating $(P2) with links for missing files...
	@mkdir -p $(P2)
	@for f in $(FILES) compile_skel.ml cprint_skel.ml ; do \
	  test -f $(P2)/$$f || (echo Linking $$f... ; ln $(P1)/$$f $(P2)/$$f) ; done
	@mkdir -p $(P2)/Exemples
	@for f in Exemples/*.c ; do \
	  test -f $(P2)/$$f || (echo Linking $$f... ; ln $(P1)/$$f $(P2)/$$f) ; done

cparse.ml: cparse.mly
	ocamlyacc -v cparse.mly

clex.ml: clex.mll
	ocamllex clex.mll

compile.cmi: compile.mli
compile.cmo: compile.ml compile.cmi

depend: Makefile $(wildcard *.ml) $(wildcard *.mli) cparse.ml clex.ml
	ocamldep *.mli *.ml > depend

-include depend
