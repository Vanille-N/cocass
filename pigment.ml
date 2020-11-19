open Printf

let color c s =
    sprintf "\x1b[%sm%s\x1b[0m" c s

let red = color "31"
let green = color "32"
