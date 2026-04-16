%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>

extern int yylex();
extern int lineno;
void yyerror(const char *s);

typedef struct TacNode TacNode;

struct TacNode {
    char *code;
    char *place;
};

static int temp_counter = 0;
static int label_counter = 0;

static char *xstrdup(const char *s) {
    size_t len = strlen(s) + 1;
    char *copy = malloc(len);
    memcpy(copy, s, len);
    return copy;
}

static char *strf(const char *fmt, ...) {
    va_list args;
    va_list copy;
    va_start(args, fmt);
    va_copy(copy, args);
    int size = vsnprintf(NULL, 0, fmt, args);
    va_end(args);
    char *buf = malloc((size_t)size + 1);
    vsnprintf(buf, (size_t)size + 1, fmt, copy);
    va_end(copy);
    return buf;
}

static char *join2(const char *a, const char *b) {
    if (!a || !*a) return xstrdup(b ? b : "");
    if (!b || !*b) return xstrdup(a);
    return strf("%s%s", a, b);
}

static char *join3(const char *a, const char *b, const char *c) {
    char *tmp = join2(a, b);
    char *out = join2(tmp, c);
    free(tmp);
    return out;
}

static TacNode *make_node(const char *code, const char *place) {
    TacNode *node = malloc(sizeof(TacNode));
    node->code = xstrdup(code ? code : "");
    node->place = xstrdup(place ? place : "");
    return node;
}

static TacNode *empty_node(void) {
    return make_node("", "");
}

static char *new_temp(void) {
    return strf("t%d", temp_counter++);
}

static char *new_label(void) {
    return strf("L%d", label_counter++);
}

static TacNode *literal_node(const char *value) {
    return make_node("", value);
}

static TacNode *binary_expr(const char *op, TacNode *lhs, TacNode *rhs) {
    char *temp = new_temp();
    char *line = strf("%s = %s %s %s\n", temp, lhs->place, op, rhs->place);
    char *code = join3(lhs->code, rhs->code, line);
    TacNode *node = make_node(code, temp);
    free(line);
    free(code);
    free(temp);
    return node;
}

static TacNode *unary_expr(const char *op, TacNode *expr) {
    char *temp = new_temp();
    char *line = strf("%s = %s %s\n", temp, op, expr->place);
    char *code = join2(expr->code, line);
    TacNode *node = make_node(code, temp);
    free(line);
    free(code);
    free(temp);
    return node;
}

static TacNode *build_if(TacNode *cond, TacNode *then_block, TacNode *else_block) {
    char *false_label = new_label();
    char *end_label = new_label();
    char *branch = strf("ifFalse %s goto %s\n", cond->place, false_label);
    char *jump_end = strf("goto %s\n", end_label);
    char *false_mark = strf("%s:\n", false_label);
    char *end_mark = strf("%s:\n", end_label);
    char *code = join2(cond->code, branch);
    char *tmp = join2(code, then_block->code);
    free(code);
    code = tmp;
    if (else_block->code[0] != '\0') {
        tmp = join2(code, jump_end);
        free(code);
        code = tmp;
    }
    tmp = join2(code, false_mark);
    free(code);
    code = tmp;
    tmp = join2(code, else_block->code);
    free(code);
    code = tmp;
    if (else_block->code[0] != '\0') {
        tmp = join2(code, end_mark);
        free(code);
        code = tmp;
    }
    TacNode *node = make_node(code, "");
    free(branch);
    free(jump_end);
    free(false_mark);
    free(end_mark);
    free(code);
    free(false_label);
    free(end_label);
    return node;
}

static TacNode *build_while(TacNode *cond, TacNode *body) {
    char *start_label = new_label();
    char *end_label = new_label();
    char *start_mark = strf("%s:\n", start_label);
    char *branch = strf("ifFalse %s goto %s\n", cond->place, end_label);
    char *loop = strf("goto %s\n", start_label);
    char *end_mark = strf("%s:\n", end_label);
    char *code = join2(start_mark, cond->code);
    char *tmp = join2(code, branch);
    free(code);
    code = tmp;
    tmp = join2(code, body->code);
    free(code);
    code = tmp;
    tmp = join2(code, loop);
    free(code);
    code = tmp;
    tmp = join2(code, end_mark);
    free(code);
    code = tmp;
    TacNode *node = make_node(code, "");
    free(start_mark);
    free(branch);
    free(loop);
    free(end_mark);
    free(code);
    free(start_label);
    free(end_label);
    return node;
}
%}

