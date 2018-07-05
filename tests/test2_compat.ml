let steps = ref 10_000
let nb_refs = ref 5
let maxi = ref 5
let proba_save = ref 0.2
let proba_restore = ref 0.2
let verbose = ref false
let spec =
  let open Arg in
  [ ("--steps", Set_int steps, "number of steps in test")
  ; ("--nb-refs", Set_int nb_refs, "number of references in the state")
  ; ("--maxi", Set_int maxi, "maximum value of a referecence")
  ; ("--proba-save", Set_float proba_save, "probability of a save at each step")
  ; ("--proba-restore", Set_float proba_restore, "probability of a restore at each step")
  ; ("--vebose", Set verbose, "verbose tests")
  ]

let _ = Arg.(parse spec (fun _ -> raise (Bad "useless arguments"))
                   (Printf.sprintf "usage: %s [options]" Sys.argv.(0)))

let steps = !steps
let nb_refs = !nb_refs
let maxi = !maxi
let proba_save = !proba_save
let proba_restore = !proba_restore
let verbose = !verbose

open Timed_compat

type fstate = int array
type istate = int ref array
type state = fstate * istate

let init_state =
  let f = Array.init nb_refs (fun _ -> Random.int maxi) in
  let i = Array.map ref f in
  (f, i)

let print_state (f, i) =
  if verbose then
    begin
      Array.iteri (fun j x ->
          Printf.printf "%i: (%i, %i) ; " j x !(i.(j))) f;
      print_newline ()
    end

let compare_state (f,i) =
  Array.iteri (fun j x -> if !(i.(j)) <> x then assert false) f

let update (f,i) =
  let n = Random.int nb_refs in
  let x = Random.int maxi in
  let f = Array.copy f in
  if verbose then Printf.printf "update %i\n%!" n;
  f.(n) <- x;
  i.(n) := x;
  (f,i)

let step saved (f,i as state) =
  let x = Random.float 1.0 in
  if x < 0.2 then
    let saved = saved @ [(f, Time.save ())] in
    (if verbose then Printf.printf "save %i\n%!" (List.length saved - 1));
    (saved, state)
  else if x < 0.4 then
    let n = Random.int (List.length saved) in
    let (f, t) = List.nth saved n in
    Time.restore t;
    (if verbose then Printf.printf "restore %i\n%!" n);
    (saved, (f, i))
  else
    let state = update state in
    (saved, state)

let run () =
  let (f,_) as state = init_state in
  print_state state;
  if verbose then Printf.printf "save %i\n%!" 0;
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
  fn steps saved state

let _ = run ()
