all: test test2

test: timed.cmx tests/test.ml
	@echo "[OPT] $@"
	@ocamlopt -o $@ $^
	@./$@

test2: timed.cmx tests/test2.ml
	@echo "[OPT] $@"
	@ocamlopt -o $@ $^
	@./$@

timed.cmi: timed.mli
	@echo "[OPT] $@"
	@ocamlopt -c $<

timed.cmx: timed.ml timed.cmi
	@echo "[OPT] $@"
	@ocamlopt -c $<

clean:
	@rm -f *.cmi *.cmx *.o
	@rm -f tests/*.cmi tests/*.cmx tests/*.o
	@rm -f test test2

distclean: clean
	@rm -f *~ test
