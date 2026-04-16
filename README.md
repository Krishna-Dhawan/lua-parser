# Lua Parser - Phase 2

Reference:
https://www.lua.org/manual/5.1/

This submission includes:
- `lexer.l` for lexical analysis
- `parser.y` for parsing and three-address code generation
- `valid.lua` as a valid input program
- `invalid.lua` as a syntax-error test program
- `lexical_invalid.lua` as an optional lexical-error test program

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
- local declaration
- assignment statement
- arithmetic, relational, and logical expressions
- one conditional statement using `if ... then ... else ... end`
- one loop statement using `while ... do ... end`
