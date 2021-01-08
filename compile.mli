(** generate text output in the output channel, compiled from the function declarations *)
val compile : (out_channel * bool) -> CAST.top_declaration list -> unit;;
