%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int yylex();
extern int lineno;
void yyerror(const char *s);
%}

%union {
    double dval;
    char *sval;
}

%token <sval> IDENTIFIER STRING BOOLEAN
%token <dval> NUMBER

%token LOCAL FUNCTION IF ELSE ELSEIF THEN END WHILE DO FOR IN BREAK RETURN
%token AND OR NOT NIL

%token ASSIGN CONCAT DOT COLON COMMA SEMICOLON
%token LPAREN RPAREN LBRACE RBRACE LBRACKET RBRACKET
%token PLUS MINUS STAR SLASH EQ NEQ LEQ GEQ LT GT

%left OR
%left AND
%nonassoc EQ NEQ LT GT LEQ GEQ
%right CONCAT
%left PLUS MINUS
%left STAR SLASH
%right NOT
%right UMINUS

%start program

%%

program:
    block { printf("Parsing finished successfully\n"); }
    ;

block:
    statement_seq opt_last_statement
    ;

statement_seq:
    /* empty */
    | statement_seq statement opt_semicolon
    ;

opt_last_statement:
    /* empty */
    | last_statement opt_semicolon
    ;

opt_semicolon:
    /* empty */
    | SEMICOLON
    ;

statement:
    declaration_stmt
    | assign_stmt
    | if_stmt
    | while_stmt
    | for_stmt
    | function_stmt
    | call_stmt
    ;

last_statement:
    BREAK
    | RETURN
    | RETURN expr_list
    ;

declaration_stmt:
    LOCAL name_list
    | LOCAL name_list ASSIGN expr_list
    | LOCAL FUNCTION IDENTIFIER function_body
    ;

function_stmt:
    FUNCTION function_name function_body
    ;

function_body:
    LPAREN opt_param_list RPAREN block END
    ;

assign_stmt:
    assign_target_list ASSIGN expr_list
    ;

if_stmt:
    IF expression THEN block else_if_list opt_else END
    ;

else_if_list:
    /* empty */
    | else_if_list ELSEIF expression THEN block
    ;

while_stmt:
    WHILE expression DO block END
    ;

for_stmt:
    FOR IDENTIFIER ASSIGN expression COMMA expression opt_for_step DO block END
    | FOR name_list IN in_expr_list DO block END
    ;

opt_for_step:
    /* empty */
    | COMMA expression
    ;

in_expr_list:
    in_expression
    | in_expr_list COMMA in_expression
    ;

in_expression:
    expression
    | call_stmt
    ;

function_name:
    IDENTIFIER
    | function_name DOT IDENTIFIER
    | function_name COLON IDENTIFIER
    ;

opt_param_list:
    /* empty */
    | name_list
    ;

name_list:
    IDENTIFIER
    | name_list COMMA IDENTIFIER
    ;

assign_target_list:
    prefix_expression
    | assign_target_list COMMA prefix_expression
    ;

prefix_expression:
    IDENTIFIER
    | LPAREN expression RPAREN
    | prefix_expression DOT IDENTIFIER
    | prefix_expression LBRACKET expression RBRACKET
    ;

call_stmt:
    prefix_expression arguments
    | prefix_expression COLON IDENTIFIER arguments
    ;

arguments:
    LPAREN opt_expr_list RPAREN
    ;

opt_expr_list:
    /* empty */
    | expr_list
    ;

expr_list:
    expression
    | expr_list COMMA expression
    ;

opt_else:
    /* empty */
    | ELSE block
    ;

expression:
    NIL
    | BOOLEAN
    | NUMBER
    | STRING
    | prefix_expression
    | table_constructor
    | FUNCTION function_body
    | NOT expression
    | MINUS expression %prec UMINUS
    | expression PLUS expression
    | expression MINUS expression
    | expression STAR expression
    | expression SLASH expression
    | expression CONCAT expression
    | expression EQ expression
    | expression NEQ expression
    | expression LT expression
    | expression GT expression
    | expression LEQ expression
    | expression GEQ expression
    | expression AND expression
    | expression OR expression
    ;

table_constructor:
    LBRACE opt_field_list RBRACE
    ;

opt_field_list:
    /* empty */
    | field_list
    ;

field_list:
    field
    | field_list field_sep field
    | field_list field_sep
    ;

field_sep:
    COMMA
    | SEMICOLON
    ;

field:
    IDENTIFIER ASSIGN expression
    | LBRACKET expression RBRACKET ASSIGN expression
    | expression
    ;

%%

void yyerror(const char* s) {
    fprintf(stderr, "Syntax error at line %d: %s\n", lineno, s);
}

int main(void) {
    return yyparse();
}
