module Time =
  struct
    type 'a tref = { mutable contents : 'a; mutable w : int }
    and memo = M : { r : 'a tref; mutable v : 'a } -> memo
    and edge = {mutable d : node; mutable u : memo list }
    and  node = {mutable e : edge }

    let count = ref 0

    let loop ()=
      incr count;
      let rec n = { e } and e = { d = n; u = [] } in
      n

    let (!!) r = r.contents

    let reverse : node -> unit = fun s ->
      (* Reverse the pointers. *)
      let e = s.e in
      let d = e.d in
      List.iter (fun (M({r;v} as rc)) -> rc.v <- !!r; r.contents <- v;) e.u;
      d.e <- e; e.d <- s

    type t = node

    let current : node ref = ref (loop ())

    let save : unit -> t =
      fun () ->
        let c = !current in
        assert (c.e.d == c);
        if c.e.u = [] then c else
          let n = loop () in
          c.e.d <- n;
          current := n;
          n

    let restore : t -> unit = fun t ->
      let rec gn acc t0 =
        (* Undo the references. *)
        match acc with
        | []       ->  t0.e <- { d = t0; u = [] }; current := t0; incr count;
        | t::acc -> assert (t.e.d == t0); reverse t; gn acc t
      in
      let rec fn acc t =
        let d = t.e.d in
        if d == t then gn acc d
        else fn (t::acc) d
      in
      ignore (save ());
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
        let e = c.e in
        assert (e.d == c);
        e.u <-m :: e.u;
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
