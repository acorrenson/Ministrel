open Lang

let _ =
  Format.printf "%a\n" pp_prog (abort_imm "A" (Emit "HELLO"))