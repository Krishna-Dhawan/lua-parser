%{
    #include <stdio.h>
%}


%%

[a-zA-Z_][a-zA-Z0-9_]* { return; }
[0-9]+                 { return ; }
[ \t\n]                {  }
.                      { return ; }

%%

int main() {

    yylex();

    return 0;
}
