lex lexer.l && yacc -d parser.y
gcc lex.yy.c y.tab.c -lfl -o lua_parser
echo "parsing valid.lua"
./lua_parser < valid.lua
echo "parsing invalid.lua"
./lua_parser < invalid.lua