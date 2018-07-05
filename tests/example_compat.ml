open Timed_compat

let _ =
  let r1 = ref 0  in
  let r2 = ref 42 in

  let t1 = Time.save () in

  r1 := 73;

  let t2 = Time.save () in

  Time.restore t1;
  assert(!r1 = 0 && !r2 = 42);
  
  r1 := 17;

  Time.restore t2;
  assert(!r1 = 73 && !r2 = 42)
