#  Copyright (c) 2005 by Laboratoire Spécification et Vérification (LSV),
#  CNRS UMR 8643 & ENS Cachan.
#  Written by Jean Goubault-Larrecq.  Derived from the csur project.
#
#  Permission is granted to anyone to use this software for any
#  purpose on any computer system, and to redistribute it freely,
#  subject to the following restrictions:
#
#  1. Neither the author nor its employer is responsible for the consequences
#     of use of this software, no matter how awful, even if they arise
#     from defects in it.
#
#  2. The origin of this software must not be misrepresented, either
#     by explicit claim or by omission.
#
#  3. Altered versions must be plainly marked as such, and must not
#     be misrepresented as being the original software.
#
#  4. This software is restricted to non-commercial use only.  Commercial
#     use is subject to a specific license, obtainable from LSV.

%.cmo: %.ml
	ocamlc -g -c $<

%.cmi: %.mli
	ocamlc -g -c $<

.PHONY: all projet.tar.gz

# Compilation parameters:
CAMLOBJS=error.cmo cparse.cmo cprint.cmo \
	ctab.cmo clex.cmo verbose.cmo genlab.cmo compile.cmo \
	main.cmo
CAMLSRC=$(addsuffix .ml,$(basename $(CAMLOBJS)))
PJ=ProjetMiniC
FILES=clex.mll cparse.ml cparse.mli ctab.mly \
	  compile.ml compile.mli \
	  cprint.ml cprint.mli \
	  error.ml verbose.ml genlab.ml main.ml Makefile

all: mcc

projet: projet.tar.gz

mcc: $(CAMLOBJS)
	ocamlc -g -o mcc unix.cma $(CAMLOBJS)

clean:
	rm -f mcc *.cmi *.cmo
	rm -f ctab.ml ctab.mli clex.ml
	rm -rf projet.tar.gz $(PJ)
	rm -rf Test/

test: projet.tar.gz
	-mkdir Test
	-rm -rf Test/*
	cp projet.tar.gz Test/
	(cd Test/; tar -xvzf projet.tar.gz; cd ProjetMiniC/; cp ~/Papers/compile.ml .; make; cp mcc ~/bin)

projet.tar.gz:
	rm -rf $(PJ) && mkdir $(PJ)
	cp $(FILES) $(PJ)
	-mkdir $(PJ)/Exemples
	cp Exemples/*.c $(PJ)/Exemples
	cp cprint_skel.ml $(PJ)/cprint.ml
	cp compile_skel.ml $(PJ)/compile.ml
	tar -cvzf $@ $(PJ)

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

ctab.ml: ctab.mly
	ocamlyacc -v ctab.mly

clex.ml: clex.mll
	ocamllex clex.mll

compile.cmi: compile.mli
compile.cmo: compile.ml compile.cmi

depend: Makefile $(wildcard *.ml) $(wildcard *.mli) ctab.ml clex.ml
	ocamldep *.mli *.ml > depend

-include depend
