open Printf

let has_color = true

let color_bold = sprintf "\x1b[1;%dm"
let color = sprintf "\x1b[%dm"

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

let red = color code_red
let green = color code_green
let yellow = color code_yellow
let blue = color code_blue
let purple = color code_purple
let gray = color code_gray
let cyan = color code_cyan

let reset = color 0
