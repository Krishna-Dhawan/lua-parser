%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
typedef struct Node Node;
#include "y.tab.h"

int lineno = 1;
int lexical_error = 0;

%}

%option noyywrap
%x MULTI_COMMENT SINGLE_COMMENT

DIGIT      [0-9]
HEX_DIGIT  [0-9a-fA-F]
LETTER     [a-zA-Z_]
ID         {LETTER}({LETTER}|{DIGIT})*
NUMBER     {DIGIT}+(\.{DIGIT}+)?
HEX_NUMBER 0[xX]{HEX_DIGIT}+
BIN_NUMBER [01]+[bB]
BOOLEAN    (true|false)

%%

"--[["                  { BEGIN(MULTI_COMMENT); }
"--"                    { BEGIN(SINGLE_COMMENT); }

<MULTI_COMMENT>"]]"     { BEGIN(INITIAL); }
<MULTI_COMMENT>\n       { lineno++; }
<MULTI_COMMENT>.        { }

<SINGLE_COMMENT>\n      { BEGIN(INITIAL); lineno++; }
<SINGLE_COMMENT>.       { }

"local"        { return LOCAL; }
"if"           { return IF; }
"else"         { return ELSE; }
"then"         { return THEN; }
"end"          { return END; }
"while"        { return WHILE; }
"do"           { return DO; }
"and"          { return AND; }
"or"           { return OR; }
"not"          { return NOT; }
"nil"          { return NIL; }



"="            { return ASSIGN; }

"("            { return LPAREN; }
")"            { return RPAREN; }

"+"            { return PLUS; }
"-"            { return MINUS; }
"*"            { return STAR; }
"/"            { return SLASH; }

"=="           { return EQ; }
"~="           { return NEQ; }
"<="           { return LEQ; }
">="           { return GEQ; }
"<"            { return LT; }
">"            { return GT; }

\"([^\\\"]|\\.)*\"             { yylval.sval = strdup(yytext); 
                                 return STRING; }
\'([^\\\']|\\.)*\'             { yylval.sval = strdup(yytext); 
                                 return STRING; }

{BOOLEAN}      { yylval.sval = strdup(yytext);
                return BOOLEAN; }

{HEX_NUMBER}   { yylval.dval = strtod(yytext, NULL);
                return NUMBER; }
{BIN_NUMBER}   { yylval.dval = (double) strtol(yytext, NULL, 2);
                return NUMBER; }

{DIGIT}+{LETTER}+({LETTER}|{DIGIT})* {
                 fprintf(stderr, "LEXICAL ERROR: Invalid Identifier %s at Line number: %d\n", yytext, lineno);
                 lexical_error = 1;
                 yyterminate();
               }

{NUMBER}       { yylval.dval = strtod(yytext, NULL);
                return NUMBER; }
{ID}           { yylval.sval = strdup(yytext); 
                return IDENTIFIER; }

[ \t\r]+       { }
[\n]           { lineno++; }

.              {
                 fprintf(stderr, "LEXICAL ERROR: %s at Line number: %d\n", yytext, lineno);
                 lexical_error = 1;
                 yyterminate();
               }

%%
