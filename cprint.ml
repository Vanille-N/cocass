open Cparse
open Format

let print_declarations out dec_list =
  Format.fprintf out "Todo\n"

let print_code out code =
    fprintf out "TODO\n"

let print_locator out nom fl fc ll lc =
  fprintf out "in file <%s> from %d:%d to %d:%d" nom fl fc ll lc

let print_ast out dec_list =
    List.iter (function
        | CDECL(_, name) -> fprintf out "decl name <%s>\n" name
        | CFUN(_, name, decs, code) -> (
            fprintf out "func name <%s> args [\n" (Pigment.red name);
            print_declarations out decs;
            fprintf out "] body {\n";
            print_code out code;
            fprintf out "}\n"
        )
    ) dec_list
