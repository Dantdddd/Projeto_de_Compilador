%code requires{
    #include "asd.h"
    #include <string.h>

    extern asd_tree_t *arvore;

    typedef enum {
        TK_TIPO_ID,
        TK_TIPO_LITERAL
    } TipoToken;

    typedef struct valor_lexico {
        int linha;
        TipoToken tipo;
        char* valor;  // sempre uma string duplicada com strdup()
    } valor_lexico_t;
}

%{
#include <stdio.h>
#include <stdlib.h>

int yylex(void);
void yyerror(const char *s);
extern int yylineno;
%}

%union{
    valor_lexico_t *valor_lexico;
    asd_tree_t *arvore;
}

%token <valor_lexico> TK_ID TK_LI_DECIMAL TK_LI_INTEIRO
%token TK_RETORNA TK_SE TK_SENAO TK_ENQUANTO

%type <arvore> comando controle_fluxo_se controle_fluxo_se_e_senao controle_fluxo_repeticao
%type <arvore> declaracao_variavel_local atribuicao_variavel chamada_funcao programa lista
%type <arvore> elemento_lista definicao_funcao bloco_comandos declaracao_variavel_global
%type <arvore> lista_comandos elementos_lista_comandos literal retorno_funcao expressao
%type <arvore> lista_argumentos_opcional
%type <arvore> expressao_nv6 expressao_nv5 expressao_nv4 expressao_nv3 expressao_nv2 expressao_nv1 operando
%type <arvore> lista_argumentos


%define parse.error verbose
%token TK_TIPO
%token TK_VAR
%token TK_DECIMAL
%token TK_INTEIRO
%token TK_ATRIB
%token TK_SETA
%token TK_COM
%token TK_OC_LE
%token TK_OC_GE
%token TK_OC_EQ
%token TK_OC_NE
%token TK_ER

%%

programa: lista ';' {
    arvore = $1;
    $$ = $1;
};

programa: %empty {
    arvore = NULL;
    $$ = NULL;
};

/********************** Definicao de lista */
lista: elemento_lista ',' lista {
    if ($1 && $3) {
        asd_add_child($1, $3);
        $$ = $1;
    }
    else if ($1) {
        $$ = $1;
    }
    else {
        $$ = $3;
    }
};
lista: elemento_lista {
    if ($1){
        $$ = $1;
    }
};

elemento_lista: declaracao_variavel_global { $$ = $1; };
elemento_lista: definicao_funcao { $$ = $1; };

/********************** Bloco de comandos */
bloco_comandos: '[' lista_comandos ']' { $$ = $2; };

lista_comandos: %empty { $$ = NULL; };
lista_comandos: elementos_lista_comandos { $$ = $1; };

elementos_lista_comandos: comando { $$ = $1; };
elementos_lista_comandos: comando elementos_lista_comandos {
    if ($1 && $2) {
        asd_add_child($1, $2);
        $$ = $1;
    }
    else if ($1) {
        $$ = $1;
    }
    else if ($2) {
        $$ = $2;
    }
};

comando: bloco_comandos { $$ = $1; };
comando: declaracao_variavel_global { $$ = $1; };
comando: declaracao_variavel_local { $$ = $1; };
comando: atribuicao_variavel { $$ = $1; };
comando: chamada_funcao { $$ = $1; };
comando: controle_fluxo_se { $$ = $1; };
comando: controle_fluxo_se_e_senao { $$ = $1; };
comando: controle_fluxo_repeticao { $$ = $1; };
comando: retorno_funcao { $$ = $1; };

/********************** Declaracao de variaveis globais*/
literal: TK_LI_DECIMAL {
    $$ = asd_new($1->valor);

    free($1->valor);
    free($1);
};

literal: TK_LI_INTEIRO{
    $$ = asd_new($1->valor);

    free($1->valor);
    free($1);
};

tipo: TK_INTEIRO;
tipo: TK_DECIMAL;

declaracao_variavel_global: TK_VAR TK_ID TK_ATRIB tipo {
    $$ = NULL;

    free($2->valor);
    free($2);
};

/********************** Declaracao de variaveis locais*/
declaracao_variavel_local: TK_VAR TK_ID TK_ATRIB tipo TK_COM literal{
    $$ = asd_new("com");
    asd_tree_t* buffer = asd_new($2->valor);
    asd_add_child($$, buffer);
    asd_add_child($$, $6);

    free($2->valor);
    free($2);
};

/********************** Atribuicao de variaveis */
atribuicao_variavel: TK_ID TK_ATRIB expressao {
    $$ = asd_new(":=");
    asd_tree_t* buffer = asd_new($1->valor);
    asd_add_child($$, buffer);
    if ($3){
        asd_add_child($$, $3);
    }

    free($1->valor);
    free($1);
};

/********************** Definicao de funcoes */
definicao_funcao: TK_ID TK_SETA tipo lista_parametros_opcional TK_ATRIB bloco_comandos {
    $$ = asd_new($1->valor);
    if ($6){
        asd_add_child($$, $6);
    }

    free($1->valor);
    free($1);
};

lista_parametros_opcional: %empty;
lista_parametros_opcional: TK_COM lista_parametros;
lista_parametros_opcional: lista_parametros;

lista_parametros: elemento_lista_parametros;
lista_parametros: lista_parametros ',' elemento_lista_parametros;

elemento_lista_parametros: TK_ID TK_ATRIB tipo {
    free($1->valor);
    free($1);
};

