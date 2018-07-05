(** Timed references for imperative state. This module provides an alternative
    type for references (or mutable cells) supporting undo/redo operations. In
    particular, an abstract notion of time is used to capture the state of the
    references at any given point, so that it can be restored. Note that usual
    reference operations only have a constant time overhead (compared to those
    of {!module:Pervasives}).

    @author Christophe Raffalli
    @author Rodolphe Lepigre *)

(** Type of references similar to {!type:'a Pervasives.ref}. Note that it uses
    three words of memory, while {!type:'a Pervasives.ref} uses two. Note that
    it is {b unsafe to marshall} elements of this type using functions of  the
    the {!module:Marshal} module or {!val:Pervasives.output_value}. *)
type 'a ref

(** [ref v] creates a new reference holding the value [v]. This operation runs
    in constant time, and has a very small (even negligible) overhead compared
    to {!val:Pervasives.ref}. *)
val ref : 'a -> 'a ref

(** [!r] returns the current value of [r]. This operation is constant time and
    has a negligible overhead compared to {!val:Pervasives.(!)}. *)
val (!) : 'a ref -> 'a

(** [r := v] sets the value of the reference [r] to [v].  This operation has a
    very small overhead compared to {!val:Pervasives.(:=)} if no time has been
    saved with {!val:Time.save}. Nonetheless, it is always constant time. *)
val (:=) : 'a ref -> 'a -> unit

(** [incr r] is equivalent to [r := !r + 1]. *)
val incr : int ref -> unit

(** [decr r] is equivalent to [r := !r - 1]. *)
val decr : int ref -> unit

(** The [Time] module provides an abstract representation of time, used to set
    a point from which updates to references are recorded to allow undoing (of
    redoing) the corresponding changes. *)
module Time :
  sig
    (** Point in the “timeline” of the program's execution. *)
    type t

    (** [save ()] registers the position of the program in its “timeline”. The
        returned value can then be used to “time-travel” toward this point, by
        calling {!val:restore}. The saving operation runs in constant time. *)
    val save : unit -> t

    (** [restore t] has the effect of “traveling in time” towards a previously
        recorded point [t]. After calling this function, the reference updates
        made between [t] and the “time before the call” are undone.  Note that
        this is the only basic operation that is not constant time. Complexity
        is discussed below. *)
    val restore : t -> unit

    (** The complexity of {!val:restore} is O(MT), where
          - M is the maximum number of different references that were updated
            between two consecutive callls to {!val:save}.
          - T is the number of saved time between t and the current time.

        A better expression of its complexity is “Σ Mₖtₖ” for 0 ≤ k < n, where
        tₖ is the k-th saved time between t = t₀ and the current time tₙ,  and
        Mₖ is the number  of different updated references between the times tₖ
        and tₖ₊₁. *)
  end

(** [pure_apply f v] computes the result of [f v],  but reverts the updates to
    references before returning the value. *)
val pure_apply : ('a -> 'b) -> 'a -> 'b

(** [pure_test p v] applies the predicate [p] to [v] (i.e., compute [p v]) and
    returns the result,  reverting the updates made to reference if the result
    is [false]. Updates are preserved if the result is [true]. *)
val pure_test : ('a -> bool) -> 'a -> bool
