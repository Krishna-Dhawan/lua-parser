%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int yylex();
extern int lineno;
void yyerror(const char *s);
%}

%union {
    long ival;
    char *sval;
}

%token <sval> IDENTIFIER STRING BOOLEAN ARITHOP RELOP
%token <ival> NUMBER

%token LOCAL IF THEN END WHILE DDO AND OR NOT NIL

%token ASSIGN CONCAT DOT COLON COMMA SEMICOLOR
%token LPAREN RPAREN LBRACE RBRACE LBRACKET RBRACKET

%start program

%%

program:
    statement_list { printf("Parsing done\n"); }
    ;

statement_list:
    statement_list statement
    | statement
    ;

statement:
    declaration_stmt
    | assign_stmt
    | if_stmt
    | while_stmt
    ;

declaration_stmt:
    LOCAL IDENTIFIER ASSIGN expression
    ;

assign_stmt:
    IDENTIFIER ASSIGN expression
    ;

expression:
    NUMBER
    | IDENTIFIER
    /* TODO: fill rest */
    ;

if_stmt:
    IF expression THEN statement_list END
    ;

while_stmt:
    WHILE expression DO statement_list END
    ;

%%

void yyerror(const char* s) {
    fprintf(stderr, "Syntax error at line %d: %s\n", lineno, s);
}

void main() {
    
}
