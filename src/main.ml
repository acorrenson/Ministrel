open Lang
open Simulator

let make_inputs =
  List.map E.of_list

let () =
  let p = Parser.parse_file "await.ministrel" in
  print_endline (Format.asprintf "%a\n" pp_prog p);
  (* (* let prog = Seq (Par (
    Seq (await "A", Emit "OK_A"), Seq (await "B", Emit "OK_B")
  ), Emit "C") in
  let inputs = make_inputs [
    ["A"];
    ["B"];
    [];
    [];
    ["A"];
    ["A"];
  ] in
  simulate inputs prog *)
  let inputs = make_inputs [
    ["A"; "R"];
    ["B"; "R"];
    ["A"; "B"; "R"];
    ["A"];
    ["B"];
    ["R"];
  ] in
  let prog =
    Loop (
      abort "R" (
        Seq (
          Par (await "A", await "B"),
          Seq (Emit "O", halt)
        )
      )
    )
  in
  simulate inputs prog *)