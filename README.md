CS F363 Compiler Construction
Assignment (Phase 2) - Parser and Intermediate Code Generation
Project Group-ID: 2
Language Chosen: Lua

Team Member Details:
Shlok Gudadhe 2023A7PS0041H
Krishna Dhawan 2023A7PS0111H
Amay Deodhar 2023A7PS0155H
Jayditya Kabra 2023A7PS1059H
Pritish Saraf 2023A7PS1104H

# Lua Parser - Phase 2

Reference:
https://www.lua.org/manual/5.1/

This submission includes:
- `lexer.l` for lexical analysis
- `parser.y` for parsing and three-address code generation
- `valid.lua` as a valid input program
- `invalid.lua` as a syntax-error test program
- `lexical_invalid.lua` as an optional lexical-error test program

Run using the run.sh shell script provided.
Typical run flow:

```sh
yacc -d parser.y
lex lexer.l
gcc y.tab.c lex.yy.c -lfl -o lua_parser
./lua_parser < valid.lua > intermediate_code.txt
./lua_parser < invalid.lua
./lua_parser < lexical_invalid.lua
```

Grammar kept for Phase 2:
- variable declaration
- assignment statement
- arithmetic, relational, and logical expressions
- one conditional statement using `if ... then ... else ... end`
- one loop statement using `while ... do ... end`
