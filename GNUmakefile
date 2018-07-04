VERSION   = 0.1
OCAML     = ocaml
OCAMLC    = ocamlc
OCAMLOPT  = ocamlopt
OCAMLDOC  = ocamldoc -html -charset utf-8
OCAMLFIND = ocamlfind

.PHONY: all
all: timed.cmxa timed.cmxs timed.cma doc

# Compilation of the library.

timed.cmi: timed.mli
	@echo "[OPT] $@"
	@$(OCAMLOPT) -c $<

timed.o: timed.cmx
timed.cmx: timed.ml timed.cmi
	@echo "[OPT] $@"
	@$(OCAMLOPT) -c $<

timed.a: timed.cmxa
timed.cmxa: timed.cmx
	@echo "[OPT] $@"
	@$(OCAMLOPT) -a -o $@ $^

timed.cmxs: timed.cmx
	@echo "[OPT] $@"
	@$(OCAMLOPT) -shared -o $@ $^

timed.cmo: timed.ml timed.cmi
	@echo "[BYT] $@"
	@$(OCAMLC) -c $<

timed.cma: timed.cmo
	@echo "[BYT] $@"
	@$(OCAMLC) -a -o $@ $^

# Tests.

.PHONY: tests
tests: all
	@$(OCAML) -I . timed.cma tests/test.ml
	@$(OCAML) -I . timed.cma tests/test2.ml
	@$(OCAML) -I . timed.cma tests/example.ml

# Documentation.

doc: timed.mli
	@echo "[DOC] $@/index.html"
	@mkdir -p doc
	@$(OCAMLDOC) -hide-warnings -d $@ -html $^

# Installation.

META:
	@echo "name            = \"timed\""                                  > $@
	@echo "version         = \"$(VERSION)\""                            >> $@
	@echo "requires        = \"\""                                      >> $@
	@echo "description     = \"Timed references for imperative state\"" >> $@
	@echo "archive(byte)   = \"timed.cma\""                             >> $@
	@echo "plugin(byte)    = \"timed.cma\""                             >> $@
	@echo "archive(native) = \"timed.cmxa\""                            >> $@
	@echo "plugin(native)  = \"timed.cmxs\""                            >> $@

INSTALLED = timed.cmxa timed.cmxs timed.cma timed.a timed.o timed.cmi \
						timed.cmx META 

.PHONY: install
install: $(INSTALLED) uninstall
	@$(OCAMLFIND) install timed $(INSTALLED)

.PHONY: uninstall
uninstall:
	@$(OCAMLFIND) remove timed

# Cleaning.

.PHONY: clean
clean:
	@rm -f timed.cm[ixoa] timed.cmxa timed.cmxs timed.a timed.o

.PHONY: distclean
distclean: clean
	@find . -name "*~" -exec rm {} \;
	@rm -rf doc META
