open Printf

type register =
    | RAX
    | RBX | BL
    | RCX | CL
    | RDX | DL
    | RDI
    | RSI
    | RSP
    | RBP
    | R08
    | R09
    | R10
    | RIP

type location =
    | Stack of int
    | Const of int
    | Globl of string
    | FnPtr of string
    | Regst of register
    | Deref of register
    | Index of register * register

type instruction =
    | RET
    | QTO
    | LTQ
    | SYS
    | NOP
    | CAL of string
    | FUN of string
    | INC of location
    | NOT of location
    | NEG of location
    | DEC of location
    | DIV of location
    | MUL of location
    | PSH of location
    | POP of location
    | TAG of string * string
    | JMP of string * string
    | JLE of string * string
    | JLT of string * string
    | JEQ of string * string
    | MOV of location * location
    | LEA of location * location
    | SUB of location * location
    | ADD of location * location
    | XOR of location * location
    | SHL of location * location
    | SHR of location * location
    | AND of location * location
    | IOR of location * location
    | CMP of location * location
    | TST of location * location

type program = {
    mutable idata: string list;
    mutable sdata: (string * string) list;
    mutable text: (instruction * string) list;
}

let decl_int prog name =
    prog.idata <- name :: prog.idata

let decl_str prog name value =
    prog.sdata <- (name, value) :: prog.sdata

let decl_asm prog instr info =
    prog.text <- (instr, info) :: prog.text

let make_prog () =
    {
        idata = [];
        sdata = [];
        text = [];
    }

type alignment =
    | TextRt of string
    | TextLt of string
    | Node of alignment list
    | Skip of int


