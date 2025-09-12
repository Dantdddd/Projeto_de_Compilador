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

lista: elemento;
lista: lista ',' elemento;

elemento: bloco_comandos;
elemento: declaracao_variavel;
elemento: definicao_funcao;
declaracao_variavel: TK_INTEIRO;
definicao_funcao: TK_ID TK_SETA;
literal: TK_LI_INTEIRO ;

lista_comandos: comando;
lista_comandos: lista_comandos comando;
bloco_comandos: '[' lista_comandos ']';

comando_retorno: TK_RETORNA TK_ATRIB TK_DECIMAL;
comando_retorno: TK_RETORNA TK_ATRIB TK_INTEIRO;
comando: comando_retorno;

comando_atrib: TK_ID TK_ATRIB;  //adicionar expressao apos atrib
comando: comando_atrib;

comando_se: TK_SE bloco_comandos TK_SENAO bloco_comandos;
comando_se: TK_SE bloco_comandos;
comando: comando_se;

comando_enquanto: TK_ENQUANTO bloco_comandos;
comando: comando_enquanto;


%%

void yyerror(const char *s) {
    fprintf(stderr, "Erro sintático na linha %d: %s\n", yylineno, s);
}