open Printf

let has_color = true

let color_bold = if has_color then (sprintf "\x1b[1;%dm") else (fun _ -> "")
let wrap_bold = if has_color then (sprintf "\x1b[1;%dm%s\x1b[0m") else (fun _ s -> s)
let color = if has_color then (sprintf "\x1b[%dm") else (fun _ -> "")
let wrap = if has_color then (sprintf "\x1b[%dm%s\x1b[0m") else (fun _ s -> s)

let code_red = 31
let code_green = 32
let code_yellow = 33
let code_blue = 34
let code_purple = 35
let code_gray = 37
let code_cyan = 36

let red_bold = color_bold code_red
let green_bold = color_bold code_green
let yellow_bold = color_bold code_yellow
let blue_bold = color_bold code_blue
let purple_bold = color_bold code_purple
let gray_bold = color_bold code_gray
let cyan_bold = color_bold code_cyan

let wrap_red_bold = wrap_bold code_red
let wrap_green_bold = wrap_bold code_green
let wrap_yellow_bold = wrap_bold code_yellow
let wrap_blue_bold = wrap_bold code_blue
let wrap_purple_bold = wrap_bold code_purple
let wrap_gray_bold = wrap_bold code_gray
let wrap_cyan_bold = wrap_bold code_cyan

let red = color code_red
let green = color code_green
let yellow = color code_yellow
let blue = color code_blue
let purple = color code_purple
let gray = color code_gray
let cyan = color code_cyan

let wrap_red = wrap code_red
let wrap_green = wrap code_green
let wrap_yellow = wrap code_yellow
let wrap_blue = wrap code_blue
let wrap_purple = wrap code_purple
let wrap_gray = wrap code_gray
let wrap_cyan = wrap code_cyan

let reset = color 0