%union {
    double dval;
    char *sval;
    TacNode *node;
}

%token <sval> IDENTIFIER STRING BOOLEAN
%token <dval> NUMBER

%token LOCAL FUNCTION IF ELSE ELSEIF THEN END WHILE DO FOR IN BREAK RETURN
%token AND OR NOT NIL

%token ASSIGN CONCAT DOT COLON COMMA SEMICOLON
%token LPAREN RPAREN LBRACE RBRACE LBRACKET RBRACKET
%token PLUS MINUS STAR SLASH EQ NEQ LEQ GEQ LT GT

%left OR
%left AND
%nonassoc EQ NEQ LT GT LEQ GEQ
%right CONCAT
%left PLUS MINUS
%left STAR SLASH
%right NOT
%right UMINUS

%type <node> program block statement_seq opt_last_statement statement last_statement
%type <node> declaration_stmt function_stmt function_body assign_stmt if_stmt if_tail
%type <node> while_stmt for_stmt opt_for_step in_expr_list in_expression function_name
%type <node> opt_param_list name_list assign_target_list prefix_expression call_stmt
%type <node> arguments opt_expr_list expr_list expression table_constructor
%type <node> opt_field_list field_list field

%start program

%%

program:
    block {
        if ($1->code[0] != '\0') {
            printf("%s", $1->code);
        }
        printf("Parsing finished successfully\n");
        $$ = $1;
    }
    ;

block:
    statement_seq opt_last_statement {
        char *code = join2($1->code, $2->code);
        $$ = make_node(code, "");
        free(code);
    }
    ;

statement_seq:
    /* empty */ { $$ = empty_node(); }
    | statement_seq statement opt_semicolon {
        char *code = join2($1->code, $2->code);
        $$ = make_node(code, "");
        free(code);
    }
    ;

opt_last_statement:
    /* empty */ { $$ = empty_node(); }
    | last_statement opt_semicolon { $$ = $1; }
    ;

opt_semicolon:
    /* empty */
    | SEMICOLON
    ;

statement:
    declaration_stmt { $$ = $1; }
    | assign_stmt { $$ = $1; }
    | if_stmt { $$ = $1; }
    | while_stmt { $$ = $1; }
    | for_stmt { $$ = $1; }
    | function_stmt { $$ = $1; }
    | call_stmt {
        char *code = join2($1->code, strf("call %s\n", $1->place));
        $$ = make_node(code, "");
        free(code);
    }
    ;

last_statement:
    BREAK { $$ = make_node("break\n", ""); }
    | RETURN { $$ = make_node("return\n", ""); }
    | RETURN expr_list {
        char *code = join2($2->code, strf("return %s\n", $2->place));
        $$ = make_node(code, "");
        free(code);
    }
    ;

declaration_stmt:
    LOCAL name_list { $$ = make_node(strf("local %s\n", $2->place), ""); }
    | LOCAL name_list ASSIGN expr_list {
        char *assign = strf("%s = %s\n", $2->place, $4->place);
        char *code = join2($4->code, assign);
        $$ = make_node(code, "");
        free(assign);
        free(code);
    }
    | LOCAL FUNCTION IDENTIFIER function_body {
        char *code = strf("# begin local function %s\n%s# end local function %s\n",
            $3, $4->code, $3);
        $$ = make_node(code, "");
        free(code);
    }
    ;

function_stmt:
    FUNCTION function_name function_body {
        char *code = strf("# begin function %s\n%s# end function %s\n",
            $2->place, $3->code, $2->place);
        $$ = make_node(code, "");
        free(code);
    }
    ;

function_body:
    LPAREN opt_param_list RPAREN block END { $$ = $4; }
    ;

assign_stmt:
    assign_target_list ASSIGN expr_list {
        char *assign = strf("%s = %s\n", $1->place, $3->place);
        char *code = join3($1->code, $3->code, assign);
        $$ = make_node(code, "");
        free(assign);
        free(code);
    }
    ;

if_stmt:
    IF expression THEN block if_tail END {
        $$ = build_if($2, $4, $5);
    }
    ;

