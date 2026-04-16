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

/* Build TAC for if and if-else statements. */
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
%token LOCAL IF ELSE THEN END WHILE DO
%token AND OR NOT NIL
%token ASSIGN
%token LPAREN RPAREN
%token PLUS MINUS STAR SLASH
%token EQ NEQ LEQ GEQ LT GT

%left OR
%left AND
%nonassoc EQ NEQ LT GT LEQ GEQ
%left PLUS MINUS
%left STAR SLASH
%right NOT
%right UMINUS

%type <node> program stmt_list stmt decl_stmt assign_stmt if_stmt else_part while_stmt expression

%start program

%%

/* Parse the input and print TAC if the whole program is valid. */
program:
    stmt_list {
        if (!lexical_error && $1->code[0] != '\0') {
            printf("%s", $1->code);
        }
        if (!lexical_error) {
            printf("Parsing finished successfully\n");
        }
    }
    ;

/* A program is a list of statements. */
stmt_list:
      /* empty */ { $$ = empty_node(); }
    | stmt_list stmt {
        char *code = join_text($1->code, $2->code);
        $$ = make_node(code, "");
        free(code);
      }
    ;

/* Only the Phase 2 constructs kept in the lab-style parser. */
stmt:
      decl_stmt { $$ = $1; }
    | assign_stmt { $$ = $1; }
    | if_stmt { $$ = $1; }
    | while_stmt { $$ = $1; }
    ;

/* Local declaration with initialization. */
decl_stmt:
    LOCAL IDENTIFIER ASSIGN expression {
        char *line = make_text("%s = %s\n", $2, $4->place);
        char *code = join_text($4->code, line);
        $$ = make_node(code, "");
        free(line);
        free(code);
    }
    ;

/* Plain assignment statement. */
assign_stmt:
    IDENTIFIER ASSIGN expression {
        char *line = make_text("%s = %s\n", $1, $3->place);
        char *code = join_text($3->code, line);
        $$ = make_node(code, "");
        free(line);
        free(code);
    }
    ;

/* If supports an optional else part. */
if_stmt:
    IF expression THEN stmt_list else_part END {
        $$ = if_node($2, $4, $5);
    }
    ;

/* Else block is optional. */
else_part:
      /* empty */ { $$ = empty_node(); }
    | ELSE stmt_list { $$ = $2; }
    ;

/* While loop with expression condition. */
while_stmt:
    WHILE expression DO stmt_list END {
        $$ = while_node($2, $4);
    }
    ;

/* Expression grammar with the operator precedence from Yacc rules. */
expression:
      IDENTIFIER { $$ = leaf_node($1); }
    | NUMBER {
        char *num = make_text("%.15g", $1);
        $$ = leaf_node(num);
        free(num);
      }
    | STRING { $$ = leaf_node($1); }
    | BOOLEAN { $$ = leaf_node($1); }
    | NIL { $$ = leaf_node("nil"); }
    | LPAREN expression RPAREN { $$ = $2; }
    | NOT expression { $$ = unary_node("not", $2); }
    | MINUS expression %prec UMINUS { $$ = unary_node("-", $2); }
    | expression PLUS expression { $$ = binary_node("+", $1, $3); }
    | expression MINUS expression { $$ = binary_node("-", $1, $3); }
    | expression STAR expression { $$ = binary_node("*", $1, $3); }
    | expression SLASH expression { $$ = binary_node("/", $1, $3); }
    | expression EQ expression { $$ = binary_node("==", $1, $3); }
    | expression NEQ expression { $$ = binary_node("~=", $1, $3); }
    | expression LT expression { $$ = binary_node("<", $1, $3); }
    | expression GT expression { $$ = binary_node(">", $1, $3); }
    | expression LEQ expression { $$ = binary_node("<=", $1, $3); }
    | expression GEQ expression { $$ = binary_node(">=", $1, $3); }
    | expression AND expression { $$ = binary_node("and", $1, $3); }
    | expression OR expression { $$ = binary_node("or", $1, $3); }
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
