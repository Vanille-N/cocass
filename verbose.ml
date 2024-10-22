(*
 *  Copyright (c) 2005 by Laboratoire Spécification et Vérification (LSV),
 *  UMR 8643 CNRS & ENS Cachan.
 *  Written by Jean Goubault-Larrecq.  Not derived from licensed software.
 *  Edited by Neven Villani
 *
 *  Permission is granted to anyone to use this software for any
 *  purpose on any computer system, and to redistribute it freely,
 *  subject to the following restrictions:
 *
 *  1. Neither the author nor its employer is responsible for the consequences
 *     of use of this software, no matter how awful, even if they arise
 *     from defects in it.
 *
 *  2. The origin of this software must not be misrepresented, either
 *     by explicit claim or by omission.
 *
 *  3. Altered versions must be plainly marked as such, and must not
 *     be misrepresented as being the original software.
 *     NOTE: This is an altered version
 *
 *  4. This software is restricted to non-commercial use only.  Commercial
 *     use is subject to a specific license, obtainable from LSV.
 *
 *)

let verbose = ref 0
let reduce_exprs = ref false

let say i loc msg =
    if !verbose >= i then
        Error.warning loc msg

let info = say 1
let detail = say 2 None
