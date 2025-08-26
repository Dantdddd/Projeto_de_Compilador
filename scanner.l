%{
#include "tokens.h";
%}

%option yylineno

blank [ \t]+
digit [0-9]
integer {digit}+
decimal {integer}?"."{integer}
comment "//".*
identifier [a-z_][a-z_{digit}]*

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
{comment} { }
{blank} { }

"!" { return yytext[0]; }
"*" { return yytext[0]; }
"/" { return yytext[0]; }
"%" { return yytext[0]; }
"+" { return yytext[0]; }
"-" { return yytext[0]; }
"<" { return yytext[0]; }
">" { return yytext[0]; }
"[" { return yytext[0]; }
"]" { return yytext[0]; }
"(" { return yytext[0]; }
")" { return yytext[0]; }
"=" { return yytext[0]; }
"," { return yytext[0]; }
";" { return yytext[0]; }
"&" { return yytext[0]; }
"|" { return yytext[0]; }

. { return TK_ER; }

%%

int get_line_number() {
    return yylineno;
}