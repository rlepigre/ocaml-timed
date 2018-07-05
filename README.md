Timed references for imperative state
=====================================

This minimal library allows the encapsulation of reference updates
in an abstract notion of state. It can be used to emulate a pure
interface while working with references.


**Authors:** Rodolphe Lepigre & Christophe Raffalli

Installation
------------

The library has no dependency, but it requires `ocamlfind` for
installation. You can use the following commands to compile and
install.
```bash
make
make install
```

The command `make` automatically produces the (`ocamldoc` format)
documentation, which contains the same information as `timed.mli`.
It can be visualized by opening the file `doc/index.html` using a
web browser.

Example
-------

```OCaml
open Timed

let _ =
  let r1 = ref 0  in
  let r2 = ref 42 in

  let t1 = Time.save () in

  r1 := 73;

  let t2 = Time.save () in

  Time.restore t1;
  assert(!r1 = 0 && !r2 = 42)
  
  r1 := 17;

  Time.restore t2;
  assert(!r1 = 73 && !r2 = 42)
```
