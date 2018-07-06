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

    (* NOTE [current] is either empty,  or it contains a [node] that points to
       itself (i.e., a loop), that stores the latest updates. *)

    (* Counter used to associate a unique identifier to each node. *)
    let count = Pervasives.ref 0

    (* NOTE We do not need to store the unique identifier in the node. *)

    (* [reverse s] reverses the edge going from [s] to [s.d], applies the undo
       operations represented by [s.u], and updates [s.u] to enable redo. *)
    let reverse : node -> unit = fun s ->
      let d = s.d in (* Destination node. *)
      let undo (M({r;v} as rc)) = rc.v <- r.contents; r.contents <- v in
      List.iter undo s.u; d.d <- s; d.u <- s.u

    (* Returns the current “time” (which is a [node]), in which the subsequent
       reference updates will be stored until a call to [restore],  or another
       call to [save]. This new node becomes the root. *)
    let save : unit -> t = fun () ->
      match get_current () with
      | None                  ->
          (* Empty graph, just create a root node (points to itself). *)
          let rec n = {d = n; u = []} in
          Pervasives.incr count;
          set_current n; n
      | Some(c) when c.u = [] ->
          (* No updates since previous save, we can use the same node. *)
          assert (c.d == c); c
      | Some(c)               ->
          (* Updates were saved in previous node, create a new root. *)
          assert (c.d == c);
          let rec n = {d = n; u = []} in
          Pervasives.incr count;
          c.d <- n; set_current n; n

    (* [restore t] restores the value of all pointer at time [t]. *)
    let restore : t -> unit = fun t ->
      (* Undoes the references along the given path. *)
      let rec gn path t0 =
        match path with
        | []      ->
            (* [t0] becomes the current time. *)
            assert (t0 == t);
            t0.d <- t0; t0.u <- []; set_current t0;
            Pervasives.incr count
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

let unsafe_reset : 'a ref -> unit = fun r -> r.last_uid <- 0
