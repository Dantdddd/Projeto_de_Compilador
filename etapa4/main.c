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
  asd_print_graphviz(arvore);
  asd_free(arvore);
  yylex_destroy();
  return ret;
}