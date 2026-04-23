%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>

int yylex(void);
extern int lineno;
extern int lexical_error;
void yyerror(const char *s);

typedef struct Node {
    char *code;
    char *place;
} Node;

static int temp_count = 0;
static int label_count = 0;

/* Copy a string into new memory. */
static char *copy_text(const char *s) {
    size_t len = strlen(s) + 1;
    char *out = (char *)malloc(len);
    memcpy(out, s, len);
    return out;
}

/* Build formatted text used in TAC lines. */
static char *make_text(const char *fmt, ...) {
    va_list args;
    va_list args_copy;
    va_start(args, fmt);
    va_copy(args_copy, args);
    int size = vsnprintf(NULL, 0, fmt, args);
    va_end(args);
    char *buf = (char *)malloc((size_t)size + 1);
    vsnprintf(buf, (size_t)size + 1, fmt, args_copy);
    va_end(args_copy);
    return buf;
}

/* Join two code parts in order. */
static char *join_text(const char *a, const char *b) {
    if (!a || !*a) return copy_text(b ? b : "");
    if (!b || !*b) return copy_text(a);
    return make_text("%s%s", a, b);
}

/* Store generated code and its result place together. */
static Node *make_node(const char *code, const char *place) {
    Node *node = (Node *)malloc(sizeof(Node));
    node->code = copy_text(code ? code : "");
    node->place = copy_text(place ? place : "");
    return node;
}

/* Empty grammar rules still return a valid node. */
static Node *empty_node(void) {
    return make_node("", "");
}

/* Generate names like t0, t1 for temporaries. */
static char *new_temp(void) {
    return make_text("t%d", temp_count++);
}

/* Generate labels like L0, L1 for jumps. */
static char *new_label(void) {
    return make_text("L%d", label_count++);
}

/* Literals and identifiers only carry a place. */
static Node *leaf_node(const char *value) {
    return make_node("", value);
}

/* Generate TAC for binary expressions. */
static Node *binary_node(const char *op, Node *left, Node *right) {
    char *temp = new_temp();
    char *line = make_text("%s = %s %s %s\n", temp, left->place, op, right->place);
    char *tmp = join_text(left->code, right->code);
    char *code = join_text(tmp, line);
    Node *node = make_node(code, temp);
    free(temp);
    free(line);
    free(tmp);
    free(code);
    return node;
}

/* Generate TAC for unary expressions. */
static Node *unary_node(const char *op, Node *expr) {
    char *temp = new_temp();
    char *line = make_text("%s = %s %s\n", temp, op, expr->place);
    char *code = join_text(expr->code, line);
    Node *node = make_node(code, temp);
    free(temp);
    free(line);
    free(code);
    return node;
}

/* Build TAC for if / elseif / else chains. */
static Node *if_node(Node *cond, Node *then_part, Node *else_part) {
    char *false_label = new_label();
    char *end_label = new_label();
    char *branch = make_text("ifFalse %s goto %s\n", cond->place, false_label);
    char *false_mark = make_text("%s:\n", false_label);
    char *end_mark = make_text("%s:\n", end_label);
    char *jump_end = make_text("goto %s\n", end_label);

    char *code = join_text(cond->code, branch);
    char *tmp = join_text(code, then_part->code);
    free(code);
    code = tmp;

    if (else_part->code[0] != '\0') {
        tmp = join_text(code, jump_end);
        free(code);
        code = tmp;
    }

    tmp = join_text(code, false_mark);
    free(code);
    code = tmp;

    tmp = join_text(code, else_part->code);
    free(code);
    code = tmp;

    if (else_part->code[0] != '\0') {
        tmp = join_text(code, end_mark);
        free(code);
        code = tmp;
    }

    Node *node = make_node(code, "");
    free(false_label);
    free(end_label);
    free(branch);
    free(false_mark);
    free(end_mark);
    free(jump_end);
    free(code);
    return node;
}

/* Build TAC for while loops. */
static Node *while_node(Node *cond, Node *body) {
    char *start_label = new_label();
    char *end_label = new_label();
    char *start_mark = make_text("%s:\n", start_label);
    char *branch = make_text("ifFalse %s goto %s\n", cond->place, end_label);
    char *jump_back = make_text("goto %s\n", start_label);
    char *end_mark = make_text("%s:\n", end_label);

    char *code = join_text(start_mark, cond->code);
    char *tmp = join_text(code, branch);
    free(code);
    code = tmp;

    tmp = join_text(code, body->code);
    free(code);
    code = tmp;

    tmp = join_text(code, jump_back);
    free(code);
    code = tmp;

    tmp = join_text(code, end_mark);
    free(code);
    code = tmp;

    Node *node = make_node(code, "");
    free(start_label);
    free(end_label);
    free(start_mark);
    free(branch);
    free(jump_back);
    free(end_mark);
    free(code);
    return node;
}
%}

