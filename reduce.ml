open CAST

let reduce_exprs = ref false

(* reduce expressions *)
let rec redexp consts e =
    if not !reduce_exprs then (
        e
    ) else (
        let maxreduce_add e = abs e < 1000000 in
        let maxreduce_mul e = abs e < 10000 in
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
            | loc, SET_VAR (name, value) -> (loc, SET_VAR (name, redexp consts value))
            | loc, SET_ARRAY (name, idx, value) -> (loc, SET_ARRAY (name, redexp consts idx, redexp consts value))
            | loc, SET_DEREF (addr, value) -> (loc, SET_DEREF (redexp consts addr, redexp consts value))
            | loc, CALL (fn, args) -> (loc, CALL (fn, List.map (redexp consts) args))
            | loc, OPSET_VAR (op, name, value) -> (loc, OPSET_VAR (op, name, redexp consts value))
            | loc, OPSET_ARRAY (op, name, idx, value) -> (loc, OPSET_ARRAY (op, name, redexp consts idx, redexp consts value))
            | loc, OPSET_DEREF (op, addr, value) -> (loc, OPSET_DEREF (op, redexp consts addr, redexp consts value))
            | loc, ESEQ lst -> (loc, ESEQ (List.map (redexp consts) lst))
            | loc, CMP (op, lhs, rhs) -> (
                let lhs = redexp consts lhs in
                let rhs = redexp consts rhs in
                match (result lhs, result rhs) with
                    | Some x, Some y -> (
                        (loc, CST (match op with
                            | C_EQ -> if x = y then 1 else 0
                            | C_GE -> if x >= y then 1 else 0
                            | C_LE -> if x <= y then 1 else 0
                            | C_GT -> if x > y then 1 else 0
                            | C_LT -> if x < y then 1 else 0
                        ))
                    )
                    | _ -> (loc, CMP (op, lhs, rhs))
            )
            | loc, OP1 (op, value) -> (
                let value = redexp consts value in
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
                let lhs = redexp consts lhs in
                let rhs = redexp consts rhs in
                match (result lhs, result rhs) with
                    | Some x, Some y -> (
                        (loc, match op with
                            | S_ADD when maxreduce_add (x + y) -> CST (x + y)
                            | S_MUL when maxreduce_mul (x * y) -> CST (x * y)
                            | S_SUB when maxreduce_add (x - y) -> CST (x - y)
                            | _ -> OP2 (op, lhs, rhs)
                        )
                    )
                    | _ -> (loc, OP2 (op, lhs, rhs))
            )
            | loc, EIF (cond, etrue, efalse) -> (
                let cond = redexp consts cond in
                match result cond with
                    | Some 0 -> redexp consts efalse
                    | Some _ -> redexp consts etrue
                    | None -> loc, EIF (cond, redexp consts etrue, redexp consts efalse)
            )
    )
