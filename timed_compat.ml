module Time =
  struct
    (* Type used to store the previous value of a reference. *)
    type memo = M : {r : 'a ref; mutable v : 'a} -> memo

    let dummy_memo : memo = M {r = ref 0; v = 0}

    (* The main data structure is an oriented graph that is held by one of its
       nodes, and stored on the OCaml heap. This means that parts of the graph
       that are not accessible (in terms of pointers) can be collected, and we
       can consider that they are not part of the graph. Every node contains a
       destination node [d], and a previous value [f] for reference [r]. *)
    type node = {mutable d : node; mutable u : memo}
    type t = node

    (* NOTE We require the in-memory graph to be either empty, or to be a tree
       oriented toward its root. Intuitively, the root (if any) will represent
       the [current] time, and any other [node] in the tree represents a point
       to which we can travel (following pointer backwards, from a given point
       to the root of the tree). *)

    (* Root of the in-memory tree, or current “time”. *)
    let current : node Weak.t = Weak.create 1

    (* NOTE The [current] “time” is implemented as a weak pointer so that  the
       root of the tree can be collected (and the graph made empty) if none of
       the other nodes are accessible (the “time” has not been saved). This is
       useful to save memory in the cases where the state is never saved. *)

    (* Get and set operation for the [current] root node. *)
    let get_current : unit -> node option = fun _ -> Weak.get current 0
    let set_current : node -> unit = fun n -> Weak.set current 0 (Some(n))

    (* NOTE At a low level, restoring a previously saved “time” really amounts
       to setting the corresponding node to be the root of the tree (reversing
       the pointers, and undoing the updates in the process). *)

    (* NOTE [current] is either empty,  or it contains a [node] that points to
       itself (i.e., a loop), that stores the latest updates. *)

    (* [reverse s] reverses the edge going from [s] to [s.d], applies the undo
       operations represented by [s.u], and updates [s.u] to enable redo. *)
    let reverse : node -> unit = fun s ->
      let d = s.d in (* Destination node. *)
      let undo (M({r;v} as rc)) = rc.v <- !r; r := v in
      undo s.u; d.d <- s; d.u <- s.u

    (* Returns the current “time” (which is a [node]), in which the subsequent
       reference updates will be stored until a call to [restore],  or another
       call to [save]. This new node becomes the root. *)
    let save : unit -> t = fun () ->
      match get_current () with
      | None                           ->
          (* Empty graph, just create a root node (points to itself). *)
          let rec n = {d = n; u = dummy_memo} in
          set_current n; n
      | Some(c) when c.u == dummy_memo ->
          (* No updates since previous save, we can use the same node. *)
          assert (c.d == c); c
      | Some(c)                        ->
          (* Updates were saved in previous node, create a new root. *)
          assert (c.d == c);
          let rec n = {d = n; u = dummy_memo} in
          c.d <- n; set_current n; n

    (* [restore t] restores the value of all pointer at time [t]. *)
    let restore : t -> unit = fun t ->
      (* Undoes the references along the given path. *)
      let rec gn path t0 =
        match path with
        | []      ->
            (* [t0] becomes the current time. *)
            assert (t0 == t);
            t0.d <- t0; t0.u <- dummy_memo; set_current t0
        | t::path ->
            (* We reverse the edge from [t] to [t0] (preforms the undo). *)
            assert (t.d == t0);
            reverse t; gn path t
      in
      (* Builds the path from [t] to the current time, and calls [gn]. *)
      let rec fn path t =
        let d = t.d in
        if d == t then (reverse d; gn path d) else fn (t::path) d
      in fn [] t

    (* Reference update. Information for rollback is stored in the root [node]
       (if any), which corresponds to the last saved “time”. *)
    let (:=) : 'a ref -> 'a -> unit = fun r v ->
      begin
        match get_current () with
        | None    -> () (* Current time not accessible, no need to save. *)
        | Some(c) ->
            assert (c.d == c); (* Check that the root points to itself. *)
            if c.u == dummy_memo then c.u <- M {r; v = !r} else
            let rec n = {d = n; u = M {r; v = !r}} in
            c.d <- n; set_current n
      end;
      r := v (* Actual update. *)
  end

(* Reference update. *)
let (:=) : 'a ref -> 'a -> unit = Time.(:=)

(* Derived functions. *)
let incr : int ref -> unit = fun r -> r := !r + 1
let decr : int ref -> unit = fun r -> r := !r - 1

let pure_apply : ('a -> 'b) -> 'a -> 'b = fun f v ->
  let t = Time.save () in
  let r = f v in
  Time.restore t; r

let pure_test : ('a -> bool) -> 'a -> bool = fun f v ->
  let t = Time.save () in
  let r = f v in
  if not r then Time.restore t; r
