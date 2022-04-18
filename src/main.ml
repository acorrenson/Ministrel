open Lang
open Simulator

let make_inputs =
  List.map E.of_list

let () =
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
  simulate inputs prog