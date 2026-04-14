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
    statement_list { printf("Parsing done\n"); }
    ;

statement_list:
    /* empty */
    | statement_list statement opt_semicolon
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
    | function_stmt
    | function_call
    | BREAK
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
    LPAREN opt_param_list RPAREN statement_list END
    ;

assign_stmt:
    var_list ASSIGN expr_list
    ;

if_stmt:
    IF expression THEN statement_list else_if_list opt_else END
    ;

else_if_list:
    /* empty */
    | else_if_list ELSEIF expression THEN statement_list
    ;

while_stmt:
    WHILE expression DO statement_list END
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

var_list:
    var
    | var_list COMMA var
    ;

var:
    IDENTIFIER
    | prefix_expression DOT IDENTIFIER
    | prefix_expression LBRACKET expression RBRACKET
    ;

prefix_expression:
    var
    | function_call
    | LPAREN expression RPAREN
    ;

function_call:
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
    | ELSE statement_list
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

void main() {
    
}