%union {
    double dval;
    char *sval;
    Node *node;
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

%type <node> program block statement_seq opt_last_statement
%type <node> statement last_statement
%type <node> declaration_stmt function_stmt function_body
%type <node> assign_stmt if_stmt else_if_list opt_else while_stmt
%type <node> for_stmt opt_for_step
%type <node> in_expr_list in_expression
%type <node> opt_param_list name_list
%type <node> assign_target_list prefix_expression
%type <node> call_stmt arguments opt_expr_list expr_list
%type <node> expression table_constructor opt_field_list field_list field
%type <sval> function_name

%start program

%%

/* Parse the input and print TAC if the whole program is valid. */
program:
    block {
        if (!lexical_error && $1->code[0] != '\0') {
            printf("%s", $1->code);
        }
        if (!lexical_error) {
            printf("Parsing finished successfully\n");
        }
    }
    ;

block:
    statement_seq opt_last_statement {
        char *code = join_text($1->code, $2->code);
        $$ = make_node(code, "");
        free(code);
    }
    ;

statement_seq:
    /* empty */ { $$ = empty_node(); }
    | statement_seq statement opt_semicolon {
        char *code = join_text($1->code, $2->code);
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
    | assign_stmt    { $$ = $1; }
    | if_stmt        { $$ = $1; }
    | while_stmt     { $$ = $1; }
    | for_stmt       { $$ = $1; }
    | function_stmt  { $$ = $1; }
    | call_stmt      { $$ = $1; }
    ;

last_statement:
    BREAK { $$ = make_node("break\n", ""); }
    | RETURN { $$ = make_node("return\n", ""); }
    | RETURN expr_list {
        char *line = make_text("return %s\n", $2->place);
        char *code = join_text($2->code, line);
        $$ = make_node(code, "");
        free(line);
        free(code);
    }
    ;

declaration_stmt:
    LOCAL name_list {
        $$ = $2;
    }
    | LOCAL name_list ASSIGN expr_list {
        char *line = make_text("%s = %s\n", $2->place, $4->place);
        char *code = join_text($4->code, line);
        $$ = make_node(code, "");
        free(line);
        free(code);
    }
    | LOCAL FUNCTION IDENTIFIER function_body {
        char *line = make_text("function %s\n", $3);
        char *code = join_text(line, $4->code);
        $$ = make_node(code, "");
        free(line);
    }
    ;

function_stmt:
    FUNCTION function_name function_body {
        char *line = make_text("function %s\n", $2);
        char *code = join_text(line, $3->code);
        $$ = make_node(code, "");
        free(line);
    }
    ;

function_body:
    LPAREN opt_param_list RPAREN block END {
        char *code = join_text($2->code, $4->code);
        char *end = join_text(code, "end_function\n");
        $$ = make_node(end, "");
        free(code);
        free(end);
    }
    ;

assign_stmt:
    assign_target_list ASSIGN expr_list {
        char *line = make_text("%s = %s\n", $1->place, $3->place);
        char *code = join_text($3->code, line);
        $$ = make_node(code, "");
        free(line);
        free(code);
    }
    ;

if_stmt:
    IF expression THEN block else_if_list opt_else END {
        /* Merge else_if_list and opt_else into a combined else part. */
        char *else_code = join_text($5->code, $6->code);
        Node *else_combined = make_node(else_code, "");
        free(else_code);
        $$ = if_node($2, $4, else_combined);
        free(else_combined->code);
        free(else_combined->place);
        free(else_combined);
    }
    ;

else_if_list:
    /* empty */ { $$ = empty_node(); }
    | else_if_list ELSEIF expression THEN block {
        /* Emit as: ifFalse <cond> goto next; <body> */
        char *false_label = new_label();
        char *branch = make_text("ifFalse %s goto %s\n", $3->place, false_label);
        char *false_mark = make_text("%s:\n", false_label);
        char *tmp1 = join_text($3->code, branch);
        char *tmp2 = join_text(tmp1, $5->code);
        char *tmp3 = join_text(tmp2, false_mark);
        char *combined = join_text($1->code, tmp3);
        $$ = make_node(combined, "");
        free(false_label);
        free(branch);
        free(false_mark);
        free(tmp1);
        free(tmp2);
        free(tmp3);
        free(combined);
    }
    ;

opt_else:
    /* empty */ { $$ = empty_node(); }
    | ELSE block { $$ = $2; }
    ;

while_stmt:
    WHILE expression DO block END {
        $$ = while_node($2, $4);
    }
    ;

for_stmt:
    FOR IDENTIFIER ASSIGN expression COMMA expression opt_for_step DO block END {
        char *start_label = new_label();
        char *end_label = new_label();
        char *init = make_text("%s = %s\n", $2, $4->place);
        char *start_mark = make_text("%s:\n", start_label);
        char *cond_temp = new_temp();
        char *cond_line = make_text("%s = %s <= %s\n", cond_temp, $2, $6->place);
        char *branch = make_text("ifFalse %s goto %s\n", cond_temp, end_label);
        char *step_code = $7->code[0] != '\0' ? $7->code : make_text("%s = %s + 1\n", $2, $2);
        char *jump = make_text("goto %s\n", start_label);
        char *end_mark = make_text("%s:\n", end_label);

        char *code = join_text($4->code, $6->code);
        char *tmp = join_text(code, init); free(code); code = tmp;
        tmp = join_text(code, start_mark); free(code); code = tmp;
        tmp = join_text(code, cond_line); free(code); code = tmp;
        tmp = join_text(code, branch); free(code); code = tmp;
        tmp = join_text(code, $9->code); free(code); code = tmp;
        tmp = join_text(code, step_code); free(code); code = tmp;
        tmp = join_text(code, jump); free(code); code = tmp;
        tmp = join_text(code, end_mark); free(code); code = tmp;

        $$ = make_node(code, "");
        free(start_label); free(end_label); free(init);
        free(start_mark); free(cond_temp); free(cond_line);
        free(branch); free(jump); free(end_mark); free(code);
        if ($7->code[0] == '\0') free(step_code);
    }
    | FOR name_list IN in_expr_list DO block END {
        char *line = make_text("for_in %s in %s\n", $2->place, $4->place);
        char *code = join_text($4->code, line);
        char *tmp = join_text(code, $6->code);
        $$ = make_node(tmp, "");
        free(line); free(code); free(tmp);
    }
    ;

opt_for_step:
    /* empty */ { $$ = empty_node(); }
    | COMMA expression {
        /* Caller uses the expression place as the step value. */
        $$ = $2;
    }
    ;

in_expr_list:
    in_expression { $$ = $1; }
    | in_expr_list COMMA in_expression {
        char *code = join_text($1->code, $3->code);
        char *place = make_text("%s, %s", $1->place, $3->place);
        $$ = make_node(code, place);
        free(code); free(place);
    }
    ;

in_expression:
    expression { $$ = $1; }
    | call_stmt { $$ = $1; }
    ;

function_name:
    IDENTIFIER { $$ = $1; }
    | function_name DOT IDENTIFIER {
        $$ = make_text("%s.%s", $1, $3);
        free($1);
    }
    | function_name COLON IDENTIFIER {
        $$ = make_text("%s:%s", $1, $3);
        free($1);
    }
    ;

opt_param_list:
    /* empty */ { $$ = empty_node(); }
    | name_list  { $$ = $1; }
    ;

name_list:
    IDENTIFIER { $$ = leaf_node($1); }
    | name_list COMMA IDENTIFIER {
        char *place = make_text("%s, %s", $1->place, $3);
        $$ = make_node($1->code, place);
        free(place);
    }
    ;

assign_target_list:
    prefix_expression { $$ = $1; }
    | assign_target_list COMMA prefix_expression {
        char *code = join_text($1->code, $3->code);
        char *place = make_text("%s, %s", $1->place, $3->place);
        $$ = make_node(code, place);
        free(code); free(place);
    }
    ;

prefix_expression:
    IDENTIFIER { $$ = leaf_node($1); }
    | LPAREN expression RPAREN { $$ = $2; }
    | prefix_expression DOT IDENTIFIER {
        char *place = make_text("%s.%s", $1->place, $3);
        $$ = make_node($1->code, place);
        free(place);
    }
    | prefix_expression LBRACKET expression RBRACKET {
        char *place = make_text("%s[%s]", $1->place, $3->place);
        char *code = join_text($1->code, $3->code);
        $$ = make_node(code, place);
        free(place); free(code);
    }
    ;

call_stmt:
    prefix_expression arguments {
        char *temp = new_temp();
        char *line = make_text("%s = call %s %s\n", temp, $1->place, $2->place);
        char *code = join_text($1->code, $2->code);
        char *full = join_text(code, line);
        $$ = make_node(full, temp);
        free(temp); free(line); free(code); free(full);
    }
    | prefix_expression COLON IDENTIFIER arguments {
        char *temp = new_temp();
        char *callee = make_text("%s:%s", $1->place, $3);
        char *line = make_text("%s = call %s %s\n", temp, callee, $4->place);
        char *code = join_text($1->code, $4->code);
        char *full = join_text(code, line);
        $$ = make_node(full, temp);
        free(temp); free(callee); free(line); free(code); free(full);
    }
    ;

arguments:
    LPAREN opt_expr_list RPAREN { $$ = $2; }
    ;

opt_expr_list:
    /* empty */ { $$ = empty_node(); }
    | expr_list  { $$ = $1; }
    ;

expr_list:
    expression { $$ = $1; }
    | expr_list COMMA expression {
        char *code = join_text($1->code, $3->code);
        char *place = make_text("%s, %s", $1->place, $3->place);
        $$ = make_node(code, place);
        free(code); free(place);
    }
    ;

expression:
    NIL                          { $$ = leaf_node("nil"); }
    | BOOLEAN                    { $$ = leaf_node($1); }
    | NUMBER {
        char *num = make_text("%.15g", $1);
        $$ = leaf_node(num);
        free(num);
    }
    | STRING                     { $$ = leaf_node($1); }
    | prefix_expression          { $$ = $1; }
    | table_constructor          { $$ = $1; }
    | FUNCTION function_body     { $$ = $2; }
    | NOT expression             { $$ = unary_node("not", $2); }
    | MINUS expression %prec UMINUS { $$ = unary_node("-", $2); }
    | expression PLUS expression   { $$ = binary_node("+",   $1, $3); }
    | expression MINUS expression  { $$ = binary_node("-",   $1, $3); }
    | expression STAR expression   { $$ = binary_node("*",   $1, $3); }
    | expression SLASH expression  { $$ = binary_node("/",   $1, $3); }
    | expression CONCAT expression { $$ = binary_node("..",  $1, $3); }
    | expression EQ expression     { $$ = binary_node("==",  $1, $3); }
    | expression NEQ expression    { $$ = binary_node("~=",  $1, $3); }
    | expression LT expression     { $$ = binary_node("<",   $1, $3); }
    | expression GT expression     { $$ = binary_node(">",   $1, $3); }
    | expression LEQ expression    { $$ = binary_node("<=",  $1, $3); }
    | expression GEQ expression    { $$ = binary_node(">=",  $1, $3); }
    | expression AND expression    { $$ = binary_node("and", $1, $3); }
    | expression OR expression     { $$ = binary_node("or",  $1, $3); }
    ;

table_constructor:
    LBRACE opt_field_list RBRACE {
        char *temp = new_temp();
        char *line = make_text("%s = {}\n", temp);
        char *code = join_text(line, $2->code);
        $$ = make_node(code, temp);
        free(temp); free(line); free(code);
    }
    ;

opt_field_list:
    /* empty */ { $$ = empty_node(); }
    | field_list { $$ = $1; }
    ;

field_list:
    field { $$ = $1; }
    | field_list field_sep field {
        char *code = join_text($1->code, $3->code);
        $$ = make_node(code, "");
        free(code);
    }
    | field_list field_sep {
        $$ = $1;
    }
    ;

field_sep:
    COMMA
    | SEMICOLON
    ;

field:
    IDENTIFIER ASSIGN expression {
        char *line = make_text("[%s] = %s\n", $1, $3->place);
        char *code = join_text($3->code, line);
        $$ = make_node(code, "");
        free(line); free(code);
    }
    | LBRACKET expression RBRACKET ASSIGN expression {
        char *line = make_text("[%s] = %s\n", $2->place, $5->place);
        char *code = join_text($2->code, $5->code);
        char *full = join_text(code, line);
        $$ = make_node(full, "");
        free(line); free(code); free(full);
    }
    | expression {
        $$ = $1;
    }
    ;

%%

void yyerror(const char *s) {
    if (!lexical_error) {
        fprintf(stderr, "Syntax error at line %d: %s\n", lineno, s);
    }
}

int main(void) {
    int result = yyparse();
    if (lexical_error) {
        fprintf(stderr, "Parser stopped due to lexical error.\n");
        return 1;
    }
    return result;
}