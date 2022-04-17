type prog =
  (* Pause for 1 unit of time *)
  | Pause
  (* Do nothing in no time *)
  | Nothing
  (* Parallel composition *)
  | Par of prog * prog
  (* Sequential composition *)
  | Seq of prog * prog
  (* Conditions *)
  | Ite of string * prog * prog
  (* Looping *)
  | Loop of prog
  (* Emitting signals *)
  | Emit of string
  (* Preemption *)
  | Abort of string * prog
  (* Traps *)
  | Trap of string * prog
  (* Throw "exception" *)
  | Exit of string


type process =
  { name    : string
  ; inputs  : string list
  ; outputs : string list
  ; program : prog
  }

let halt =
  Loop Pause

let abort_imm s p =
  Ite (s, Nothing, Abort(s, p))

let await s =
  Abort (s, halt)

let await_imm s =
  abort_imm s halt

let trap_handle t p q =
  let ok = "_trap_done" in
  Trap (ok, Seq (Trap (t, Seq (p, Exit ok)), q))

let pp_prog fmt p =
  let id lvl = String.make lvl ' ' in
  let rec pp_prog_aux lvl fmt = function
    | Pause ->
      Format.fprintf fmt "%spause" (id lvl)
    | Nothing ->
      Format.fprintf fmt "%snothing" (id lvl)
    | Par (x, y) ->
      Format.fprintf fmt "%s{%a%s\n} || {\n%a%s\n}"
      (id lvl)
      (pp_prog_aux (lvl + 2)) x
      (id lvl)
      (pp_prog_aux (lvl + 2)) y
      (id lvl)
    | Seq (x, y) ->
      Format.fprintf fmt "%a;\n%a"
      (pp_prog_aux lvl) x
      (pp_prog_aux lvl) y
    | Ite (s, x, y) ->
      Format.fprintf fmt "%sif %s then\n%a\n%selse\n%a\n%send"
      (id lvl)
      s
      (pp_prog_aux (lvl + 2)) x
      (id lvl)
      (pp_prog_aux (lvl + 2)) y
      (id lvl)
    | Loop p ->
      Format.fprintf fmt "%sloop\n%a\n%send"
      (id lvl)
      (pp_prog_aux (lvl + 2)) p
      (id lvl)
    | Emit s ->
      Format.fprintf fmt "%semit %s" (id lvl) s
    | Abort (s, p) ->
      Format.fprintf fmt "%sabort\n%a\n%swhen %s"
      (id lvl)
      (pp_prog_aux (lvl + 2)) p
      (id lvl)
      s
    | Trap (s, p) ->
      Format.fprintf fmt "%strap %s\n%a\n%s"
      (id lvl)
      s
      (pp_prog_aux (lvl + 2)) p
      (id lvl)
    | Exit s ->
      Format.fprintf fmt "%sexit %s" (id lvl) s
    in
    pp_prog_aux 0 fmt p