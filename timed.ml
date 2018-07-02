module Time =
  struct
    type t = T : {mutable p : t; r : 'a ref; mutable v : 'a} -> t

    let current : t ref =
      ref (let rec p = T {p; r = ref 0; v = 0} in p)

    let save : unit -> t =
      fun () -> !current

    let restore : t -> unit =
      let rec gn acc (T r as t0) =
        let v = r.v in
        r.v <- !(r.r); r.r := v;
        match acc with
        | []     -> r.p <- t0; current := t0
        | t::acc -> r.p <- t; gn acc t
      in
      let rec fn acc ((T {p}) as time) =
        if time != p then fn (time::acc) p else gn acc time
      in
      fn []
  end

let (:=) : 'a ref -> 'a -> unit = fun r v ->
  let open Time in
  let rec node = T {p = node; r; v = !r} in
  let T curr = !current in
  curr.p <- node; current := node; r := v

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
