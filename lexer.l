%{
#include <stdio.h>
#include <stdlib.h>

FILE *out;   /* Output file pointer */
%}

%option noyywrap

DIGIT      [0-9]
LETTER     [a-zA-Z_]
ID         {LETTER}({LETTER}|{DIGIT})*
NUMBER     {DIGIT}+(\.{DIGIT}+)?

%%

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

"("            { fprintf(out, "TOKEN: LPAREN\n"); }
")"            { fprintf(out, "TOKEN: RPAREN\n"); }
";"            { fprintf(out, "TOKEN: SEMICOLON\n"); }

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

    FILE *in = fopen(argv[1], "r");  // ← Use argv[1], not hardcoded "valid.lua"
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

    printf("Output file opened successfully: %s\n", argv[2]);  // add this
    fprintf(out, "TEST LINE\n");  // add this

    yyin = in;

    yylex();

    fclose(in);
    fclose(out);  // ← This flushes and closes; make sure it

    printf("Lexical analysis completed. Output written to %s\n", argv[2]);

    return 0;
}
