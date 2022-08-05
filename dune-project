(lang dune 2.7)
(name "timed")
(authors
 "Christophe Raffalli <christophe@raffalli.eu"
 "Rodolphe Lepigre <lepigre@mpi-sws.org>")
(maintainers
 "Christophe Raffalli <christophe@raffalli.eu"
 "Rodolphe Lepigre <lepigre@mpi-sws.org>")
(source (github rlepigre/ocaml-timed))
(license "MIT")

(generate_opam_files true)

(package
 (name timed)
 (synopsis "Timed references for imperative state")
 (description
  "Timed references for imperative state. This module provides an alternative
   type for references (or mutable cells) supporting undo/redo operations. In
   particular, an abstract notion of time is used to capture the state of the
   references at any given point, so that it can be restored. Note that usual
   reference operations only have a constant time / memory overhead (compared
   to those of the standard library).

   Moreover, we provide an alternative implementation based on the references
   of the standard library (Pervasives module). However, it is less efficient
   than the first one.")
 (depends
  (ocaml (>= 4.08.0))
  (odoc :with-doc)
  (dune :build)))
