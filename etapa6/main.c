/*
    Luis Franca
    Dante
*/

#include <stdio.h>
#include "asd.h"
#include "parser.tab.h"

extern int yyparse(void);
extern int yylex_destroy(void);

asd_tree_t *arvore = NULL;
TabelaSimbolos *tabela = NULL;

int main (int argc, char **argv)
{
  int ret = yyparse();

  if (ret == 0 && arvore != NULL) {
    ILOC_print_operations(arvore->code);

    ILOC_clean_operations(arvore->code);
  }

  asd_free(arvore);
  yylex_destroy();

  return ret;
}