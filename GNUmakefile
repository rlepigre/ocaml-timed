all: timed.cmxa timed.cmxs timed.cma

# Compilation of the library.

timed.cmi: timed.mli
	@echo "[OPT] $@"
	@ocamlopt -c $<

timed.o: timed.cmx
timed.cmx: timed.ml timed.cmi
	@echo "[OPT] $@"
	@ocamlopt -c $<

timed.a: timed.cmxa
timed.cmxa: timed.cmx
	@echo "[OPT] $@"
	@ocamlopt -a -o $@ $^

timed.cmxs: timed.cmx
	@echo "[OPT] $@"
	@ocamlopt -shared -o $@ $^

timed.cmo: timed.ml timed.cmi
	@echo "[BYT] $@"
	@ocamlc -c $<

timed.cma: timed.cmo
	@echo "[BYT] $@"
	@ocamlc -a -o $@ $^

# Tests.

.PHONY: tests
tests: all
	@ocaml -I . timed.cma tests/test.ml
	@ocaml -I . timed.cma tests/example.ml

# Installation.

INSTALLED = timed.cmxa timed.cmxs timed.cma timed.a timed.o timed.cmi \
						timed.cmx META 

.PHONY: install
install: all uninstall
	@ocamlfind install timed $(INSTALLED)

.PHONY: uninstall
uninstall:
	@ocamlfind remove timed

# Cleaning.

clean:
	@rm -f timed.cm[ixoa] timed.cmxa timed.cmxs timed.a timed.o

distclean: clean
	@find . -name "*~" -exec rm {} \;
