VERSION   = 1.0
OCAML     = ocaml
OCAMLC    = ocamlc
OCAMLOPT  = ocamlopt
OCAMLDOC  = ocamldoc -html -charset utf-8
OCAMLFIND = ocamlfind

LIBFILES  = timed.cmxa timed.cmxs timed.cma timed.a timed.o timed.cmi \
						timed.cmx timed_compat.cmxa timed_compat.cmxs timed_compat.cma \
						timed_compat.a timed_compat.o timed_compat.cmi timed_compat.cmx \
						timed.mli timed_compat.mli META 

.PHONY: all
all: $(LIBFILES) doc

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

timed_compat.cmi: timed_compat.mli
	@echo "[OPT] $@"
	@$(OCAMLOPT) -c $<

timed_compat.o: timed_compat.cmx
timed_compat.cmx: timed_compat.ml timed_compat.cmi
	@echo "[OPT] $@"
	@$(OCAMLOPT) -c $<

timed_compat.a: timed_compat.cmxa
timed_compat.cmxa: timed_compat.cmx
	@echo "[OPT] $@"
	@$(OCAMLOPT) -a -o $@ $^

timed_compat.cmxs: timed_compat.cmx
	@echo "[OPT] $@"
	@$(OCAMLOPT) -shared -o $@ $^

timed_compat.cmo: timed_compat.ml timed_compat.cmi
	@echo "[BYT] $@"
	@$(OCAMLC) -c $<

timed_compat.cma: timed_compat.cmo
	@echo "[BYT] $@"
	@$(OCAMLC) -a -o $@ $^

# Tests.

.PHONY: tests
tests: all
	@$(OCAML) -I . timed.cma tests/test.ml
	@$(OCAML) -I . timed.cma tests/test2.ml
	@$(OCAML) -I . timed.cma tests/example.ml
	@$(OCAML) -I . timed_compat.cma tests/test_compat.ml
	@$(OCAML) -I . timed_compat.cma tests/test2_compat.ml
	@$(OCAML) -I . timed_compat.cma tests/example_compat.ml
	@echo "[TST] All good!"

# Documentation.

doc: timed.mli timed_compat.mli
	@echo "[DOC] $@/index.html"
	@mkdir -p doc
	@$(OCAMLDOC) -hide-warnings -d $@ -html $^

# Installation.

META:
	@echo "[GEN] $@ (version $(VERSION))"
	@echo "name            = \"timed\""                                    > $@
	@echo "version         = \"$(VERSION)\""                              >> $@
	@echo "requires        = \"\""                                        >> $@
	@echo "description     = \"Timed references for imperative state\""   >> $@
	@echo "archive(byte)   = \"timed.cma\""                               >> $@
	@echo "plugin(byte)    = \"timed.cma\""                               >> $@
	@echo "archive(native) = \"timed.cmxa\""                              >> $@
	@echo "plugin(native)  = \"timed.cmxs\""                              >> $@
	@echo ""                                                              >> $@
	@echo "package \"compat\" ("                                          >> $@
	@echo "  version         = \"$(VERSION)\""                            >> $@
	@echo "  requires        = \"\""                                      >> $@
	@echo "  description     = \"Timed references compatibility module\"" >> $@
	@echo "  archive(byte)   = \"timed_compat.cma\""                      >> $@
	@echo "  plugin(byte)    = \"timed_compat.cma\""                      >> $@
	@echo "  archive(native) = \"timed_compat.cmxa\""                     >> $@
	@echo "  plugin(native)  = \"timed_compat.cmxs\""                     >> $@
	@echo ")"                                                             >> $@

.PHONY: install
install: $(LIBFILES) uninstall
	@$(OCAMLFIND) install timed $(LIBFILES)

.PHONY: uninstall
uninstall:
	@$(OCAMLFIND) remove timed

.PHONY: release
release: distclean
	@echo "[TAG] ocaml-timed_$(VERSION)"
	@git push origin
	@git tag -a ocaml-timed_$(VERSION)
	@git push origin ocaml-timed_$(VERSION)

# Cleaning.

.PHONY: clean
clean:
	@rm -f *.cm[ixoa] *.cmxa *.cmxs *.a *.o

.PHONY: distclean
distclean: clean
	@find . -name "*~" -exec rm {} \;
	@rm -rf doc META
