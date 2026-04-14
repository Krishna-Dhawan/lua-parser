%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "y.tab.h"

int lineno = 1;

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
"function"     { return FUNCTION; }
"if"           { return IF; }
"else"         { return ELSE; }
"elseif"       { return ELSEIF; }
"then"         { return THEN; }
"end"          { return END; }
"for"          { return FOR; }
"while"        { return WHILE; }
"do"           { return DO; }
"and"          { return AND; }
"or"           { return OR; }
"not"          { return NOT; }
"nil"          { return NIL; }
"in"           { return IN; }
"break"        { return BREAK; }
"return"       { return RETURN; }



"="            { return ASSIGN; }

".."           { return CONCAT; }
"."            { return DOT; }
":"            { return COLON; }
","            { return COMMA; }
";"            { return SEMICOLON; }

"("            { return LPAREN; }
")"            { return RPAREN; }
"{"            { return LBRACE; }
"}"            { return RBRACE; }
"["            { return LBRACKET; }
"]"            { return RBRACKET; }

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

{BOOLEAN}      { return BOOLEAN; }

{HEX_NUMBER}   { yylval.dval = strtod(yytext, NULL);
                return NUMBER; }
{BIN_NUMBER}   { yylval.dval = strtod(yytext, NULL, 2);
                return NUMBER; }

{DIGIT}+{LETTER}+({LETTER}|{DIGIT})* {
                 fprintf(stderr, "LEXICAL ERROR: Invalid Identifier %s at Line number: %d\n", yytext, lineno);
               }

{NUMBER}       { yylval.dval = strtod(yytext, NULL);
                return NUMBER; }
{ID}           { yylval.sval = strdup(yytext); 
                return IDENTIFIER; }

[ \t\r]+       { }
[\n]           { lineno++; }

.              { fprintf(stderr, "LEXICAL ERROR: %s at Line number: %d\n", yytext, lineno); }

%%
