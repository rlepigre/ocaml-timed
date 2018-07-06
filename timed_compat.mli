(*****************************************************************************
MIT License

Copyright (c) 2018 Rodolphe Lepigre and Christophe Raffalli

Permission is hereby granted,  free of charge,  to any person obtaining a copy
of this software and associated documentation files (the "Software"),  to deal
in the Software without restriction,  including  without limitation the rights
to use,  copy, modify,  merge, publish,  distribute,  sublicense,  and/or sell
copies of the  Software, and  to  permit  persons  to  whom  the  Software  is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED  "AS IS",  WITHOUT WARRANTY OF ANY KIND,  EXPRESS  OR
IMPLIED,  INCLUDING  BUT NOT  LIMITED TO  THE WARRANTIES  OF  MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT  SHALL  THE
AUTHORS  OR  COPYRIGHT  HOLDERS  BE  LIABLE  FOR  ANY CLAIM,  DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,  ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN  THE
SOFTWARE.
*****************************************************************************)

(** Timed references for {!type:'a Pervasives.ref}.  This module redefines the
    functions used to update references,  and enables the restoration of saved
    reference states.

    @author Christophe Raffalli
    @author Rodolphe Lepigre *)

(** Note that this module allocates one blocks of memory at initialization for
    its internal state. It occupies a total of four words. *)

(** [r := v] sets the value of the reference [r] to [v].  This operation has a
    very small overhead compared to {!val:Pervasives.(:=)} if no time has been
    saved with {!val:Time.save}. Nonetheless, it is always constant time. Note
    that this function does not perform any memory allocation, except when the
    current “time” is accessible (or has not been collected). When that is the
    case, three blocks of memory are allocated, for a total of eight words. *)
val (:=) : 'a ref -> 'a -> unit

(** [incr r] is equivalent to [r := !r + 1]. *)
val incr : int ref -> unit

(** [decr r] is equivalent to [r := !r - 1]. *)
val decr : int ref -> unit

(** The [Time] module provides an abstract representation of time, used to set
    a point from which (monitored) updates to references are recorded to allow
    undoing/redoing the corresponding changes. *)
module Time :
  sig
    (** Point in the “timeline” of the program's execution. *)
    type t

    (** [save ()] registers the position of the program in its “timeline”. The
        returned value can then be used to “time-travel” toward this point, by
        calling {!val:restore}. The saving operation runs in constant time. In
        the process one block of memory of three words is allocated. Note that
        two consecutive calls to [save] (i.e., with no interleaved {!val:(:=)}
        or {!val:restore}) return the same value,  and the second one does not
        allocate any memory. *)
    val save : unit -> t

    (** [restore t] has the effect of “traveling in time” towards a previously
        recorded point [t]. After calling this function, (monitored) reference
        updates made between [t] and the “current time” are undone.  Note that
        the time and memory complexity of this function is proportional to the
        number of (monitored) updates between [t] and the current time. *)
    val restore : t -> unit
  end

(** [pure_apply f v] computes the result of [f v], but reverts the (monitored)
    updates made to references in the process before returning the value. *)
val pure_apply : ('a -> 'b) -> 'a -> 'b

(** [pure_test p v] applies the predicate [p] to [v] (i.e., compute [p v]) and
    returns the result, reverting (monitored) updates made to reference if the
    result is [false]. Updates are preserved if the result is [true]. *)
val pure_test : ('a -> bool) -> 'a -> bool
