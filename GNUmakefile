all: test

test: timed.cmx test.ml
	ocamlopt -o $@ $^

timed.cmi: timed.mli
	ocamlopt -c $<

timed.cmx: timed.ml timed.cmi
	ocamlopt -c $<

clean:
	rm -f *.cmi *.cmx *.o

distclean: clean
	rm -f *~ test
