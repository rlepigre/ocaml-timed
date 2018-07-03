open Timed

let nb_steps = 10_000
let nb_ref = 5
let maxi = 5
let proba_save = 0.2
let proba_restore = 0.2

type fstate = int array
type istate = int ref array
type state = fstate * istate

let init_state =
  let f = Array.init nb_ref (fun _ -> Random.int maxi) in
  let i = Array.map ref f in
  (f, i)

let print_state (f, i) =
  Array.iteri (fun j x ->
      Printf.printf "%i: (%i, %i) ; " j x !(i.(j))) f;
  print_newline ()

let compare_state (f,i) =
  Array.iteri (fun j x -> if !(i.(j)) <> x then assert false) f

let update (f,i) =
  let n = Random.int nb_ref in
  let x = Random.int maxi in
  let f = Array.copy f in
    Printf.printf "update %i\n%!" n;
  f.(n) <- x;
  i.(n) := x;
  (f,i)

let step saved (f,i as state) =
  let x = Random.float 1.0 in
  if x < 0.2 then
    let saved = saved @ [(f, Time.save ())] in
    Printf.printf "save %i\n%!" (List.length saved - 1);
    (saved, state)
  else if x < 0.4 then
    let n = Random.int (List.length saved) in
    let (f, t) = List.nth saved n in
    Time.restore t;
    Printf.printf "restore %i\n%!" n;
    (saved, (f, i))
  else
    let state = update state in
    (saved, state)

let run () =
  let (f,_) as state = init_state in
  print_state state;
  Printf.printf "save %i\n%!" 0;
  let saved = [(f, Time.save ())] in
  let rec fn count saved state =
    if count > 0 then
      let (saved, state) = step saved state in
      print_state state;
      compare_state state;
      fn (count -1) saved state
    else
      ()
  in
  fn nb_steps saved state

let _ = run ()
