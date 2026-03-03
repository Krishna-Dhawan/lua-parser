%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

FILE *out;   /* Output file pointer */
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
ARITHOP    [\+\-\*/]
RELOP      (==|~=|<=|>=|<|>)

%%

"--[["                  { BEGIN(MULTI_COMMENT); }
"--"                    { BEGIN(SINGLE_COMMENT); }

<MULTI_COMMENT>"]]"     { BEGIN(INITIAL);       /* Exit multi-line comment */ }
<MULTI_COMMENT>\n       { /* Ignore newlines */ lineno++; }
<MULTI_COMMENT>.        { /* Ignore everything else */ }

<SINGLE_COMMENT>\n      { BEGIN(INITIAL); lineno++;       /* Exit on newline */ }
<SINGLE_COMMENT>.       { /* Ignore everything else */ }


"local"        { fprintf(out, "TOKEN: LOCAL\n"); }
"function"     { fprintf(out, "TOKEN: FUNCTION\n"); }
"if"           { fprintf(out, "TOKEN: IF\n"); }
"else"         { fprintf(out, "TOKEN: ELSE\n"); }
"elseif"       { fprintf(out, "TOKEN: ELSEIF\n"); }
"then"         { fprintf(out, "TOKEN: THEN\n"); }
"end"          { fprintf(out, "TOKEN: END\n"); }
for            { fprintf(out, "TOKEN: FOR\n"); }
"while"        { fprintf(out, "TOKEN: WHILE\n"); }
"do"           { fprintf(out, "TOKEN: DO\n"); }
"and"          { fprintf(out, "TOKEN: AND\n"); }
"or"           { fprintf(out, "TOKEN: OR\n"); }
"not"          { fprintf(out, "TOKEN: NOT\n"); }
"in"           { fprintf(out, "TOKEN: IN\n"); }
"break"        { fprintf(out, "TOKEN: BREAK\n"); }
"return"       { fprintf(out, "TOKEN: RETURN\n"); }



"="            { fprintf(out, "TOKEN: ASSIGN\n"); }

".."           { fprintf(out, "TOKEN: CONCAT\n"); }
"."            { fprintf(out, "TOKEN: DOT\n"); }
":"            { fprintf(out, "TOKEN: COLON\n"); }
","            { fprintf(out, "TOKEN: COMMA\n"); }
";"            { fprintf(out, "TOKEN: SEMICOLON\n"); }

"("            { fprintf(out, "TOKEN: LPAREN\n"); }
")"            { fprintf(out, "TOKEN: RPAREN\n"); }
"{"            { fprintf(out, "TOKEN: LBRACE\n"); }
"}"            { fprintf(out, "TOKEN: RBRACE\n"); }
"["            { fprintf(out, "TOKEN: LBRACKET\n"); }
"]"            { fprintf(out, "TOKEN: RBRACKET\n"); }

\"([^\\\"]|\\.)*\"             { fprintf(out, "TOKEN: STRING (%s)\n", yytext); }
\'([^\\\']|\\.)*\'             { fprintf(out, "TOKEN: STRING (%s)\n", yytext); }

{BOOLEAN}      { fprintf(out, "TOKEN: BOOLEAN (%s)\n", yytext);}
"nil"          { fprintf(out, "TOKEN: NIL\n");}

{ARITHOP}      { fprintf(out, "TOKEN: ARITHOP (%s)\n", yytext); }
{RELOP}        { fprintf(out, "TOKEN: RELOP (%s)\n", yytext); }

{HEX_NUMBER}   {
                    long decimal_val = strtol(yytext, NULL, 16);
                    fprintf(out, "TOKEN: HEX_NUMBER (Decimal: %ld)\n", decimal_val);
               }

{BIN_NUMBER}   {
                    char temp[256];
                    int len = strlen(yytext);

                    if (len > 255) len = 255;

                    strncpy(temp, yytext, len - 1);
                    temp[len - 1] = '\0';

                    long decimal_val = strtol(temp, NULL, 2);
                    fprintf(out, "TOKEN: BIN_NUMBER (Decimal: %ld)\n", decimal_val);
               }

{DIGIT}+{LETTER}+({LETTER}|{DIGIT})* { 
                 fprintf(out, "LEXICAL ERROR: Invalid Identifier %s at Line number: %d\n", yytext, lineno); 
               }

{NUMBER}       { fprintf(out, "TOKEN: NUMBER (%s)\n", yytext); }
{ID}           { fprintf(out, "TOKEN: IDENTIFIER (%s)\n", yytext); }

[ \t\r]+     ;   /* Ignore whitespace */
[\n]           { lineno++; }

.              { fprintf(out, "LEXICAL ERROR: %s at Line number: %d", yytext, lineno); }

%%

int main(int argc, char *argv[]){
    if (argc != 3)
    {
        printf("Usage: %s <inputfile> <outputfile>\n", argv[0]);
        return 1;
    }

    FILE *in = fopen(argv[1], "r");
    if (!in)
    {
        printf("Error: Cannot open input file '%s'.\n", argv[1]);
        return 1;
    }

    printf("Input file opened successfully: %s\n", argv[1]);

    out = fopen(argv[2], "w");
    if (!out)
    {
        printf("Error: Cannot open output file '%s'.\n", argv[2]);
        fclose(in);
        return 1;
    }

    printf("Output file opened successfully: %s\n", argv[2]);

    yyin = in;
    yylex();

    fclose(in);
    fclose(out); 
    printf("Lexical analysis completed. Output written to %s\n", argv[2]);

    return 0;
}