if_tail:
    /* empty */ { $$ = empty_node(); }
    | ELSE block { $$ = $2; }
    | ELSEIF expression THEN block if_tail {
        $$ = build_if($2, $4, $5);
    }
    ;

while_stmt:
    WHILE expression DO block END {
        $$ = build_while($2, $4);
    }
    ;

for_stmt:
    FOR IDENTIFIER ASSIGN expression COMMA expression opt_for_step DO block END {
        char *step = ($7->place[0] != '\0') ? $7->place : "1";
        char *start_label = new_label();
        char *end_label = new_label();
        char *init = strf("%s = %s\n", $2, $4->place);
        char *start = strf("%s:\n", start_label);
        char *cond_temp = new_temp();
        char *cond = strf("%s = %s <= %s\n", cond_temp, $2, $6->place);
        char *branch = strf("ifFalse %s goto %s\n", cond_temp, end_label);
        char *inc = strf("%s = %s + %s\n", $2, $2, step);
        char *loop = strf("goto %s\n", start_label);
        char *end = strf("%s:\n", end_label);
        char *code = join3($4->code, $6->code, $7->code);
        char *tmp = join2(code, init);
        free(code);
        code = tmp;
        tmp = join2(code, start);
        free(code);
        code = tmp;
        tmp = join2(code, cond);
        free(code);
        code = tmp;
        tmp = join2(code, branch);
        free(code);
        code = tmp;
        tmp = join2(code, $9->code);
        free(code);
        code = tmp;
        tmp = join2(code, inc);
        free(code);
        code = tmp;
        tmp = join2(code, loop);
        free(code);
        code = tmp;
        tmp = join2(code, end);
        free(code);
        code = tmp;
        $$ = make_node(code, "");
        free(init);
        free(start);
        free(cond_temp);
        free(cond);
        free(branch);
        free(inc);
        free(loop);
        free(end);
        free(code);
        free(start_label);
        free(end_label);
    }
    | FOR name_list IN in_expr_list DO block END {
        char *body = strf("# generic for %s in %s\n%s# end generic for\n",
            $2->place, $4->place, $6->code);
        char *code = join2($4->code, body);
        $$ = make_node(code, "");
        free(body);
        free(code);
    }
    ;

opt_for_step:
    /* empty */ { $$ = literal_node(""); }
    | COMMA expression { $$ = $2; }
    ;

in_expr_list:
    in_expression { $$ = $1; }
    | in_expr_list COMMA in_expression {
        char *code = join2($1->code, $3->code);
        char *place = strf("%s, %s", $1->place, $3->place);
        $$ = make_node(code, place);
        free(code);
        free(place);
    }
    ;

in_expression:
    expression { $$ = $1; }
    | call_stmt { $$ = $1; }
    ;

function_name:
    IDENTIFIER { $$ = literal_node($1); }
    | function_name DOT IDENTIFIER {
        char *place = strf("%s.%s", $1->place, $3);
        $$ = make_node("", place);
        free(place);
    }
    | function_name COLON IDENTIFIER {
        char *place = strf("%s:%s", $1->place, $3);
        $$ = make_node("", place);
        free(place);
    }
    ;

opt_param_list:
    /* empty */ { $$ = empty_node(); }
    | name_list { $$ = $1; }
    ;

name_list:
    IDENTIFIER { $$ = literal_node($1); }
    | name_list COMMA IDENTIFIER {
        char *place = strf("%s, %s", $1->place, $3);
        $$ = make_node("", place);
        free(place);
    }
    ;

assign_target_list:
    prefix_expression { $$ = $1; }
    | assign_target_list COMMA prefix_expression {
        char *code = join2($1->code, $3->code);
        char *place = strf("%s, %s", $1->place, $3->place);
        $$ = make_node(code, place);
        free(code);
        free(place);
    }
    ;

prefix_expression:
    IDENTIFIER { $$ = literal_node($1); }
    | LPAREN expression RPAREN { $$ = $2; }
    | prefix_expression DOT IDENTIFIER {
        char *place = strf("%s.%s", $1->place, $3);
        $$ = make_node($1->code, place);
        free(place);
    }
    | prefix_expression LBRACKET expression RBRACKET {
        char *code = join2($1->code, $3->code);
        char *place = strf("%s[%s]", $1->place, $3->place);
        $$ = make_node(code, place);
        free(code);
        free(place);
    }
    ;

