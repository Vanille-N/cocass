open Printf

let color c s =
    sprintf "\x1b[1;%sm%s\x1b[0m" c s

let red = color "31"
let green = color "32"
let yellow = color "33"
let blue = color "34"
let purple = color "35"
