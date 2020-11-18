
(*
 *	Copyright (c) 2005 by Laboratoire Spécification et Vérification (LSV),
 *	CNRS UMR 8643 & ENS Cachan.
 *	Written by Jean Goubault-Larrecq.  Derived from the csur project.
 *
 *	Permission is granted to anyone to use this software for any
 *	purpose on any computer system, and to redistribute it freely,
 *	subject to the following restrictions:
 *
 *	1. Neither the author nor its employer is responsible for the consequences of use of
 *		this software, no matter how awful, even if they arise
 *		from defects in it.
 *
 *	2. The origin of this software must not be misrepresented, either
 *		by explicit claim or by omission.
 *
 *	3. Altered versions must be plainly marked as such, and must not
 *		be misrepresented as being the original software.
 *
 *	4. This software is restricted to non-commercial use only.  Commercial
 *		use is subject to a specific license, obtainable from LSV.
 *)

open Cparse
open Verbose
open Compile
open Arg

let input = ref stdin
let c_prefix = ref "a.out"
let c_E = ref false
let c_A = ref false
let c_D = ref false

let basename s =
  try String.sub s 0 (String.rindex s '.')
  with Not_found -> s

let () =
  parse
    [("-v", Unit (fun () -> verbose:=1), "reports stuff");
     ("-v1", Unit (fun () -> verbose:=1), "reports stuff");
     ("-v2", Unit (fun () -> verbose:=2), "reports stuff, and stuff");
     ("-D", Unit (fun () -> c_D:=true), "print declarations");
     ("-A", Unit (fun () -> c_A:=true), "print abstract syntax tree");
     ("-E", Unit (fun () -> c_E:=true), "output assembler dump")]
    (fun s ->
       c_prefix := basename s;
       input :=
         Unix.open_process_in ("cpp -DMCC \"" ^ (String.escaped s) ^ "\""))
    "compiles a C-- program"

let () =
  let lexbuf = Lexing.from_channel (!input) in
  let c = Ctab.translation_unit Clex.ctoken lexbuf in
  let out = if !c_E then stdout else open_out (!c_prefix ^ ".s") in
    Error.flush_error ();

    if !c_D then begin
      Cprint.print_declarations Format.std_formatter c
    end;
    if !c_A then begin
      Cprint.print_ast Format.std_formatter c
    end;

    if not (!c_D || !c_A) then begin
      compile out c;
      Error.flush_error ()
    end;

    if not (!c_D || !c_A || !c_E) then begin
      flush out;
      close_out_noerr out;
      let command =
        let prefix = String.escaped !c_prefix in
          Printf.sprintf
            "gcc -ggdb -o \"%s\" \"%s.s\" -lc -lm"
            prefix prefix
      in
        ignore (Unix.system command)
    end
