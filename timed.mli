(** Timed references for imperative state. This module redefines the functions
    used to update references (i.e., values of type ['a ref]), and enables the
    restoration of a saved state. *)

(** The [Time] module provides an abstract representation of time, used to set
    a point from which (monitored) updates to references are recorded to allow
    undoing/redoing the corresponding changes. *)
module Time :
  sig
    (** Point in the “timeline” of the program's execution. *)
    type t

    (** [save ()] registers the position of the program in its “timeline”. The
        returned value can then be used to “time-travel” toward this point.
        in O(1) *)
    val save : unit -> t

    (** [restore t] has the effect of “traveling in time” towards a previously
        recorded point [t]. After calling this function, (monitored) reference
        updates made between [t] and the “time before the call” are undone.

     Complexity: O(MT) when
     - M: maximum number of references updated between two consecutive
       save (the number of references, not the number of updates, hence,
       is one update the same reference several time, it does not count)
     - T: number of saved time between t and the current time.

      A better complexity is the sum of all M_i for i in 0 to n-1 where t_i are the
      time between t = t_0 and the current time t_n and M_i are the number of
      updated references between t_i and t_(i+1).
     *)
    val restore : t -> unit
  end

type 'a ref

(** reference access in O(1) *)
val (!) : 'a ref -> 'a

(** reference construction in O(1) *)
val ref : 'a -> 'a ref

(** [r := v] has the same effect as [Pervasives.(r := v)],  but the value that
    was stored in [r] before the update is recorded so that it may be restored
    by a subsequent call to [Time.restore]. in O(1) *)
val (:=) : 'a ref -> 'a -> unit

(** [incr r] increments the integer stored in [r],  recording the old value so
    that it can be resotred by a subsequent call to [Time.restore]. *)
val incr : int ref -> unit

(** [decr r] is similar to [incr r], but it decrements the integer. *)
val decr : int ref -> unit

(** [pure_apply f v] computes the result of [f v], but reverts the (monitored)
    updates made to references in the process before returning the value. *)
val pure_apply : ('a -> 'b) -> 'a -> 'b

(** [pure_test p v] applies the predicate [p] to [v] (i.e., compute [p v]) and
    returns the result, reverting (monitored) updates made to reference if the
    result is [false]. Updates are preserved if the result is [true]. *)
val pure_test : ('a -> bool) -> 'a -> bool
