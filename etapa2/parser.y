%{
#include <stdio.h>
#include <stdlib.h>

int yylex(void);
void yyerror(const char *s);
extern int yylineno;
%}

%define parse.error verbose
%token TK_TIPO
%token TK_VAR
%token TK_SENAO
%token TK_DECIMAL
%token TK_SE
%token TK_INTEIRO
%token TK_ATRIB
%token TK_RETORNA
%token TK_SETA
%token TK_ENQUANTO
%token TK_COM
%token TK_OC_LE
%token TK_OC_GE
%token TK_OC_EQ
%token TK_OC_NE
%token TK_ID
%token TK_LI_INTEIRO
%token TK_LI_DECIMAL
%token TK_ER

%%

programa: lista ';';
programa: %empty;


/********************** Definicao de lista */
lista: elemento_lista;
lista: lista ',' elemento_lista;
elemento_lista: declaracao_variavel_global;
elemento_lista: definicao_funcao;

/********************** Bloco de comandos */
bloco_comandos: '[' lista_comandos ']';
lista_comandos: %empty;
lista_comandos: elementos_lista_comandos;
elementos_lista_comandos: comando;
elementos_lista_comandos: comando elementos_lista_comandos;
comando: bloco_comandos;
comando: declaracao_variavel_global;
comando: declaracao_variavel_local;
comando: atribuicao_variavel;
comando: chamada_funcao;
comando: retorno_funcao;
comando: controle_fluxo_se;
comando: controle_fluxo_se_e_senao;
comando: controle_fluxo_repeticao;

/********************** Declaracao de variaveis globais*/
literal: TK_LI_DECIMAL;
literal: TK_LI_INTEIRO;
tipo: TK_INTEIRO;
tipo: TK_DECIMAL;
declaracao_variavel_global: TK_VAR TK_ID TK_ATRIB tipo;

/********************** Declaracao de variaveis locais*/
declaracao_variavel_local: TK_VAR TK_ID TK_ATRIB tipo TK_COM literal;

/********************** Atribuicao de variaveis */
atribuicao_variavel: TK_ID TK_ATRIB expressao;

/********************** Definicao de funcoes */
definicao_funcao: TK_ID TK_SETA tipo lista_parametros_opcional TK_ATRIB bloco_comandos;
lista_parametros_opcional: %empty;
lista_parametros_opcional: TK_COM lista_parametros;
lista_parametros: elemento_lista_parametros;
lista_parametros: elemento_lista_parametros ',' lista_parametros;
elemento_lista_parametros: TK_ID TK_ATRIB tipo;

/*********************** Chamada de funcao */
chamada_funcao: TK_ID '(' lista_argumentos_opcional ')';
lista_argumentos_opcional: %empty;
lista_argumentos_opcional: lista_argumentos;
lista_argumentos: expressao;
lista_argumentos: lista_argumentos ',' expressao;

/********************** Comandos de retorno de funcao */
retorno_funcao: TK_RETORNA expressao TK_ATRIB tipo;

/********************** Comandos de controle de fluxo */
controle_fluxo_se: TK_SE '(' expressao ')' bloco_comandos;
controle_fluxo_se_e_senao: TK_SE '(' expressao ')' bloco_comandos TK_SENAO bloco_comandos;
controle_fluxo_repeticao: TK_ENQUANTO '(' expressao ')' bloco_comandos;

/********************** Expressoes */
expressao: expressao_nv6;
expressao: expressao '|' expressao_nv6;

expressao_nv6: expressao_nv5;
expressao_nv6: expressao_nv6 '&' expressao_nv5;

expressao_nv5: expressao_nv4;
expressao_nv5: expressao_nv5 TK_OC_EQ expressao_nv4;
expressao_nv5: expressao_nv5 TK_OC_NE expressao_nv4;

expressao_nv4: expressao_nv3;
expressao_nv4: expressao_nv4 TK_OC_LE expressao_nv3;
expressao_nv4: expressao_nv4 TK_OC_GE expressao_nv3;
expressao_nv4: expressao_nv4 '>' expressao_nv3;
expressao_nv4: expressao_nv4 '<' expressao_nv3;

expressao_nv3: expressao_nv2;
expressao_nv3: expressao_nv3 '+' expressao_nv2;
expressao_nv3: expressao_nv3 '-' expressao_nv2;

expressao_nv2: expressao_nv1;
expressao_nv2: expressao_nv2 '%' expressao_nv1;
expressao_nv2: expressao_nv2 '/' expressao_nv1;
expressao_nv2: expressao_nv2 '*' expressao_nv1;

expressao_nv1: operando;
expressao_nv1: '+' operando;
expressao_nv1: '-' operando;
expressao_nv1: '!' operando;

operando: TK_ID;
operando: literal;
operando: chamada_funcao;
operando: '(' expressao ')';

%%

void yyerror(const char *s) {
    fprintf(stderr, "Erro sintático na linha %d: %s\n", yylineno, s);
}