/*
Função principal para realização da análise sintática.
*/
#include <stdio.h>
#include "parser.tab.h" //arquivo gerado com bison -d parser.y
                        //inclua tal comando no teu workflow (Makefile)
extern int yylex_destroy(void);

int main (int argc, char **argv)
{
  int ret = yyparse();
  if (ret == 0) {
      printf("Análise sintática concluída com sucesso.\n");
  } else {
      printf("Falha na análise sintática.\n");
  }
  yylex_destroy();
  return ret;
}