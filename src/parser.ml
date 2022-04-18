open Genlex
open Lang
open Simulator

let lexer =
  make_lexer [
    "await";
    "in";
    "abort";
    "when";
    "exit";
    "if";
    "then";
    "else";
    "loop";
    "emit";
    "trap";
    "pause";
    "halt";
    "nothing";
    "suspend";
    "immediate";
    "end";
    ";";
    "||";
    "{";
    "}";
  ]

let (let*) = Option.bind

let rec parse_par (s : token Stream.t) acc =
  match acc with
  | None ->
    let* lhs = parse_atom s in
    parse_par s (Some lhs)
  | Some lhs ->
    match Stream.peek s with
    | Some (Kwd "||") ->
      Stream.junk s;
      let* rhs = parse_atom s in
      parse_par s (Some (Par (lhs, rhs)))
    | _ -> acc

and parse_seq s acc =
  match acc with
  | None ->
    let* lhs = parse_par s None in
    parse_seq s (Some lhs)
  | Some lhs ->
    match Stream.peek s with
    | Some (Kwd ";") ->
      Stream.junk s;
      let* rhs = parse_par s None in
      parse_seq s (Some (Seq (lhs, rhs)))
    | _ -> acc

and parse_atom s =
  let* head = Stream.peek s in
  Stream.junk s;
  match head with
  | Kwd "emit" ->
    let* signal = parse_ident s in
    Some (Emit signal)
  | Kwd "await" ->
    let* signal = parse_ident s in
    Some (await signal)
  | Kwd "loop" ->
    let* body = parse_seq s None in
    let* _ = parse_end s in
    Some (Loop body)
  | Kwd "exit" ->
    let* trap = parse_ident s in
    let* index = parse_num s in
    Some (Exit (trap, index))
  | Kwd "trap" ->
    let* trap = parse_ident s in
    let* body = parse_seq s None in
    let* _ = parse_end s in
    Some (Trap (trap, body))
  | Kwd "suspend" ->
    let* body = parse_seq s None in
    let* _ = parse_when s in
    let* signal = parse_ident s in
    Some (Suspend (signal, body))
  | Kwd "abort" ->
      let* body = parse_seq s None in
      let* _ = parse_when s in
      let* signal = parse_ident s in
      Some (abort signal body)
  | Kwd "pause" -> Some Pause
  | Kwd "nothing" -> Some Nothing
  | Kwd "halt" -> Some halt
  | Kwd "{" ->
    let* body = parse_seq s None in
    let* _ = parse_close s in
    Some body
  | _ -> None
and parse_ident s =
  match Stream.peek s with
  | Some (Ident i) ->
    Stream.junk s;
    Some i
  | _ -> None
and parse_num s =
  match Stream.peek s with
  | Some (Int n) -> 
    Stream.junk s;
    Some n
  | _ -> None
and parse_end s =
  match Stream.peek s with
  | Some (Kwd "end") ->
    Stream.junk s;
    Some ()
  | _ -> None
and parse_when s =
  match Stream.peek s with
  | Some (Kwd "when") ->
    Stream.junk s;
    Some ()
  | _ -> None
and parse_in s =
  match Stream.peek s with
  | Some (Kwd "in") ->
    Stream.junk s;
    Some ()
  | _ -> None
and parse_close s =
  match Stream.peek s with
  | Some (Kwd "}") ->
    Stream.junk s;
    Some ()
  | _ -> None

let parser s = parse_seq s None

let parse_file file =
  open_in file
  |> Stream.of_channel
  |> lexer
  |> parser
  |> Option.get

let parse_inputs file =
  let chan = open_in file in
  let inputs = ref [] in
  try while true do
    let line = input_line chan in
    let symbols = Str.split (Str.regexp " +") line in
    inputs := (E.of_list symbols)::!inputs
  done; assert false
  with _ -> List.rev !inputs
