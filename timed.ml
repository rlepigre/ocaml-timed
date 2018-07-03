module Time =
  struct
    type 'a tref = { mutable contents : 'a; w : edge Weak.t }
    and memo = M : { r : 'a tref; mutable v : 'a } -> memo
    and edge = {mutable d : node option; mutable u : memo list }
    and  node = {mutable e : edge }

    let (!!) r = r.contents

    let reverse : node -> unit = fun s ->
      match s.e.d with
      | None -> assert false
      | Some  d ->
          (* Reverse the pointers. *)
          d.e <- s.e; s.e.d <- Some s

    type t = node

    let current : edge ref = ref {d = None; u = []}

    let save : unit -> t =
      fun () ->
        let e = { d = None; u = [] } in
        let n = { e } in
        !current.d <- Some n;
        current := e;
        n

    let restore : t -> unit =
      let rec gn acc e =
        (* Undo the references. *)
        List.iter (fun (M({r;v} as rc)) -> rc.v <- !!r; r.contents <- v;) e.u;
        match acc with
        | []     -> current := e; e.d <- None
        | t::acc -> reverse t; gn acc t.e
      in
      let rec fn acc ({e} as time) =
        match e.d with
        | None        -> gn acc e
        | Some d -> fn (time::acc) d
      in
      fn []

    let ref x = {
        contents = x;
        w = Weak.create 1
      }

    let (:=) : 'a tref -> 'a -> unit = fun r v ->
      let m = M {r; v = !!r} in
      r.contents <- v;
      match Weak.get r.w 0 with
      | Some e when e == !current -> ()
      | _ ->
         let e = !current in
         e.u <-m :: e.u;
         Weak.set r.w 0 (Some e)

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
