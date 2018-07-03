module Time =
  struct
    type 'a tref = { mutable contents : 'a; mutable w : int }
    and memo = M : { r : 'a tref; mutable v : 'a } -> memo
    and edge = {mutable d : node; mutable u : memo list }
    and  node = edge

    let count = ref 0

    let loop ()=
      incr count;
      let rec n = { d = n; u = [] } in n

    let (!!) r = r.contents

    let reverse : node -> unit = fun s ->
      (* Reverse the pointers. *)
      let d = s.d in
      List.iter (fun (M({r;v} as rc)) -> rc.v <- !!r; r.contents <- v;) s.u;
      d.d <- s; d.u <- s.u

    type t = node

    let current : node ref = ref (loop ())

    let save : unit -> t =
      fun () ->
        let c = !current in
        assert (c.d == c);
        if c.u = [] then c else
          let n = loop () in
          c.d <- n;
          current := n;
          n

    let restore : t -> unit = fun t ->
      let rec gn acc t0 =
        (* Undo the references. *)
        match acc with
        | []       ->  t0.d <- t0; t0. u <- []; current := t0; incr count;
        | t::acc -> assert (t.d == t0); reverse t; gn acc t
      in
      let rec fn acc t =
        let d = t.d in
        if d == t then (reverse d; gn acc d)
        else fn (t::acc) d
      in
      fn [] t

    let ref x = {
        contents = x;
        w = 0
      }

    let (:=) : 'a tref -> 'a -> unit = fun r v ->
      let m = M {r; v = !!r} in
      r.contents <- v;
      if r.w <> !count then (
        let c = !current in
        assert (c.d == c);
        c.u <-m :: c.u;
        r.w <- !count)

  end

type 'a ref = 'a Time.tref

let ref = Time.ref

let (!) =  Time.(!!)

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