chamada_funcao: TK_ID '(' lista_argumentos_opcional ')' {
    char label[64];

    sprintf(label, "call %s", $1->valor);

    $$ = asd_new(label);

    if ($3 != NULL){
        asd_add_child($$, $3);
    }

    // 5. Liberar a memória do token, na ordem correta
    free($1->valor);
    free($1);
};

lista_argumentos_opcional: %empty {$$ = NULL;};
lista_argumentos_opcional: lista_argumentos { $$ = $1; };

lista_argumentos: expressao { $$ = $1; };
lista_argumentos: expressao ',' lista_argumentos {
    if ($1 && $3){
        asd_add_child($1, $3);
        $$ = $1;
    }
    else if ($3) {
        $$ = $3;
    }
    else if ($1) {
        $$ = $1;
    }
};

/********************** Comandos de retorno de funcao */
retorno_funcao: TK_RETORNA expressao TK_ATRIB tipo {
    $$ = asd_new("retorna");
    asd_add_child($$, $2);
};

/********************** Comandos de controle de fluxo */
controle_fluxo_se_e_senao: TK_SE '(' expressao ')' bloco_comandos TK_SENAO bloco_comandos {
    $$ = asd_new("se");
    asd_add_child($$, $3);
    if ($5){
        asd_add_child($$, $5);
    }
    if ($7){
        asd_add_child($$, $7);
    }
};

controle_fluxo_se: TK_SE '(' expressao ')' bloco_comandos {
    $$ = asd_new("se");
    asd_add_child($$, $3);
    if ($5){
        asd_add_child($$, $5);
    }
};

controle_fluxo_repeticao: TK_ENQUANTO '(' expressao ')' bloco_comandos {
    $$ = asd_new("enquanto");
    asd_add_child($$, $3);
    if ($5){
        asd_add_child($$, $5);
    }
};

/********************** Expressoes */
expressao: expressao_nv6 { $$ = $1; };
expressao: expressao '|' expressao_nv6 {
    $$ = asd_new("|");
    asd_add_child($$, $1);
    asd_add_child($$, $3);
};

expressao_nv6: expressao_nv5 { $$ = $1; };
expressao_nv6: expressao_nv6 '&' expressao_nv5{
    $$ = asd_new("&");
    asd_add_child($$, $1);
    asd_add_child($$, $3);
};

expressao_nv5: expressao_nv4 { $$ = $1; };
expressao_nv5: expressao_nv5 TK_OC_EQ expressao_nv4{
    $$ = asd_new("==");
    asd_add_child($$, $1);
    asd_add_child($$, $3);
};
expressao_nv5: expressao_nv5 TK_OC_NE expressao_nv4{
    $$ = asd_new("!=");
    asd_add_child($$, $1);
    asd_add_child($$, $3);
};

expressao_nv4: expressao_nv3 { $$ = $1; };
expressao_nv4: expressao_nv4 TK_OC_LE expressao_nv3{
    $$ = asd_new("<=");
    asd_add_child($$, $1);
    asd_add_child($$, $3);
};
expressao_nv4: expressao_nv4 TK_OC_GE expressao_nv3{
    $$ = asd_new(">=");
    asd_add_child($$, $1);
    asd_add_child($$, $3);
};
expressao_nv4: expressao_nv4 '>' expressao_nv3{
    $$ = asd_new(">");
    asd_add_child($$, $1);
    asd_add_child($$, $3);
};
expressao_nv4: expressao_nv4 '<' expressao_nv3{
    $$ = asd_new("<");
    asd_add_child($$, $1);
    asd_add_child($$, $3);
};

expressao_nv3: expressao_nv2 { $$ = $1; };
expressao_nv3: expressao_nv3 '+' expressao_nv2{
    $$ = asd_new("+");
    asd_add_child($$, $1);
    asd_add_child($$, $3);
};
expressao_nv3: expressao_nv3 '-' expressao_nv2{
    $$ = asd_new("-");
    asd_add_child($$, $1);
    asd_add_child($$, $3);
};

expressao_nv2: expressao_nv1 { $$ = $1; };
expressao_nv2: expressao_nv2 '%' expressao_nv1{
    $$ = asd_new("%");
    asd_add_child($$, $1);
    asd_add_child($$, $3);
};
expressao_nv2: expressao_nv2 '/' expressao_nv1{
    $$ = asd_new("/");
    asd_add_child($$, $1);
    asd_add_child($$, $3);
};
expressao_nv2: expressao_nv2 '*' expressao_nv1{
    $$ = asd_new("*");
    asd_add_child($$, $1);
    asd_add_child($$, $3);
};

expressao_nv1: operando { $$ = $1; };
expressao_nv1: '+' operando{
    $$ = asd_new("+");
    asd_add_child($$, $2);
};
expressao_nv1: '-' operando{
    $$ = asd_new("-");
    asd_add_child($$, $2);
};
expressao_nv1: '!' operando{
    $$ = asd_new("!");
    asd_add_child($$, $2);
};

/********** Expressoes Nv 0 */
operando: TK_ID {
    $$ = asd_new($1->valor);

    free($1->valor);
    free($1);
};
operando: literal { $$ = $1; };
operando: chamada_funcao { $$ = $1; };
operando: '(' expressao ')' { $$ = $2; };

%%

void yyerror(const char *s) {
    fprintf(stderr, "Erro sintático na linha %d: %s\n", yylineno, s);
}