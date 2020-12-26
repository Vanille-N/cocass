%{

(*
 * Copyright (c) 2005 by Laboratoire Spécification et Vérification
 * (LSV), UMR 8643 CNRS & ENS Cachan.
 * Written by Jean Goubault-Larrecq.  Derived from the csur project.
 *
 * Permission is granted to anyone to use this software for any
 * purpose on any computer system, and to redistribute it freely,
 * subject to the following restrictions:
 *
 * 1. Neither the author nor its employer is responsible for the
 *    consequences of use of this software, no matter how awful, even if
 *    they arise from defects in it.
 *
 * 2. The origin of this software must not be misrepresented, either
 *    by explicit claim or by omission.
 *
 * 3. Altered versions must be plainly marked as such, and must not
 *    be misrepresented as being the original software.
 *
 * 4. This software is restricted to non-commercial use only.  Commercial
 *    use is subject to a specific license, obtainable from LSV.
 *
 *)

(* Analyse grammaticale d'un sous-ensemble (tres) reduit de C. *)

open CAST
open Error

let parse_error msg =
    fatal (Some (getloc ())) msg

%}

%token <string> IDENTIFIER TYPE_NAME
%token <int> CONSTANT
%token <string> STRING_LITERAL
%token SIZEOF
%token PTR_OP INC_OP DEC_OP LEFT_OP RIGHT_OP LE_OP GE_OP EQ_OP NE_OP
%token AND_OP OR_OP MUL_ASSIGN DIV_ASSIGN MOD_ASSIGN ADD_ASSIGN
%token SUB_ASSIGN LEFT_ASSIGN RIGHT_ASSIGN AND_ASSIGN
%token XOR_ASSIGN OR_ASSIGN
%token SEMI_CHR OPEN_BRACE_CHR CLOSE_BRACE_CHR COMMA_CHR COLON_CHR
%token EQ_CHR OPEN_PAREN_CHR CLOSE_PAREN_CHR OPEN_BRACKET_CHR
%token CLOSE_BRACKET_CHR DOT_CHR AND_CHR OR_CHR XOR_CHR BANG_CHR
%token TILDE_CHR ADD_CHR SUB_CHR STAR_CHR DIV_CHR MOD_CHR
%token OPEN_ANGLE_CHR CLOSE_ANGLE_CHR QUES_CHR
%token TYPEDEF EXTERN STATIC AUTO REGISTER
%token CHAR SHORT INTEGER LONG SIGNED UNSIGNED FLOATING DOUBLE CONST VOLATILE VOID
%token STRUCT UNION ENUM ELLIPSIS EOF
%token CASE DEFAULT IF ELSE SWITCH WHILE DO FOR GOTO CONTINUE BREAK RETURN
%token TRY THROW CATCH FINALLY
%token ASM

%type <(CAST.top_declaration list)> translation_unit

%start translation_unit
%%

primary_expression:
    | identifier { let loc, var = $1 in loc, VAR var }
    | constant { let loc, cst = $1 in loc, CST cst }
    | string_literal { let loc, s = $1 in loc, STRING s }
    | OPEN_PAREN_CHR expression CLOSE_PAREN_CHR { $2 }
;

constant : CONSTANT { getloc (), $1 };

identifier  : IDENTIFIER      { getloc (), $1 };
open_brace  : OPEN_BRACE_CHR  { getloc () };
close_brace : CLOSE_BRACE_CHR { getloc () };

string_literal:
    | STRING_LITERAL { getloc (), $1 }
    | STRING_LITERAL string_literal {
        let l, s = $2 in
        let s2 = $1 in
        (getloc (), s2^s) }
;

inc_op : INC_OP { getloc () }
dec_op : DEC_OP { getloc () }

postfix_expression:
    | primary_expression { $1 }
    | postfix_expression OPEN_BRACKET_CHR expression close_bracket
        { sup_locator (loc_of_expr $1) $4, OP2 (S_INDEX, $1, $3) }
    | identifier OPEN_PAREN_CHR close_paren {
        let loc, var = $1 in
        let loc1 = sup_locator loc $3 in
        loc1, CALL (var, []) }
    | identifier OPEN_PAREN_CHR argument_expression_list close_paren {
        let loc, var = $1 in
        let loc1 = sup_locator loc $4 in
        loc1, CALL (var, List.rev $3) }
    | postfix_expression inc_op
        { sup_locator (loc_of_expr $1) $2, OP1 (M_POST_INC, $1) }
    | postfix_expression dec_op
        { sup_locator (loc_of_expr $1) $2, OP1 (M_POST_DEC, $1) }
;

/* Les argument_expression_list sont des listes a l'envers */

argument_expression_list:
    | assignment_expression { [$1] }
    | argument_expression_list COMMA_CHR assignment_expression
        { $3 :: $1 }
;

unary_expression:
    | postfix_expression { $1 }
    | inc_op unary_expression
        { sup_locator $1 (loc_of_expr $2), OP1 (M_PRE_INC, $2) }
    | dec_op unary_expression
        { sup_locator $1 (loc_of_expr $2), OP1 (M_PRE_DEC, $2) }
    | unary_operator cast_expression {
        let loc, c = $1 in
        let loc' = sup_locator loc (loc_of_expr $2) in
        match c with
            | ADD_CHR -> $2
            | SUB_CHR -> loc', OP1 (M_MINUS, $2)
            | BANG_CHR -> loc', EIF ($2, (loc', CST 0), (loc', CST 1))
            | TILDE_CHR -> loc', OP1 (M_NOT, $2)
            | AND_CHR -> loc', OP1 (M_ADDR, $2)
            | STAR_CHR -> loc', OP1 (M_DEREF, $2)
            | _ -> (Error.error (Some loc) "unknown unary operator"; loc, CST 0) }
;

unary_operator:
    | add_chr   { $1 }
    | sub_chr   { $1 }
    | bang_chr  { $1 }
    | tilde_chr { $1 }
    | star_chr  { $1 }
    | and_chr   { $1 }
;

add_chr   : ADD_CHR   { getloc (), ADD_CHR   }
sub_chr   : SUB_CHR   { getloc (), SUB_CHR   }
bang_chr  : BANG_CHR  { getloc (), BANG_CHR  }
tilde_chr : TILDE_CHR { getloc (), TILDE_CHR }
star_chr  : STAR_CHR  { getloc (), STAR_CHR  }
and_chr   : AND_CHR   { getloc (), AND_CHR   }

close_paren : CLOSE_PAREN_CHR { getloc () }

cast_expression:
    unary_expression { $1 }
;

multiplicative_expression:
    | cast_expression { $1 }
    | multiplicative_expression STAR_CHR cast_expression {
        sup_locator (loc_of_expr $1) (loc_of_expr $3),
        OP2 (S_MUL, $1, $3) }
    | multiplicative_expression DIV_CHR cast_expression {
        sup_locator (loc_of_expr $1) (loc_of_expr $3),
        OP2 (S_DIV, $1, $3) }
    | multiplicative_expression MOD_CHR cast_expression {
        sup_locator (loc_of_expr $1) (loc_of_expr $3),
        OP2 (S_MOD, $1, $3) }
;

additive_expression:
    | multiplicative_expression
        { $1 }
    | additive_expression ADD_CHR multiplicative_expression {
        sup_locator (loc_of_expr $1) (loc_of_expr $3),
        OP2 (S_ADD, $1, $3) }
    | additive_expression SUB_CHR multiplicative_expression {
        sup_locator (loc_of_expr $1) (loc_of_expr $3),
        OP2 (S_SUB, $1, $3) }
;

shift_expression:
    | additive_expression { $1 }
    | additive_expression LEFT_OP multiplicative_expression {
        sup_locator (loc_of_expr $1) (loc_of_expr $3),
        OP2 (S_SHL, $1, $3) }
    | additive_expression RIGHT_OP multiplicative_expression {
        sup_locator (loc_of_expr $1) (loc_of_expr $3),
        OP2 (S_SHR, $1, $3) }
;

relational_expression:
    | shift_expression { $1 }
    | relational_expression OPEN_ANGLE_CHR shift_expression {
        sup_locator (loc_of_expr $1) (loc_of_expr $3),
        CMP (C_LT, $1, $3) }
    | relational_expression CLOSE_ANGLE_CHR shift_expression {
        sup_locator (loc_of_expr $1) (loc_of_expr $3),
        CMP (C_LT, $3, $1) }
    | relational_expression LE_OP shift_expression {
        sup_locator (loc_of_expr $1) (loc_of_expr $3),
        CMP (C_LE, $1, $3) }
    | relational_expression GE_OP shift_expression {
        sup_locator (loc_of_expr $1) (loc_of_expr $3),
        CMP (C_LE, $3, $1) }
;

equality_expression:
    | relational_expression { $1 }
    | equality_expression EQ_OP relational_expression {
        sup_locator (loc_of_expr $1) (loc_of_expr $3),
        CMP (C_EQ, $1, $3) }
    | equality_expression NE_OP relational_expression {
        let loc = sup_locator (loc_of_expr $1) (loc_of_expr $3) in
        loc,
        EIF ((loc, CMP (C_EQ, $1, $3)), (loc, CST 0), (loc, CST 1)) }
;

and_expression:
    | equality_expression { $1 }
    | and_expression AND_CHR equality_expression {
        sup_locator (loc_of_expr $1) (loc_of_expr $3),
        OP2 (S_AND, $1, $3) }
;

exclusive_or_expression:
    | and_expression { $1 }
    | exclusive_or_expression XOR_CHR equality_expression {
        sup_locator (loc_of_expr $1) (loc_of_expr $3),
        OP2 (S_XOR, $1, $3) }
;

inclusive_or_expression:
    | exclusive_or_expression { $1 }
    | inclusive_or_expression OR_CHR equality_expression {
        sup_locator (loc_of_expr $1) (loc_of_expr $3),
        OP2 (S_OR, $1, $3) }
;

logical_and_expression:
    | inclusive_or_expression { $1 }
    | logical_and_expression AND_OP inclusive_or_expression {
        let loc = sup_locator (loc_of_expr $1) (loc_of_expr $3) in
        loc, EIF ($1, $3, (loc, CST 0)) }
;

logical_or_expression:
    | logical_and_expression { $1 }
    | logical_or_expression OR_OP logical_and_expression {
        let loc = sup_locator (loc_of_expr $1) (loc_of_expr $3) in
        loc, EIF ($1, (loc, CST 1), $3) }
;

conditional_expression:
    | logical_or_expression { $1 }
    | logical_or_expression QUES_CHR expression COLON_CHR conditional_expression {
        sup_locator (loc_of_expr $1) (loc_of_expr $5),
        EIF ($1, $3, $5) }
;

extended_assignment_operator:
    | ADD_ASSIGN   { S_ADD }
    | MUL_ASSIGN   { S_MUL }
    | SUB_ASSIGN   { S_SUB }
    | DIV_ASSIGN   { S_DIV }
    | MOD_ASSIGN   { S_MOD }
    | OR_ASSIGN    { S_OR  }
    | AND_ASSIGN   { S_AND }
    | XOR_ASSIGN   { S_XOR }
    | LEFT_ASSIGN  { S_SHL }
    | RIGHT_ASSIGN { S_SHR }
;

assignment_expression:
    | conditional_expression { $1 }
    | unary_expression EQ_CHR assignment_expression {
        let locvar, left = $1 in
        let loc = sup_locator locvar (loc_of_expr $3) in
        loc, SET ($1, $3)
    }
    | unary_expression extended_assignment_operator assignment_expression {
        let locvar, left = $1 in
        let loc = sup_locator locvar (loc_of_expr $3) in
        loc, OPSET ($2, $1, $3)
    }
;

expression:
    | assignment_expression { $1 }
    | expression COMMA_CHR assignment_expression {
        sup_locator (loc_of_expr $1) (loc_of_expr $3),
        ESEQ [$1; $3]
    }
;

declaration:
    type_specifier optional_init_declarator_list SEMI_CHR
        { List.rev $2 }
;

optional_init_declarator_list :
    | init_declarator_list { $1 }
    | { [] }
;

/* Une init_declarator_list est une liste a l'envers de declarator. */
init_declarator_list:
    | init_declarator { [$1] }
    | init_declarator_list COMMA_CHR init_declarator
        { $3 :: $1 }
;

declarative_statement: declaration { getloc (), CLOCAL $1 }

init_declarator:
    | identifier EQ_CHR assignment_expression { let loc, x = $1 in ((loc, x), Some $3) }
    | identifier { let loc, x = $1 in ((loc, x), None) }
    | identifier OPEN_PAREN_CHR CLOSE_PAREN_CHR { let loc, x = $1 in ((loc, x), None) }
;

declarator:
    | identifier { $1 }
    | identifier OPEN_PAREN_CHR CLOSE_PAREN_CHR { $1 }
;

type_specifier:
    | INTEGER { () }
    | CHAR { () }
    | LONG { () }
    | VOID { () }
    | type_specifier STAR_CHR { () }
;

close_bracket : CLOSE_BRACKET_CHR { getloc () };

statement:
    | compound_statement { $1 }
    | expression_statement { loc_of_expr $1, CEXPR $1 }
    | selection_statement { $1 }
    | iteration_statement { $1 }
    | jump_statement { $1 }
    | handler_statement { $1 }
    | declarative_statement { $1 }
;

open_block  : open_brace  { $1 };
close_block : close_brace { $1 };

scope_block:
    | statement_list
        { getloc (), CBLOCK (List.rev $1) }
    | { getloc (), CBLOCK [] }
;

compound_statement:
    | open_block scope_block close_block
        { sup_locator $1 $3, snd $2 }
;

/* Une statement_list est une liste inversee de statement */
statement_list:
    | statement { [$1] }
    | statement_list statement { $2 :: $1 }
;

expression_statement:
    | semi_chr { $1, ESEQ [] }
    | expression SEMI_CHR { $1 }
;

semi_chr : SEMI_CHR { getloc () }

casekw    : CASE    { getloc () };
defaultkw : DEFAULT { getloc () };

case :
    | casekw CONSTANT COLON_CHR statement_list
        { $1, $2, ($1, CBLOCK (List.rev $4)) }
    | casekw SUB_CHR CONSTANT COLON_CHR statement_list
        { $1, -$3, ($1, CBLOCK (List.rev $5)) }
    | casekw CONSTANT COLON_CHR
        { $1, $2, ($1, CBLOCK []) }
    | casekw SUB_CHR CONSTANT COLON_CHR
        { $1, -$3, ($1, CBLOCK []) }
;

default :
    | defaultkw COLON_CHR statement_list
        { $1, CBLOCK (List.rev $3) }
    | { getloc (), CBLOCK [] }
;

case_list :
    | case case_list {
        let (rest, deflt) = $2 in
        ($1 :: rest, deflt) }
    | default
        { [], $1 }
;

switch_block : open_block case_list close_block { $2 };

ifkw     : IF     { getloc () };
switchkw : SWITCH { getloc () };

selection_statement:
    | ifkw OPEN_PAREN_CHR expression CLOSE_PAREN_CHR statement
        { sup_locator $1 (fst $5), CIF ($3, $5, (getloc (), CBLOCK [])) }
    | ifkw OPEN_PAREN_CHR expression CLOSE_PAREN_CHR statement ELSE statement
        { sup_locator $1 (fst $7), CIF ($3, $5, $7) }
    | switchkw OPEN_PAREN_CHR expression CLOSE_PAREN_CHR switch_block {
        let (cases, deflt) = $5 in
        ($1, CSWITCH ($3, cases, deflt)) }
;

whilekw : WHILE { getloc () };
forkw   : FOR   { getloc () };
dokw    : DO    { getloc () };

iteration_statement:
    | whilekw OPEN_PAREN_CHR expression close_paren statement {
        let loc = sup_locator $1 (fst $5) in
        loc, CWHILE ($3, $5, (loc, ESEQ []), true)
    }
    | forkw OPEN_PAREN_CHR expression_statement expression_statement close_paren statement
    /* for (e0; e; ) c == e0; while (e) c; */ {
        let loc = sup_locator $1 (fst $6) in
        loc, CBLOCK ([
            (loc_of_expr $3, CEXPR $3);
            (loc, CWHILE ($4, $6, (loc, ESEQ []), true))
        ])
    }
    | forkw OPEN_PAREN_CHR expression_statement expression_statement expression close_paren statement
    /* for (e0; e; e1) c == e0; while (e) { c; e1 } */ {
        let loc = sup_locator $1 (fst $7) in
        loc, CBLOCK ([
            (loc_of_expr $3, CEXPR $3);
            loc, CWHILE ($4, $7, $5, true)
        ])
    }
    | dokw statement whilekw expression SEMI_CHR {
        let loc = sup_locator $1 (fst $2) in
        loc, CWHILE ($4, $2, (loc, ESEQ []), false)
    }
;

trykw: TRY { getloc () };
catchkw: CATCH { getloc () };
finallykw: FINALLY { getloc () };

finally_option:
    | finallykw statement
        { $2 }
    | { getloc (), CBLOCK [] }

catch:
    | catchkw OPEN_PAREN_CHR identifier CLOSE_PAREN_CHR statement
        { $1, snd $3, "_", $5 }
    | catchkw OPEN_PAREN_CHR identifier identifier CLOSE_PAREN_CHR statement
        { $1, snd $3, snd $4, $6 }
;

catch_list:
    | { [] }
    | catch_list catch
        { $2 :: $1 }
;

try_catch:
    | trykw statement catch_list
        { $1, $2, List.rev $3 }
;

handler_statement:
    | try_catch finally_option {
        let (tryloc, code, catches) = $1 in
        tryloc, CTRY (code, catches, $2) }
;

return   : RETURN   { getloc () };
break    : BREAK    { getloc () };
continue : CONTINUE { getloc () };
throw    : THROW    { getloc () };

jump_statement:
    | return SEMI_CHR
        { $1, CRETURN None }
    | return expression SEMI_CHR
        { sup_locator $1 (loc_of_expr $2), CRETURN (Some $2) }
    | break SEMI_CHR
        { $1, CBREAK }
    | continue SEMI_CHR
        { $1, CCONTINUE }
    | throw identifier SEMI_CHR
        { $1, CTHROW (snd $2, (fst $2, VAR "NULL")) }
    | throw identifier OPEN_PAREN_CHR expression CLOSE_PAREN_CHR SEMI_CHR
        { $1, CTHROW (snd $2, $4) }
;

translation_unit:
    | external_declaration { $1 }
    | translation_unit external_declaration { $1 @ $2 }
    | EOF { [] }
;

external_declaration:
    | function_definition { [$1] }
    | declaration { List.map (fun (id, init) -> CDECL (id, init)) $1 }
;

parameter_declaration: type_specifier declarator { $2 };

/*!!!should check no repeated param name! */
/* Une parameter_list est une liste inversee de parameter_list. */
parameter_list:
    | parameter_declaration { [$1] }
    | parameter_list COMMA_CHR parameter_declaration
        { $3 :: $1 }
;

ellipsis: ELLIPSIS { (getloc (), "...") }

parameter_type_list:
    | parameter_list { List.rev $1}
    | parameter_list COMMA_CHR ellipsis { $3 :: List.rev $1 }
;

parameter_declarator:
    | OPEN_PAREN_CHR CLOSE_PAREN_CHR { [] }
    | OPEN_PAREN_CHR VOID CLOSE_PAREN_CHR { [] }
    | OPEN_PAREN_CHR parameter_type_list CLOSE_PAREN_CHR { $2 }
;

function_declarator:
    type_specifier identifier parameter_declarator
        { $2, $3 }
;

function_definition:
    | function_declarator compound_statement {
        let (loc, var), decls = $1 in
        CFUN ((loc, var), decls, $2)
    }
;

%%
