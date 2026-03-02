%{
#include <stdio.h>
#include <stdlib.h>

FILE *out;   /* Output file pointer */
%}

%option noyywrap
%x MULTI_COMMENT SINGLE_COMMENT

DIGIT      [0-9]
LETTER     [a-zA-Z_]
ID         {LETTER}({LETTER}|{DIGIT})*
NUMBER     {DIGIT}+(\.{DIGIT}+)?
BOOLEAN    (true|false)

%%

"--[["                  { BEGIN(MULTI_COMMENT); }
"--"                    { BEGIN(SINGLE_COMMENT); }

<MULTI_COMMENT>"]]"     { BEGIN(INITIAL);       /* Exit multi-line comment */ }
<MULTI_COMMENT>\n       { /* Ignore newlines */ }
<MULTI_COMMENT>.        { /* Ignore everything else */ }

<SINGLE_COMMENT>\n      { BEGIN(INITIAL);       /* Exit on newline */ }
<SINGLE_COMMENT>.       { /* Ignore everything else */ }


"local"        { fprintf(out, "TOKEN: LOCAL\n"); }
"if"           { fprintf(out, "TOKEN: IF\n"); }
"then"         { fprintf(out, "TOKEN: THEN\n"); }
"end"          { fprintf(out, "TOKEN: END\n"); }
"while"        { fprintf(out, "TOKEN: WHILE\n"); }
"do"           { fprintf(out, "TOKEN: DO\n"); }
"and"          { fprintf(out, "TOKEN: AND\n"); }
"or"           { fprintf(out, "TOKEN: OR\n"); }
"not"          { fprintf(out, "TOKEN: NOT\n"); }

"=="           { fprintf(out, "TOKEN: EQ\n"); }
"~="           { fprintf(out, "TOKEN: NE\n"); }
"<="           { fprintf(out, "TOKEN: LE\n"); }
">="           { fprintf(out, "TOKEN: GE\n"); }
"<"            { fprintf(out, "TOKEN: LT\n"); }
">"            { fprintf(out, "TOKEN: GT\n"); }

"="            { fprintf(out, "TOKEN: ASSIGN\n"); }
"+"            { fprintf(out, "TOKEN: PLUS\n"); }
"-"            { fprintf(out, "TOKEN: MINUS\n"); }
"*"            { fprintf(out, "TOKEN: MUL\n"); }
"/"            { fprintf(out, "TOKEN: DIV\n"); }

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

{NUMBER}       { fprintf(out, "TOKEN: NUMBER (%s)\n", yytext); }
{ID}           { fprintf(out, "TOKEN: IDENTIFIER (%s)\n", yytext); }

[ \t\r\n]+     ;   /* Ignore whitespace */

.              { fprintf(out, "LEXICAL ERROR: %s\n", yytext); }


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
