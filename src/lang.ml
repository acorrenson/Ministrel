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
  | Suspend of string * prog
  (* Traps *)
  | Trap of string * prog
  (* Throw "exception" *)
  | Exit of string * int


type process =
  { name    : string
  ; inputs  : string list
  ; outputs : string list
  ; program : prog
  }

let _count = ref 0

let gen s =
  incr _count;
  Printf.sprintf "%s_%d" s !_count

let halt =
  Loop Pause

let await s =
  let ok = gen "_await_done" in
  Seq (Pause,
    Trap (
      ok,
      Loop (
        Seq (
          Ite (s, Exit (ok, 2), Nothing),
          Pause
        )
      )
    )
  )

let await_imm_not s =
  let ok = gen "_await_imm_done" in
  Trap (
    ok,
    Loop (
      Seq (
        Ite (s, Nothing, Exit (ok, 2)),
        Pause
      )
    )
  )

let suspend_imm s p =
  Seq (await_imm_not s, Suspend (s, p))

let abort s p =
  let ok = gen "_abort_done" in
  Trap (ok,
    Par (
      Seq (Suspend (s, p), Exit (ok, 2)),
      Seq (await s, Exit (ok, 2))
    )
  )


let abort_imm s p =
  Ite (s, Nothing, abort s p)

let await_imm s =
  abort_imm s halt

let trap_handle t p q =
  let ok = "_trap_done" in
  Trap (ok, Seq (Trap (t, Seq (p, Exit (ok, 2))), q))

let pp_prog fmt p =
  let id lvl = String.make lvl ' ' in
  let rec pp_prog_aux lvl fmt = function
    | Pause ->
      Format.fprintf fmt "%spause" (id lvl)
    | Nothing ->
      Format.fprintf fmt "%snothing" (id lvl)
    | Par (x, y) ->
      Format.fprintf fmt "%s{\n%a\n%s} || {\n%a\n%s}"
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
    | Suspend (s, p) ->
      Format.fprintf fmt "%ssuspend\n%a\n%swhen %s"
      (id lvl)
      (pp_prog_aux (lvl + 2)) p
      (id lvl)
      s
    | Trap (s, p) ->
      Format.fprintf fmt "%strap %s\n%a\n%send"
      (id lvl)
      s
      (pp_prog_aux (lvl + 2)) p
      (id lvl)
    | Exit (s, k) ->
      Format.fprintf fmt "%sexit %s[%d]" (id lvl) s k
    in
    pp_prog_aux 0 fmt p