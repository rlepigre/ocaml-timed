module Time =
  struct
    (* a type similar to ervasives.ref. The field 'w' stores that time (an
        int identifyinh the time returned by save) of the last update. The
        idea is to store only the value before the first update between two
        consecutive time *)
    type 'a tref = { mutable contents : 'a; mutable w : int }

    (* memo is a GADT to store the previous value of a reference *)
    type memo = M : { r : 'a tref; mutable v : 'a } -> memo

    (* This is then main structure of or librarie, it is an oriented graph,
        whose nodes represent the time returned by save. Each node point to
        a destination node [d], with u storing all updates that should be undone when
       when goig to the time [d] *)
    type node = {mutable d : node; mutable u : memo list }
    type t = node

    (* a counter to associate an integer to each node. We do not need to store
        the integer in the node. *)
    let count = ref 0

    (* Creation of a new node for the current time. The current time is characterised
        by a loop that stores the latest update. *)
    let loop ()=
      incr count;
      let rec n = { d = n; u = [] } in n

    (* the current time is a weak point, because if no saved time are
       accessible, we do not need to keep a node, as this would keep useless
       pointers *)
    let current : node Weak.t = Weak.create 1

    let get_cur () = Weak.get current 0
    let set_cur x = Weak.set current 0 x

    (* [reverse n] reverses the edge from [n] to [n.d] and undo all changes
        in [n.u]. [n.u]  is updated to allow "redo" *)
    let reverse : node -> unit = fun s ->
      (* Reverse the pointers. *)
      let d = s.d in
      List.iter (fun (M({r;v} as rc)) -> rc.v <- r.contents; r.contents <- v;) s.u;
      d.d <- s; d.u <- s.u

    (* function returning the current time *)
    let save : unit -> t =
      fun () ->
      match get_cur () with
      | None -> (* We just create a new node *)
         let n = loop () in
         set_cur (Some n);
         n
      | Some c ->
         assert (c.d == c);
         if c.u = [] then c else
           (* if some undo are recorded, we need to create a node "after" these undo *)
           let n = loop () in
           c.d <- n;
           set_cur (Some n);
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
                       t0.d <- t0; t0. u <- []; set_cur (Some t0); incr count;
        | t::acc -> assert (t.d == t0);
                    (* we reverse the edge from t to t0, which performs the undo *)
                    reverse t; gn acc t
      in fn [] t

    (* referece creation *)
    let ref x = {
        contents = x;
        w = 0
      }

    (* update *)
    let (:=) : 'a tref -> 'a -> unit = fun r v ->
      begin
        (* no need to store the old value if
            - the current time is not accessible (no saved time are accessible)
            - or [r] was already updated and its initial value is already stored *)
        match get_cur (), r.w <> !count with
        | (Some c, true) ->
           assert (c.d == c);
           (* we store the old value *)
           let m = M {r; v = r.contents} in
           c.u <-m :: c.u;
           (* we store the information that r was updated at the current time *)
           r.w <- !count
        | _ -> ()
      end;
      (* and we do the update! *)
      r.contents <- v;
  end

type 'a ref = 'a Time.tref

let ref = Time.ref

let (!) r =  Time.(r.contents)

let (:=) = Time.(:=)

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
