(** Timed references for {!type:'a Pervasives.ref}.  This module redefines the
    functions used to update references,  and enables the restoration of saved
    reference states.

    @author Christophe Raffalli
    @author Rodolphe Lepigre *)

(** Note that this module allocates two blocks of memory at initialization for
    its internal state. They occupy a total of four words. *)

(** [r := v] has the same effect as [Pervasives.(r := v)],  but the value that
    was stored in [r] before the update is recorded so that it may be restored
    by a subsequent call to {!val:Time.restore}. This is done in constant time
    and three blocks of memory are allocated (for a total of eight words). *)
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
        returned value can then be used to “time-travel” toward this point. No
        allocation is performed, and this operation is constant time. *)
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
