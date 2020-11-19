open Cparse
open Format

let print_declarations out dec_list =
  Format.fprintf out "Todo\n"

let print_locator out nom fl fc ll lc =
  fprintf out "in file <%s> from %d:%d to %d:%d" nom fl fc ll lc

let print_ast out dec_list =
  match dec_list with
    | CDECL(loc, str) -> fprintf out "foo"