call_stmt:
    prefix_expression arguments {
        char *temp = new_temp();
        char *line = strf("%s = call %s(%s)\n", temp, $1->place, $2->place);
        char *code = join3($1->code, $2->code, line);
        $$ = make_node(code, temp);
        free(temp);
        free(line);
        free(code);
    }
    | prefix_expression COLON IDENTIFIER arguments {
        char *temp = new_temp();
        char *line = strf("%s = call %s:%s(%s)\n", temp, $1->place, $3, $4->place);
        char *code = join3($1->code, $4->code, line);
        $$ = make_node(code, temp);
        free(temp);
        free(line);
        free(code);
    }
    ;

arguments:
    LPAREN opt_expr_list RPAREN { $$ = $2; }
    ;

opt_expr_list:
    /* empty */ { $$ = empty_node(); }
    | expr_list { $$ = $1; }
    ;

expr_list:
    expression { $$ = $1; }
    | expr_list COMMA expression {
        char *code = join2($1->code, $3->code);
        char *place = strf("%s, %s", $1->place, $3->place);
        $$ = make_node(code, place);
        free(code);
        free(place);
    }
    ;

expression:
    NIL { $$ = literal_node("nil"); }
    | BOOLEAN { $$ = literal_node($1); }
    | NUMBER {
        char *num = strf("%.15g", $1);
        $$ = literal_node(num);
        free(num);
    }
    | STRING { $$ = literal_node($1); }
    | prefix_expression { $$ = $1; }
    | table_constructor { $$ = $1; }
    | FUNCTION function_body {
        char *temp = new_temp();
        char *code = strf("# function literal %s\n%s", temp, $2->code);
        $$ = make_node(code, temp);
        free(code);
        free(temp);
    }
    | NOT expression { $$ = unary_expr("not", $2); }
    | MINUS expression %prec UMINUS { $$ = unary_expr("-", $2); }
    | expression PLUS expression { $$ = binary_expr("+", $1, $3); }
    | expression MINUS expression { $$ = binary_expr("-", $1, $3); }
    | expression STAR expression { $$ = binary_expr("*", $1, $3); }
    | expression SLASH expression { $$ = binary_expr("/", $1, $3); }
    | expression CONCAT expression { $$ = binary_expr("..", $1, $3); }
    | expression EQ expression { $$ = binary_expr("==", $1, $3); }
    | expression NEQ expression { $$ = binary_expr("~=", $1, $3); }
    | expression LT expression { $$ = binary_expr("<", $1, $3); }
    | expression GT expression { $$ = binary_expr(">", $1, $3); }
    | expression LEQ expression { $$ = binary_expr("<=", $1, $3); }
    | expression GEQ expression { $$ = binary_expr(">=", $1, $3); }
    | expression AND expression { $$ = binary_expr("and", $1, $3); }
    | expression OR expression { $$ = binary_expr("or", $1, $3); }
    ;

table_constructor:
    LBRACE opt_field_list RBRACE {
        char *temp = new_temp();
        char *line = strf("%s = {%s}\n", temp, $2->place);
        char *code = join2($2->code, line);
        $$ = make_node(code, temp);
        free(line);
        free(code);
        free(temp);
    }
    ;

opt_field_list:
    /* empty */ { $$ = empty_node(); }
    | field_list { $$ = $1; }
    ;

field_list:
    field { $$ = $1; }
    | field_list field_sep field {
        char *code = join2($1->code, $3->code);
        char *place = strf("%s, %s", $1->place, $3->place);
        $$ = make_node(code, place);
        free(code);
        free(place);
    }
    | field_list field_sep { $$ = $1; }
    ;

field_sep:
    COMMA
    | SEMICOLON
    ;

field:
    IDENTIFIER ASSIGN expression {
        char *place = strf("%s = %s", $1, $3->place);
        $$ = make_node($3->code, place);
        free(place);
    }
    | LBRACKET expression RBRACKET ASSIGN expression {
        char *code = join2($2->code, $5->code);
        char *place = strf("[%s] = %s", $2->place, $5->place);
        $$ = make_node(code, place);
        free(code);
        free(place);
    }
    | expression { $$ = $1; }
    ;

%%

void yyerror(const char* s) {
    fprintf(stderr, "Syntax error at line %d: %s\n", lineno, s);
}

int main(void) {
    return yyparse();
}
