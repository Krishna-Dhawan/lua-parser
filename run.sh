#!/bin/sh

yacc -d parser.y
flex lexer.l
gcc y.tab.c lex.yy.c -lfl -o lua_parser

echo "parsing valid.lua"
./lua_parser < valid.lua > intermediate_code.txt

echo "parsing invalid.lua"
./lua_parser < invalid.lua

echo "parsing lexical_invalid.lua"
./lua_parser < lexical_invalid.lua