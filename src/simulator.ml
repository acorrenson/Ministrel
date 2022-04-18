open Lang

module E = Set.Make(String)

let delta k p =
  if k = 1 then p else Nothing

let down = function
  | 0 -> 0
  | 1 -> 1
  | 2 -> 0
  | k when k >= 3 -> k - 1
  | _ -> assert false

let rec simulate_one (env : E.t) (p : prog) =
  match p with
  | Pause ->
    (Nothing, E.empty, 1)
  | Nothing ->
    (Nothing, E.empty, 0)
  | Par (p, q) ->
    let (p', p_out, p_k) = simulate_one env p in
    let (q', q_out, q_k) = simulate_one env q in
    let m = max p_k q_k in
    (delta m (Par (p', q')), E.union p_out q_out, m)
  | Seq (p, q) ->
    let (p', p_out, p_k) = simulate_one env p in
    if p_k = 0 then
      let (q', q_out, q_k) = simulate_one env q in
      (q', E.union p_out q_out, q_k)
    else
      (delta p_k (Seq (p', q)), p_out, p_k)
  | Ite (s, p, q) ->
    if E.mem s env then
      simulate_one env p
    else
      simulate_one env q
  | Loop p ->
    let (p', out, k) = simulate_one env p in
    if k = 0 then failwith "No-time loop!";
    (delta k (Seq (p', Loop p)), out, k)
  | Emit s ->
    (Nothing, E.singleton s, 0)
  | Suspend (s, p) ->
    let (p', out, k) = simulate_one env p in
    (delta k (suspend_imm s p'), out, k)
  | Trap (t, p) ->
    let (p', out, k) = simulate_one env p in
    let k = down k in
    (delta k (Trap (t, p')), out, k)
  | Exit (_, k) ->
    (Nothing, E.empty, k)

let string_of_env env =
  env
  |> E.to_seq
  |> List.of_seq
  |> String.concat " "

let rec simulate envs p =
  match envs with
  | [] -> ()
  | env::envs ->
    let (p, out, k) = simulate_one env p in
    Printf.printf "[%s] -> [%s]\n"
      (string_of_env env)
      (string_of_env out);
    if k = 0 then () else
    let _ = read_line () in
    simulate envs p