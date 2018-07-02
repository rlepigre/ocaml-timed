all: test

test: timed.cmx test.ml
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

distclean: clean
	@rm -f *~ test
