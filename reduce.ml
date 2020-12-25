open CAST

let reduce_exprs = ref false

let cmp_rev = function
    | C_NE -> C_EQ
    | C_EQ -> C_NE
    | C_GT -> C_LE
    | C_LE -> C_GT
    | C_GE -> C_LT
    | C_LT -> C_GE

(* reduce expressions *)
let rec redexp ?force:(force=false) consts e =
    if not force && not !reduce_exprs then (
        e
    ) else (
        let rec aux e =
            let maxreduce e = abs e < 1000000 in
            let rec result e = match snd e with
                | CST c -> Some c
                | _ -> None
            in
            match e with
                | loc, VAR name -> (
                    match List.assoc_opt name consts with
                        | None -> (loc, VAR name)
                        | Some k -> (loc, CST k)
                )
                | loc, CST c -> (loc, CST c)
                | loc, STRING s -> (loc, STRING s)
                | loc, SET (pos, value) -> (loc, SET (aux pos, aux value))
                | loc, CALL (fn, args) -> (loc, CALL (fn, List.map (aux) args))
                | loc, OPSET (op, pos, value) -> (loc, OPSET (op, aux pos, aux value))
                | loc, ESEQ lst -> (loc, ESEQ (List.map (aux) lst))
                | loc, CMP (op, lhs, rhs) -> (
                    let lhs = aux lhs in
                    let rhs = aux rhs in
                    match (result lhs, result rhs) with
                        | Some x, Some y -> (
                            (loc, CST (match op with
                                | C_EQ -> if x = y then 1 else 0
                                | C_GE -> if x >= y then 1 else 0
                                | C_LE -> if x <= y then 1 else 0
                                | C_GT -> if x > y then 1 else 0
                                | C_LT -> if x < y then 1 else 0
                                | C_NE -> if x <> y then 1 else 0
                            ))
                        )
                        | _ -> (loc, CMP (op, lhs, rhs))
                )
                | loc, OP1 (op, value) -> (
                    let value = aux value in
                    match result value with
                        | Some x -> (
                            (loc, match op with
                                | M_MINUS -> CST (-x)
                                | M_NOT -> CST (-x-1)
                                | _ -> OP1 (op, (loc, CST x))
                            )
                        )
                        | None -> (loc, (OP1 (op, value)))
                )
                | loc, OP2 (op, lhs, rhs) -> (
                    let lhs = aux lhs in
                    let rhs = aux rhs in
                    match (result lhs, result rhs) with
                        | Some x, Some y -> (
                            (loc, match op with
                                | S_ADD when maxreduce (x + y) -> CST (x + y)
                                | S_MUL when maxreduce (x * y) -> CST (x * y)
                                | S_SUB when maxreduce (x - y) -> CST (x - y)
                                | S_DIV when y = 0 -> (
                                    Error.warning (Some loc) "division by zero detected";
                                    OP2 (op, lhs, rhs)
                                )
                                | S_DIV -> CST (
                                    if x >= 0 && y > 0 then x / y
                                    else if x > 0 then -(abs x / abs y)
                                    else if y > 0 then -(abs x / abs y)
                                    else abs x / abs y
                                )
                                | S_MOD when y = 0 -> (
                                    Error.warning (Some loc) "division by zero detected";
                                    OP2 (op, lhs, rhs)
                                )
                                | S_MOD -> CST (
                                    x mod abs y
                                )
                                | S_AND -> CST (x land y)
                                | S_OR -> CST (x lor y)
                                | S_XOR -> CST (x lxor y)
                                | S_SHL when y < 0 -> (
                                    Error.warning (Some loc) "negative shift amount";
                                    OP2 (op, lhs, rhs)
                                )
                                | S_SHL when y <= 10 && maxreduce (x lsl y) -> CST (x lsl y)
                                | S_SHR when y < 0 -> (
                                    Error.warning (Some loc) "negative shift amount";
                                    OP2 (op, lhs, rhs)
                                )
                                | S_SHR when y <= 10 && maxreduce (x lsr y) -> CST (x lsr y)
                                | S_SHR -> OP2 (op, lhs, rhs)
                                | _ -> OP2 (op, lhs, rhs)
                            )
                        )
                        | _ -> (loc, OP2 (op, lhs, rhs))
                )
                | loc, EIF (cond, etrue, efalse) -> (
                    match (cond, etrue, efalse) with
                        | (_, CMP (op, lt, rt)), (_, CST 0), (_, CST 1) -> aux (loc, CMP (cmp_rev op, lt, rt))
                        | _ -> (
                            let cond = aux cond in
                            match result cond with
                                | Some 0 -> aux efalse
                                | Some _ -> aux etrue
                                | None -> loc, EIF (cond, aux etrue, aux efalse)
                        )
                )
        in aux e
    )
