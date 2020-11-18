open Cparse
open Genlab
open Printf

let compile out decl_list =
  fprintf out ".global main
.text
main:
    mov $60, %%rax
    mov $42, %%rdi
    syscall
"
