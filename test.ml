open Timed

let main () =
  let r1 = ref 0  in
  let r2 = ref 42 in
  let r3 = ref 73 in

  let print_state s =
    Printf.printf "%s: (%2i, %2i, %2i)\n%!" s !r1 !r2 !r3 
  in

  let check_eq (a,b,c) =
    assert (!r1 = a); assert (!r2 = b); assert (!r3 = c)
  in

  let t0 = Time.save () in
  print_state "At t0               ";

  Printf.printf "r1 := 12\n%!";
  r1 := 12;

  print_state "At t1               ";
  let t1 = Time.save () in

  Printf.printf "r2 := 43\n%!";
  r2 := 43;

  print_state "Before restore to t0";
  Time.restore t0;
  print_state "After  restore to t0";
  check_eq (0, 42, 73);

  Printf.printf "r3 := 0\n%!";
  r3 := 0;

  print_state "At t2               ";
  let t2 = Time.save () in

  Printf.printf "r1 := 42\n%!";
  r1 := 42;

  print_state "Before restore to t1";
  Time.restore t1;
  print_state "After  restore to t1";
  check_eq (12, 42, 73);

  Printf.printf "r1 := 38\n%!";
  r1 := 38;

  print_state "Before restore to t2";
  Time.restore t2;
  print_state "After  restore to t2";
  check_eq (0, 42, 0)

let _ =
  Printf.printf "== Tests =========================\n%!";
  main ();
  Printf.printf "==================================\n%!"
