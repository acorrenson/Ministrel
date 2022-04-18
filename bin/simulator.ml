open Ministrel

let usage_msg = Sys.argv.(0) ^ " [-verbose] <model> [-sim <inputs>] [-pp]"
let verbose = ref false
let model = ref ""
let inputs = ref ""
let pp = ref false

let anon_fun filename =
    model := filename

let speclist =
  [("-verbose", Arg.Set verbose, "Output debug information");
  ("-sim", Arg.Set_string inputs, "Run a simulation with given inputs");
  ("-pp", Arg.Set pp, "Print the program")]

let pretty_print () =
  if !model = "" then (Arg.usage speclist usage_msg; exit 1);
  let p = Parser.parse_file !model in
  Printf.printf "%s\n" (Format.asprintf "%a" Lang.pp_prog p)

let simulate () =
  if !inputs <> "" then begin
    if !model = "" then (Arg.usage speclist usage_msg; exit 1);
    let inputs = Parser.parse_inputs !inputs in
    let prog = Parser.parse_file !model in
    Simulator.simulate inputs prog
  end

let () =
  Arg.parse speclist anon_fun usage_msg;
  if !pp then pretty_print ();
  simulate ()
    