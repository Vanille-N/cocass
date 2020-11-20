open Printf

let color c = sprintf "\x1b[1;%dm" c
let wrap c s = sprintf "\x1b[1;%dm%s\x1b[0m" c s

let code_red = 31
let code_green = 32
let code_yellow = 33
let code_blue = 34
let code_purple = 35

let red = color code_red
let green = color code_green
let yellow = color code_yellow
let blue = color code_blue
let purple = color code_purple
let reset = color 0

let wrap_red = wrap code_red
let wrap_green = wrap code_green
let wrap_yellow = wrap code_yellow
let wrap_blue = wrap code_blue
let wrap_purple = wrap code_purple
