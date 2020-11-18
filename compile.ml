open Cparse
open Genlab
open Format

let compile out decl_list =
  fprintf out ".global main
.text
main:
    mov $60, %%rax
    mov $42, %%rdi
    syscall
"