let generate ((out:out_channel), color) prog =
    let color_reg = if color then Pigment.purple else "" in
    let color_int = if color then Pigment.blue else "" in
    let color_meta = if color then Pigment.reset else "" in
    let color_var = if color then Pigment.cyan else "" in
    let color_tag = if color then Pigment.green else "" in
    let color_instr = if color then Pigment.yellow else "" in
    let color_comment = if color then Pigment.gray else "" in
    let regname r =
        color_reg ^ (
            match r with
                | RAX -> "%rax"
                | RBX -> "%rbx" | BL -> "%bl"
                | RCX -> "%rcx" | CL -> "%cl"
                | RDX -> "%rdx" | DL -> "%dl"
                | RDI -> "%rdi"
                | RSI -> "%rsi"
                | RSP -> "%rsp"
                | RBP -> "%rbp"
                | R08 -> "%r8"
                | R09 -> "%r9"
                | R10 -> "%r10"
                | RIP -> "%rip"
            )
    in
    let locate = function
        | Stack k -> [
            TextRt (sprintf "%s%d(%s" color_int k (regname RBP));
            TextLt (color_int ^ ")")
        ]
        | Globl v -> [
            TextRt (sprintf "%s%s(%s" color_var v (regname RIP));
            TextLt (color_var ^ ")")
        ]
        | Regst r -> [
            TextRt (sprintf "%s" (regname r));
            Skip 1
        ]
        | Deref r -> [
            TextRt (sprintf "%s(%s" color_int (regname r));
            TextLt (color_int ^ ")")
        ]
        | Const c -> [
            TextRt (sprintf "%s$%d" color_int c);
            Skip 1
        ]
        | Index (addr, idx) -> [
            TextLt (sprintf "%s(%s%s,%s%s,8)" color_int (regname addr) color_int (regname idx) color_int);
            Skip 1
        ]
        | FnPtr f -> [
            TextRt (sprintf "%s%s(%s" color_int f (regname RIP));
            TextLt (color_int ^ ")")
        ]
    in
    let generate_ialign name =
        [TextLt (color_var ^ name ^ ": "); TextLt (sprintf "%s.zero %s8" color_meta color_int)]
    in
    let generate_salign (name, value) =
        [TextLt (color_var ^ name ^ ": "); TextLt (sprintf "%s.string %s\"%s\"" color_meta color_var (String.escaped value))]
    in
    let generate_talign (instr, info) =
        let fmtinfo = TextLt (
            color_comment
            ^ (match instr with FUN _ -> " " | _ -> "")
            ^ (if info = "" then "#" else "# " ^ info)
        ) in
        match instr with
            | RET -> [TextLt (color_instr ^ "    ret "); Skip 5; fmtinfo]
            | QTO -> [TextLt (color_instr ^ "    cqto "); Skip 5; fmtinfo]
            | LTQ -> [TextLt (color_instr ^ "    cltq "); Skip 5; fmtinfo]
            | SYS -> [TextLt (color_instr ^ "    syscall "); Skip 5; fmtinfo]
            | CAL fn -> [TextLt (color_instr ^ "    call "); TextLt (color_tag ^ fn); Skip 4; fmtinfo]
            | FUN fn -> [TextLt ("\n" ^ color_tag ^ fn ^ ":"); Skip 5; fmtinfo]
            | TAG (fn, tag) -> [TextLt (sprintf "  %s%s.%s:" color_tag fn tag); Skip 5; fmtinfo]
            | INC l -> [TextLt (color_instr ^ "    incq "); Node (locate l); Skip 3; fmtinfo]
            | NOT l -> [TextLt (color_instr ^ "    not "); Node (locate l); Skip 3; fmtinfo]
            | NEG l -> [TextLt (color_instr ^ "    neg "); Node (locate l); Skip 3; fmtinfo]
            | DEC l -> [TextLt (color_instr ^ "    decq "); Node (locate l); Skip 3; fmtinfo]
            | DIV l -> [TextLt (color_instr ^ "    idiv "); Node (locate l); Skip 3; fmtinfo]
            | JMP (fn, tag) -> [
                TextLt (color_instr ^ "    jmp ");
                TextLt (sprintf "%s%s.%s" color_tag fn tag);
                Skip 4; fmtinfo]
            | SUB (s, d) -> [
                TextLt (color_instr ^ "    sub ");
                Node (locate s); TextLt ", ";
                Node (locate d); fmtinfo]
            | ADD (s, d) -> [
                TextLt (color_instr ^ "    add ");
                Node (locate s); TextLt ", ";
                Node (locate d); fmtinfo]
            | MOV (s, d) -> [
                TextLt (color_instr ^ "    mov ");
                Node (locate s); TextLt ", ";
                Node (locate d); fmtinfo]
            | LEA (s, d) -> [
                TextLt (color_instr ^ "    lea ");
                Node (locate s); TextLt ", ";
                Node (locate d); fmtinfo]
            | XOR (s, d) -> [
                TextLt (color_instr ^ "    xor ");
                Node (locate s); TextLt ", ";
                Node (locate d); fmtinfo]
            | IOR (s, d) -> [
                TextLt (color_instr ^ "    or ");
                Node (locate s); TextLt ", ";
                Node (locate d); fmtinfo]
            | AND (s, d) -> [
                TextLt (color_instr ^ "    and ");
                Node (locate s); TextLt ", ";
                Node (locate d); fmtinfo]
            | SHL (s, d) -> [
                TextLt (color_instr ^ "    salq ");
                Node (locate s); TextLt ", ";
                Node (locate d); fmtinfo]
            | SHR (s, d) -> [
                TextLt (color_instr ^ "    sarq ");
                Node (locate s); TextLt ", ";
                Node (locate d); fmtinfo]
            | MUL l -> [
                TextLt (color_instr ^ "    mul ");
                Node (locate l);
                Skip 3; fmtinfo]
            | PSH l -> [
                TextLt (color_instr ^ "    push ");
                Node (locate l);
                Skip 3; fmtinfo]
            | POP l -> [
                TextLt (color_instr ^ "    pop ");
                Node (locate l);
                Skip 3; fmtinfo]
            | NOP -> if info = ""
                then [TextLt (color_instr ^ "    nop "); Skip 5; fmtinfo]
                else [Skip 6; fmtinfo]
            | CMP (a, b) -> [
                TextLt (color_instr ^ "    cmp ");
                Node (locate a);
                TextLt ", ";
                Node (locate b); fmtinfo]
            | TST (a, b) -> [
                TextLt (color_instr ^ "    test ");
                Node (locate a);
                TextLt ", ";
                Node (locate b); fmtinfo]
            | JLE (fn, tag) -> [
                TextLt (color_instr ^ "    jle ");
                TextLt (sprintf "%s%s.%s" color_tag fn tag); Skip 4; fmtinfo]
            | JLT (fn, tag) -> [
                TextLt (color_instr ^ "    jl ");
                TextLt (sprintf "%s%s.%s" color_tag fn tag); Skip 4; fmtinfo]
            | JEQ (fn, tag) -> [
                TextLt (color_instr ^ "    je ");
                TextLt (sprintf "%s%s.%s" color_tag fn tag); Skip 4; fmtinfo]
    in
    let display_align out marks text =
        (* printf "newline\n"; *)
        let current = ref 0 in
        let target = ref 0 in
        let marks = ref marks in
        let pop lst =
            let x = List.hd !lst in
            lst := List.tl !lst;
            x
        in
        let true_length str =
            let len = ref 0 in
            let count = ref true in
            for i = 0 to String.length str - 1 do
                if !count then (
                    if str.[i] = '\x1b' then (
                        count := false
                    ) else (
                        incr len
                    )
                ) else (
                    if str.[i] = 'm' then (
                        count := true
                    )
                )
            done;
            !len
        in
        let rec aux = function
            | TextRt t -> (
                let len = true_length t in
                target := !target + pop marks;
                let unused = max 0 (!target - !current - len) in
                fprintf out "%s%s" (String.make unused ' ') t;
                current := len + unused + !current;
            )
            | TextLt t -> (
                let len = true_length t in
                target := !target + pop marks;
                let unused = max 0 (!target - !current - len) in
                fprintf out "%s%s" t (String.make unused ' ');
                current := len + unused + !current;
            )
            | Node l -> List.iter aux l
            | Skip k -> for i = 1 to k do aux (TextLt "") done
        in List.iter aux text;
        fprintf out "\n"
    in
    fprintf out "    %s.data\n" color_meta;
    fprintf out "    %s.align %s8\n" color_meta color_int;
    let idata = List.rev prog.idata in
    let ialign = List.map generate_ialign idata in
    List.iter (display_align out [10; 0]) ialign;
    let sdata = List.rev prog.sdata in
    let salign = List.map generate_salign sdata in
    List.iter (display_align out [10; 0]) salign;
    fprintf out "\n";
    fprintf out "    %s.global %smain\n" color_meta color_tag;
    fprintf out "    %s.text" color_meta;
    let tdata = List.rev prog.text in
    let talign = List.map generate_talign tdata in
    List.iter (display_align out [9; 12; 0; 0; 12; 7; 0]) talign;
