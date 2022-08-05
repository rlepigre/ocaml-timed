VERSION := 1.1

all:
	@dune build
.PHONY: all

doc:
	@dune build @doc
.PHONY: doc

clean:
	@dune clean
.PHONY: clean

distclean: clean
	@find . -name "*~" -type f -exec rm {} \;
.PHONY: distclean

tests:
	@dune runtest
.PHONY: tests

promote:
	@dune promote
.PHONY: promote

install:
	@dune install
.PHONY: install

uninstall:
	@dune uninstall
.PHONY: uninstall

## Documentation webpage

updatedoc: doc
	@mkdir -p docs
	@rm -rf docs/$(VERSION)
	@cp -r _build/default/_doc/_html docs/$(VERSION)
.PHONY: updatedoc

## Release

release: distclean
	git push origin
	git tag -a $(VERSION)
	git push origin $(VERSION)
	opam publish
.PHONY: release
