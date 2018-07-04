(* Reference representation. *)
type 'a ref =
  { mutable contents : 'a
  ; mutable last_uid : int }

(* NOTE [last_uid] stores the unique identifier of the “node” (see below) that
   contains the last update information for the reference.  It is used to only
   store the first update to a reference in between two “snapshots”. *)

(* Reference creation and access. *)
let ref : 'a -> 'a ref = fun v -> {contents = v; last_uid = 0}
let (!) : 'a ref -> 'a = fun r -> r.contents

module Time =
  struct
    (* Type used to store the previous value of a reference. *)
    type memo = M : {r : 'a ref; mutable v : 'a} -> memo

    (* The main data structure is an oriented graph that is held by one of its
       nodes, and stored on the OCaml heap. This means that parts of the graph
       that are not accessible (in terms of pointers) can be collected, and we
       can consider that they are not part of the graph. Every node contains a
       destination node [d], and list [u] of updates that can be undone. *)
    type node = {mutable d : node; mutable u : memo list}
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

    (* a counter to associate an integer to each node. We do not need to store
        the integer in the node. *)
    let count = Pervasives.ref 0

    (* Creation of a new node for the current time. The current time is characterised
        by a loop that stores the latest update. *)
    let loop ()=
      Pervasives.incr count;
      let rec n = { d = n; u = [] } in n

    (* [reverse n] reverses the edge from [n] to [n.d] and undo all changes
        in [n.u]. [n.u]  is updated to allow "redo" *)
    let reverse : node -> unit = fun s ->
      (* Reverse the pointers. *)
      let d = s.d in
      List.iter (fun (M({r;v} as rc)) -> rc.v <- r.contents; r.contents <- v;) s.u;
      d.d <- s; d.u <- s.u

    (* function returning the current time *)
    let save : unit -> t = fun () ->
      match get_current () with
      | None -> (* We just create a new node *)
         let n = loop () in
         set_current n;
         n
      | Some c ->
         assert (c.d == c);
         if c.u = [] then c else
           (* if some undo are recorded, we need to create a node "after" these undo *)
           let n = loop () in
           c.d <- n;
           set_current n;
           n

    (* [restore t] restores the value of all pointer at time [t]. *)
    let restore : t -> unit = fun t ->
      (* fn builds the path from [t] to the current time and call gn *)
      let rec fn acc t =
        let d = t.d in
        if d == t then (reverse d; gn acc d)
        else fn (t::acc) d
      (* gn really do the undo *)
      and  gn acc t0 =
        (* Undo the references. *)
        match acc with
        | []       ->  assert (t0 == t);
                       (* t becomes the current time *)
                       t0.d <- t0; t0. u <- []; set_current t0;
                       Pervasives.incr count;
        | t::acc -> assert (t.d == t0);
                    (* we reverse the edge from t to t0, which performs the undo *)
                    reverse t; gn acc t
      in fn [] t

    (* Reference update. *)
    let (:=) : 'a ref -> 'a -> unit = fun r v ->
      begin
        (* No need to store the previous value if it has already been updated
           inside the same node. *)
        if r.last_uid <> Pervasives.(!count) then
        match get_current () with
        | None    -> () (* Current time not accessible, no need to save. *)
        | Some(c) ->
            assert (c.d == c); (* Check that the root points to itself. *)
            c.u <- M {r; v = r.contents} :: c.u; (* Save the old value. *)
            r.last_uid <- Pervasives.(!count) (* Last set at current time. *)
      end;
      r.contents <- v (* Actual update. *)
  end

(* Reference update. *)
let (:=) : 'a ref -> 'a -> unit = Time.(:=)

(* Derived functions. *)
let incr : int ref -> unit = fun r -> r := !r + 1
let decr : int ref -> unit = fun r -> r := !r - 1

let pure_apply : ('a -> 'b) -> 'a -> 'b = fun f v ->
  let t = Time.save () in
  let r = f v in Time.restore t; r

let pure_test : ('a -> bool) -> 'a -> bool = fun f v ->
  let t = Time.save () in
  let r = f v in if not r then Time.restore t; r
