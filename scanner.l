%{
#include "parser.tab.h"
%}

/* Ativa yylineno para realizar contagem de linhas */
%option yylineno

/* noyywrap, noinput e nounput evitam warnings na compilacao */
%option noyywrap
%option noinput nounput

/* Definicao de caracteres vazios */
blank [ \t]+    

/* Integers sao uma combinacao de digits (0-9) e decimals sao integers que incluem um "." que representa a virgula */
digit [0-9]
integer {digit}+
decimal {integer}?"."{integer}

/* Comments sao qualquer sequencia de caracteres que comecam com "//" e vao ate quebra de linha */
comment "//".*

/* Definicao de identifiers, que comecam com um caracter minusculo do alfabeto ou "_" e sao seguidos de outros caracteres minusculos, digitos ou underline */
identifier [a-z_][a-z0-9_]*

/* Definicoes para quebra de linha e caracteres especiais */
newline (\r?\n)
specialchars [!*\/%+\-<>\[\]\(\)=,;&|]

%%

"tipo" { return TK_TIPO; }
"var" { return TK_VAR; }
"senao" { return TK_SENAO; }
"decimal" { return TK_DECIMAL; }
"se" { return TK_SE; }
"inteiro" { return TK_INTEIRO; }
"retorna" { return TK_RETORNA; }
"enquanto" { return TK_ENQUANTO; }
"com" { return TK_COM; }

"<=" { return TK_OC_LE; }
">=" { return TK_OC_GE; }
"==" { return TK_OC_EQ; }
"!=" { return TK_OC_NE; }
":=" { return TK_ATRIB; }
"->" { return TK_SETA; }

{identifier} { return TK_ID; }
{decimal} { return TK_LI_DECIMAL; }
{integer} { return TK_LI_INTEIRO; }

{newline} { }
{specialchars} { return yytext[0]; }

{comment} { }
{blank} { }

. { return TK_ER; }

%%

/* Utiliza yylineno para retornar a contagem de linhas */
int get_line_number() {
    return yylineno;
}