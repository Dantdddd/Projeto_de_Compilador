/*
    * Luis Franca
    * Dante
*/

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "asd.h"

int yylex(void);
void yyerror(const char *s);
extern int yylineno;

// Contadores globais para endereçamento de memória
int global_offset = 0;
int local_offset = 0;
%}

%code requires{
    #include "asd.h"
    #include <string.h>

    #define LITERAL 0
    #define IDENTIFICADOR 1
    #define FUNCAO 2
    #define TIPO_INT 3
    #define TIPO_FLOAT 4

    #define ERR_UNDECLARED      10 //2.2
    #define ERR_DECLARED        11 //2.2
    #define ERR_VARIABLE        20 //2.3
    #define ERR_FUNCTION        21 //2.3
    #define ERR_WRONG_TYPE      30 //2.4
    #define ERR_MISSING_ARGS    40 //2.5
    #define ERR_EXCESS_ARGS     41 //2.5
    #define ERR_WRONG_TYPE_ARGS 42 //2.5

    extern asd_tree_t *arvore;

    typedef enum {
        TK_TIPO_ID,
        TK_TIPO_LITERAL
    } TipoToken;

    typedef union {
        int DadoInt;
        float DadoFloat;
    } Dado;

    typedef struct valor_lexico {
        int linha;
        TipoToken tipo;
        char* valor;
    } valor_lexico_t;

    typedef struct Parametro {
        int tipo;
        Dado dado;
        struct Parametro *prox;
    } Parametro;

    typedef struct Simbolo {
        char *chave;
        int natureza;
        int tipo;
        Parametro *parametros;

        int mem_offset;
        int is_global;

        Dado dado;
        struct Simbolo *prox;
    } Simbolo;

    typedef struct TabelaSimbolos {
        Simbolo *primeiro;
        struct TabelaSimbolos *anterior;
    } TabelaSimbolos;

    extern TabelaSimbolos *tabela;

    TabelaSimbolos *tabela_criar(TabelaSimbolos *anterior);
    Simbolo *tabela_buscar(TabelaSimbolos *tabela, const char *nome);

    Simbolo *tabela_inserir_funcao(TabelaSimbolos *tabela, char *chave, int natureza, int tipo, Parametro *params, Dado dado);

    TabelaSimbolos *tabela_destruir(TabelaSimbolos *tabela);

    void tabela_imprimir(TabelaSimbolos *tabela);
    void simbolos_destruir(Simbolo *simbolo);
    Parametro *parametro_criar(int tipo, Dado dado);

    void parametros_destruir(Parametro *p);
}

%union{
    valor_lexico_t *valor_lexico;
    asd_tree_t *arvore;
    Parametro *parametro;
    int TipoSimbolo;
}

%token <valor_lexico> TK_ID TK_LI_DECIMAL TK_LI_INTEIRO
%token TK_RETORNA TK_SE TK_SENAO TK_ENQUANTO
%token TK_TIPO TK_VAR TK_DECIMAL TK_INTEIRO TK_ATRIB TK_SETA TK_COM
%token TK_OC_LE TK_OC_GE TK_OC_EQ TK_OC_NE TK_ER

%type <arvore> comando controle_fluxo_se controle_fluxo_se_e_senao controle_fluxo_repeticao
%type <arvore> declaracao_variavel_local atribuicao_variavel chamada_funcao programa lista
%type <arvore> declaracao_variavel_local_simples
%type <arvore> elemento_lista definicao_funcao bloco_comandos declaracao_variavel_global
%type <arvore> lista_comandos elementos_lista_comandos literal retorno_funcao expressao
%type <arvore> lista_argumentos_opcional
%type <arvore> expressao_nv6 expressao_nv5 expressao_nv4 expressao_nv3 expressao_nv2 expressao_nv1 operando
%type <arvore> lista_argumentos

%type <parametro> lista_parametros_opcional lista_parametros elemento_lista_parametros
%type <TipoSimbolo> tipo

%define parse.error verbose

%%

programa: escopo_ini lista escopo_fim ';' {
    arvore = $2;
    $$ = $2;
};

programa: %empty {
    arvore = NULL;
    $$ = NULL;
};

escopo_ini: %empty {
    tabela = tabela_criar(tabela);
}

escopo_fim: %empty {
    tabela = tabela_destruir(tabela);
}

/********************** Definicao de lista */
lista: elemento_lista ',' lista {
    if ($1 && $3) {
        asd_add_child($1, $3);

        if ($1->code)
        {
            $1->code = ILOC_concat_operations($1->code, $3->code);
        }
        else
        {
            $1->code = $3->code;
        }

        $$ = $1;
    }
    else if ($1)
    {
        $$ = $1;
    }
    else
    {
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
bloco_comandos: '[' escopo_ini lista_comandos escopo_fim ']' { $$ = $3; };

lista_comandos: %empty { $$ = NULL; }
    | elementos_lista_comandos { $$ = $1; };

elementos_lista_comandos: comando { $$ = $1; }
    | comando elementos_lista_comandos {
    if ($1 && $2) {
        asd_add_child($1, $2);
        $1->code = ILOC_concat_operations($1->code, $2->code);
        $$ = $1;
    }
    else if ($1) {
        $$ = $1;
    }
    else if ($2) {
        $$ = $2;
    }
};

comando:
      bloco_comandos
    | declaracao_variavel_local_simples
    | declaracao_variavel_local
    | atribuicao_variavel
    | chamada_funcao
    | controle_fluxo_se
    | controle_fluxo_se_e_senao
    | controle_fluxo_repeticao
    | retorno_funcao ;

/********************** Declaracao de variaveis globais*/
literal: TK_LI_DECIMAL {
    $$ = asd_new($1->valor);
    $$->is_int = 0;

    char temp[32];
    ILOC_new_temp(temp);
    $$->temp = strdup(temp);

    $$->code = ILOC_new_operation(LOADI, $1->valor, NULL, temp, NULL);

    free($1->valor);
    free($1);
};

literal: TK_LI_INTEIRO{
    char temp[32];

    $$ = asd_new($1->valor);
    $$->is_int = 1;

    ILOC_new_temp(temp);
    $$->temp = strdup(temp);

    // Gera instrução: loadI valor => temp
    $$->code = ILOC_new_operation(LOADI, $1->valor, NULL, temp, NULL);

    free($1->valor);
    free($1);
};

tipo: TK_INTEIRO { $$ = TIPO_INT; };
tipo: TK_DECIMAL { $$ = TIPO_FLOAT; };

declaracao_variavel_global: TK_VAR TK_ID TK_ATRIB tipo {
    Dado d;
    Simbolo *s;

    if (tabela_buscar(tabela, $2->valor) != NULL)
    {
        fprintf(stderr, "Erro linha %d: variável '%s' já declarada\n", yylineno, $2->valor);
        exit(ERR_DECLARED);
    }

    s = tabela_inserir_funcao(tabela, $2->valor, IDENTIFICADOR, $4, NULL, d);

    s->is_global = 1;
    s->mem_offset = global_offset;
    global_offset += 4;

    free($2->valor);
    free($2);
    $$ = NULL;
};


/********************** Declaracao de variaveis locais*/
/* Nova regra para variavel dentro de funcao */
declaracao_variavel_local_simples: TK_VAR TK_ID TK_ATRIB tipo {
    Dado d;
    Simbolo *s;

    if (tabela_buscar(tabela, $2->valor) != NULL) {
        fprintf(stderr, "Erro linha %d: variável '%s' já declarada\n", yylineno, $2->valor);
        exit(ERR_DECLARED);
    }

    s = tabela_inserir_funcao(tabela, $2->valor, IDENTIFICADOR, $4, NULL, d);

    s->is_global = 0;
    s->mem_offset = local_offset;
    local_offset += 4;

    $$ = NULL;

    free($2->valor);
    free($2);
};

declaracao_variavel_local: TK_VAR TK_ID TK_ATRIB tipo TK_OC_LE literal {
    Dado d;
    Simbolo* s;
    char offset_str[16];
    ILOC_operation_t *store;

    if (tabela_buscar(tabela, $2->valor) != NULL)
    {
        fprintf(stderr, "Erro linha %d: variável '%s' já declarada\n", yylineno, $2->valor);
        exit(ERR_DECLARED);
    }

    int var_is_int = ($4 == TIPO_INT);
    if (var_is_int != $6->is_int)
    {
        fprintf(stderr, "Erro linha %d: Tipo do literal (is_int=%d) incompatível com a declaração de '%s' (is_int=%d).\n",
                yylineno, $6->is_int, $2->valor, var_is_int);
        exit(ERR_WRONG_TYPE);
    }

    s = tabela_inserir_funcao(tabela, $2->valor, IDENTIFICADOR, $4, NULL, d);

    // Configura endereço local
    s->is_global = 0;
    s->mem_offset = local_offset;
    local_offset += 4;

    $$ = asd_new("com");
    $$->is_int = var_is_int;

    sprintf(offset_str, "%d", s->mem_offset);

    store = ILOC_new_operation(STOREAI, $6->temp, "(%rbp)", offset_str, NULL);

    $$->code = ILOC_concat_operations($6->code, store);

    asd_add_child($$, asd_new($2->valor));
    asd_add_child($$, $6);

    free($2->valor);
    free($2);
};


/********************** Atribuicao de variaveis */
atribuicao_variavel: TK_ID TK_ATRIB expressao {
    int var_is_int;
    char offset_str[16];
    char* base_reg;
    ILOC_operation_t *store;
    Simbolo *s = tabela_buscar(tabela, $1->valor);

    if (s == NULL)
    {
        fprintf(stderr, "Erro linha %d: identificador '%s' não declarado\n", yylineno, $1->valor);
        exit(ERR_UNDECLARED);
    }

    if (s->natureza != IDENTIFICADOR)
    {
        fprintf(stderr, "Erro linha %d: '%s' não é uma variável\n", yylineno, $1->valor);
        exit(ERR_VARIABLE);
    }

    var_is_int = (s->tipo == TIPO_INT);
    if (var_is_int != $3->is_int)
    {
        fprintf(stderr, "Erro linha %d: Tipos incompatíveis na atribuição para '%s'. Esperado (is_int=%d), recebido (is_int=%d).\n",
            yylineno, $1->valor, var_is_int, $3->is_int);
        exit(ERR_WRONG_TYPE);
    }

    $$ = asd_new(":=");
    $$->is_int = var_is_int;

    base_reg = s->is_global ? "rbss" : "rfp";
    sprintf(offset_str, "%d", s->mem_offset);

    store = ILOC_new_operation(STOREAI, $3->temp, base_reg, offset_str, NULL);

    $$->code = ILOC_concat_operations($3->code, store);

    asd_add_child($$, asd_new($1->valor));
    if ($3) asd_add_child($$, $3);

    free($1->valor);
    free($1);
};


/********************** Definicao de funcoes */
definicao_funcao: TK_ID TK_SETA tipo
    { local_offset = 0; }
    lista_parametros_opcional TK_ATRIB
    {
        Dado dado;
        if (tabela_buscar(tabela, $1->valor) != NULL) {
            fprintf(stderr, "Erro linha %d: função '%s' já declarada\n", yylineno, $1->valor);
            exit(ERR_DECLARED);
        }

        tabela_inserir_funcao(tabela, $1->valor, FUNCAO, $3, $5, dado);
    }
    bloco_comandos
    {
        ILOC_operation_t *label_op;

        $$ = asd_new($1->valor);
        $$->is_int = ($3 == TIPO_INT);

        // Rótulo da função no início do código
        label_op = ILOC_new_operation(NOP, NULL, NULL, NULL, $1->valor);

        if ($8)
        {
            $$->code = ILOC_concat_operations(label_op, $8->code);
            asd_add_child($$, $8);
        }
        else
        {
            $$->code = label_op;
        }

        free($1->valor);
        free($1);
    };

lista_parametros_opcional: %empty { $$ = NULL; };
lista_parametros_opcional: TK_COM lista_parametros { $$ = $2; };
lista_parametros_opcional: lista_parametros { $$ = $1; };

lista_parametros: elemento_lista_parametros { $$ = $1; };
lista_parametros: lista_parametros ',' elemento_lista_parametros {
    Parametro *ultimo = $1;

    while (ultimo->prox != NULL)
    {
        ultimo = ultimo->prox;
    }

    ultimo->prox = $3;
    $$ = $1;
};

elemento_lista_parametros: TK_ID TK_ATRIB tipo {
    Dado dado;
    Simbolo *s;

    $$ = parametro_criar($3, dado);

    s = tabela_inserir_funcao(tabela, $1->valor, IDENTIFICADOR, $3, NULL, dado);
    s->is_global = 0;
    s->mem_offset = local_offset;
    local_offset += 4;

    free($1->valor);
    free($1);
};

chamada_funcao: TK_ID '(' lista_argumentos_opcional ')' {
    Simbolo *s = tabela_buscar(tabela, $1->valor);
    Parametro *param_esperado;
    asd_tree_t *arg_list_node;
    int arg_count;

    if (s == NULL) {
        fprintf(stderr, "Erro linha %d: função '%s' não declarada\n", yylineno, $1->valor);
        exit(ERR_UNDECLARED);
    }
    if (s->natureza != FUNCAO) {
        fprintf(stderr, "Erro linha %d: '%s' não é uma função\n", yylineno, $1->valor);
        exit(ERR_VARIABLE);
    }

    param_esperado = s->parametros;
    arg_list_node = $3;
    arg_count = 0;

    while (param_esperado != NULL || arg_list_node != NULL) {
        arg_count++;
        int param_is_int;
        int arg_is_int;
        asd_tree_t *current_arg_expr;

        if (param_esperado != NULL && arg_list_node == NULL)
        {
            fprintf(stderr, "Erro linha %d: Faltam argumentos para a chamada de '%s'.\n", yylineno, $1->valor);
            exit(ERR_MISSING_ARGS);
        }
        if (param_esperado == NULL && arg_list_node != NULL)
        {
            fprintf(stderr, "Erro linha %d: Excesso de argumentos para a chamada de '%s'.\n", yylineno, $1->valor);
            exit(ERR_EXCESS_ARGS);
        }

        current_arg_expr = arg_list_node;
        param_is_int = (param_esperado->tipo == TIPO_INT);
        arg_is_int = current_arg_expr->is_int;

        if (param_is_int != arg_is_int)
        {
            fprintf(stderr, "Erro linha %d: Tipo incorreto para argumento %d na chamada de '%s'. Esperado (is_int=%d), recebido (is_int=%d).\n",
                    yylineno, arg_count, $1->valor, param_is_int, arg_is_int);
            exit(ERR_WRONG_TYPE_ARGS);
        }

        param_esperado = param_esperado->prox;
        if (current_arg_expr->number_of_children > 0)
        {
            arg_list_node = current_arg_expr->children[0];
        }
        else
        {
            arg_list_node = NULL;
        }
    }

    char label[64];
    sprintf(label, "call %s", $1->valor);
    $$ = asd_new(label);
    $$->is_int = (s->tipo == TIPO_INT);

    char temp[32];
    ILOC_new_temp(temp);
    $$->temp = strdup(temp);

    // Jump para chamada de função
    ILOC_operation_t *call = ILOC_new_operation(JUMPI, NULL, NULL, $1->valor, NULL);

    if ($3) {
        $$->code = ILOC_concat_operations($3->code, call);
        asd_add_child($$, $3);
    } else {
        $$->code = call;
    }

    free($1->valor);
    free($1);
};

lista_argumentos_opcional: %empty {$$ = NULL;}
    | lista_argumentos { $$ = $1; };

lista_argumentos: expressao { $$ = $1; }
    | expressao ',' lista_argumentos {
        if ($1 && $3) {
            asd_add_child($1, $3);
            $1->code = ILOC_concat_operations($1->code, $3->code);
            $$ = $1;
        }
        else if ($3) { $$ = $3; }
        else if ($1) { $$ = $1; }
    };

/********************** Comandos de retorno de funcao */
retorno_funcao: TK_RETORNA expressao TK_ATRIB tipo {
    int declared_is_int = ($4 == TIPO_INT);

    if (declared_is_int != $2->is_int) {
        fprintf(stderr, "Erro linha %d: Tipo da expressão (is_int=%d) incompatível com o tipo de retorno declarado (is_int=%d).\n",
                yylineno, $2->is_int, declared_is_int);
        exit(ERR_WRONG_TYPE);
    }

    $$ = asd_new("retorna");
    $$->is_int = $2->is_int;
    $$->code = $2->code;

    asd_add_child($$, $2);
};

/********************** Comandos de controle de fluxo */
controle_fluxo_se_e_senao: TK_SE '(' expressao ')' bloco_comandos TK_SENAO bloco_comandos {
    // Verificações de tipo... (mantidas iguais)
    if ($5 && $5->is_int != $7->is_int)
    {
        if ($5->is_int != $7->is_int)
        {
            fprintf(stderr, "Erro linha %d: Tipos dos blocos IF e ELSE incompatíveis.\n", yylineno);
            exit(ERR_WRONG_TYPE);
        }
    }

    $$ = asd_new("se");
    $$->is_int = $3->is_int;

    char label_true [32];
    char label_false [32];
    char label_end [32];

    ILOC_new_label(label_true);
    ILOC_new_label(label_false);
    ILOC_new_label(label_end);

    ILOC_operation_t *cbr = ILOC_new_operation(CBR, $3->temp, label_true, label_false, NULL);
    ILOC_operation_t *lbl_true = ILOC_new_operation(NOP, NULL, NULL, NULL, label_true);
    ILOC_operation_t *lbl_false = ILOC_new_operation(NOP, NULL, NULL, NULL, label_false);
    ILOC_operation_t *lbl_end = ILOC_new_operation(NOP, NULL, NULL, NULL, label_end);
    ILOC_operation_t *jump_end = ILOC_new_operation(JUMPI, NULL, NULL, label_end, NULL);

    $$->code = $3->code;
    $$->code = ILOC_concat_operations($$->code, cbr);

    $$->code = ILOC_concat_operations($$->code, lbl_true);
    if ($5)
    {
        $$->code = ILOC_concat_operations($$->code, $5->code);
    }

    $$->code = ILOC_concat_operations($$->code, jump_end);

    $$->code = ILOC_concat_operations($$->code, lbl_false);
    if ($7)
    {
        $$->code = ILOC_concat_operations($$->code, $7->code);
    }

    $$->code = ILOC_concat_operations($$->code, lbl_end);

    asd_add_child($$, $3);

    if ($5)
    {
        asd_add_child($$, $5);
    }

    if ($7)
    {
        asd_add_child($$, $7);
    }
};

controle_fluxo_se: TK_SE '(' expressao ')' bloco_comandos {
    $$ = asd_new("se");
    $$->is_int = $3->is_int;

    char label_true[32], label_false[32];
    ILOC_new_label(label_true);
    ILOC_new_label(label_false);

    ILOC_operation_t *cbr = ILOC_new_operation(CBR, $3->temp, label_true, label_false, NULL);
    ILOC_operation_t *lbl_true = ILOC_new_operation(NOP, NULL, NULL, NULL, label_true);
    ILOC_operation_t *lbl_end = ILOC_new_operation(NOP, NULL, NULL, NULL, label_false);

    $$->code = $3->code;
    $$->code = ILOC_concat_operations($$->code, cbr);
    $$->code = ILOC_concat_operations($$->code, lbl_true);
    $$->code = ILOC_concat_operations($$->code, $5->code);
    $$->code = ILOC_concat_operations($$->code, lbl_end);

    asd_add_child($$, $3);
    if ($5)
    {
        asd_add_child($$, $5);
    }
};

controle_fluxo_repeticao: TK_ENQUANTO '(' expressao ')' bloco_comandos {
    $$ = asd_new("enquanto");
    $$->is_int = $3->is_int;

    char label_start[32], label_true[32], label_end[32];
    ILOC_new_label(label_start);
    ILOC_new_label(label_true);
    ILOC_new_label(label_end);

    ILOC_operation_t *lbl_start = ILOC_new_operation(NOP, NULL, NULL, NULL, label_start);
    ILOC_operation_t *cbr = ILOC_new_operation(CBR, $3->temp, label_true, label_end, NULL);
    ILOC_operation_t *lbl_true = ILOC_new_operation(NOP, NULL, NULL, NULL, label_true);
    ILOC_operation_t *jump_start = ILOC_new_operation(JUMPI, NULL, NULL, label_start, NULL);
    ILOC_operation_t *lbl_end = ILOC_new_operation(NOP, NULL, NULL, NULL, label_end);

    $$->code = lbl_start;
    $$->code = ILOC_concat_operations($$->code, $3->code);
    $$->code = ILOC_concat_operations($$->code, cbr);
    $$->code = ILOC_concat_operations($$->code, lbl_true);
    $$->code = ILOC_concat_operations($$->code, $5->code);
    $$->code = ILOC_concat_operations($$->code, jump_start);
    $$->code = ILOC_concat_operations($$->code, lbl_end);

    asd_add_child($$, $3);
    if ($5)
    {
        asd_add_child($$, $5);
    }
};

/********************** Expressoes */
expressao: expressao_nv6 { $$ = $1; };
expressao: expressao '|' expressao_nv6 {
    if ($1->is_int != 1 || $3->is_int != 1) {
        fprintf(stderr, "Erro linha %d: Operador '|' requer operandos do tipo int.\n", yylineno);
        exit(ERR_WRONG_TYPE);
    }
    $$ = asd_new("|");
    $$->is_int = 1;

    char temp[32];

    ILOC_new_temp(temp);
    $$->temp = strdup(temp);

    ILOC_operation_t *op = ILOC_new_operation(OR, $1->temp, $3->temp, temp, NULL);
    $$->code = ILOC_concat_operations($1->code, $3->code);
    $$->code = ILOC_concat_operations($$->code, op);

    asd_add_child($$, $1);
    asd_add_child($$, $3);
};

expressao_nv6: expressao_nv5 { $$ = $1; };
expressao_nv6: expressao_nv6 '&' expressao_nv5{
    if ($1->is_int != 1 || $3->is_int != 1) {
        fprintf(stderr, "Erro linha %d: Operador '&' requer operandos do tipo int.\n", yylineno);
        exit(ERR_WRONG_TYPE);
    }

    $$ = asd_new("&");
    $$->is_int = 1;

    char temp[32];

    ILOC_new_temp(temp);
    $$->temp = strdup(temp);

    ILOC_operation_t *op = ILOC_new_operation(AND, $1->temp, $3->temp, temp, NULL);
    $$->code = ILOC_concat_operations($1->code, $3->code);
    $$->code = ILOC_concat_operations($$->code, op);

    asd_add_child($$, $1);
    asd_add_child($$, $3);
};

expressao_nv5: expressao_nv4 { $$ = $1; };
expressao_nv5: expressao_nv5 TK_OC_EQ expressao_nv4{
    if ($1->is_int != $3->is_int) {
        fprintf(stderr, "Erro linha %d: Tipos incompatíveis para operador '=='.\n", yylineno);
        exit(ERR_WRONG_TYPE);
    }
    $$ = asd_new("==");
    $$->is_int = 1;

    char temp[32];

    ILOC_new_temp(temp);
    $$->temp = strdup(temp);

    ILOC_operation_t *op = ILOC_new_operation(CMP_EQ, $1->temp, $3->temp, temp, NULL);
    $$->code = ILOC_concat_operations($1->code, $3->code);
    $$->code = ILOC_concat_operations($$->code, op);

    asd_add_child($$, $1);
    asd_add_child($$, $3);
};
expressao_nv5: expressao_nv5 TK_OC_NE expressao_nv4{
    if ($1->is_int != $3->is_int) {
        fprintf(stderr, "Erro linha %d: Tipos incompatíveis para operador '!='.\n", yylineno);
        exit(ERR_WRONG_TYPE);
    }
    $$ = asd_new("!=");
    $$->is_int = 1;

    char temp[32];

    ILOC_new_temp(temp);
    $$->temp = strdup(temp);

    ILOC_operation_t *op = ILOC_new_operation(CMP_NE, $1->temp, $3->temp, temp, NULL);
    $$->code = ILOC_concat_operations($1->code, $3->code);
    $$->code = ILOC_concat_operations($$->code, op);

    asd_add_child($$, $1);
    asd_add_child($$, $3);
};

expressao_nv4: expressao_nv3 { $$ = $1; };
expressao_nv4: expressao_nv4 TK_OC_LE expressao_nv3{
    if ($1->is_int != $3->is_int) {
        fprintf(stderr, "Erro linha %d: Tipos incompatíveis para operador '<='.\n", yylineno);
        exit(ERR_WRONG_TYPE);
    }
    $$ = asd_new("<=");
    $$->is_int = 1;

    char temp[32];

    ILOC_new_temp(temp);
    $$->temp = strdup(temp);

    ILOC_operation_t *op = ILOC_new_operation(CMP_LE, $1->temp, $3->temp, temp, NULL);
    $$->code = ILOC_concat_operations($1->code, $3->code);
    $$->code = ILOC_concat_operations($$->code, op);

    asd_add_child($$, $1);
    asd_add_child($$, $3);
};
expressao_nv4: expressao_nv4 TK_OC_GE expressao_nv3{
    if ($1->is_int != $3->is_int) {
        fprintf(stderr, "Erro linha %d: Tipos incompatíveis para operador '>='.\n", yylineno);
        exit(ERR_WRONG_TYPE);
    }
    $$ = asd_new(">=");
    $$->is_int = 1;

    char temp[32];

    ILOC_new_temp(temp);
    $$->temp = strdup(temp);

    ILOC_operation_t *op = ILOC_new_operation(CMP_GE, $1->temp, $3->temp, temp, NULL);
    $$->code = ILOC_concat_operations($1->code, $3->code);
    $$->code = ILOC_concat_operations($$->code, op);

    asd_add_child($$, $1);
    asd_add_child($$, $3);
};
expressao_nv4: expressao_nv4 '>' expressao_nv3{
    if ($1->is_int != $3->is_int) {
        fprintf(stderr, "Erro linha %d: Tipos incompatíveis para operador '>'.\n", yylineno);
        exit(ERR_WRONG_TYPE);
    }
    $$ = asd_new(">");
    $$->is_int = 1;

    char temp[32];

    ILOC_new_temp(temp);
    $$->temp = strdup(temp);

    ILOC_operation_t *op = ILOC_new_operation(CMP_GT, $1->temp, $3->temp, temp, NULL);
    $$->code = ILOC_concat_operations($1->code, $3->code);
    $$->code = ILOC_concat_operations($$->code, op);

    asd_add_child($$, $1);
    asd_add_child($$, $3);
};
expressao_nv4: expressao_nv4 '<' expressao_nv3{
    if ($1->is_int != $3->is_int) {
        fprintf(stderr, "Erro linha %d: Tipos incompatíveis para operador '<'.\n", yylineno);
        exit(ERR_WRONG_TYPE);
    }

    $$ = asd_new("<");
    $$->is_int = 1;

    char temp[32];

    ILOC_new_temp(temp);
    $$->temp = strdup(temp);

    ILOC_operation_t *op = ILOC_new_operation(CMP_LT, $1->temp, $3->temp, temp, NULL);
    $$->code = ILOC_concat_operations($1->code, $3->code);
    $$->code = ILOC_concat_operations($$->code, op);

    asd_add_child($$, $1);
    asd_add_child($$, $3);
};

expressao_nv3: expressao_nv2 { $$ = $1; };
expressao_nv3: expressao_nv3 '+' expressao_nv2{
    if ($1->is_int != $3->is_int) {
        fprintf(stderr, "Erro linha %d: Tipos incompatíveis para operador '+'. (is_int=%d e is_int=%d)\n",
                yylineno, $1->is_int, $3->is_int);
        exit(ERR_WRONG_TYPE);
    }
    $$ = asd_new("+");
    $$->is_int = $1->is_int;

    char temp[32];

    ILOC_new_temp(temp);
    $$->temp = strdup(temp);

    ILOC_operation_t *load1 = ILOC_new_operation(LOADA0, $1->temp, "%edx", NULL, NULL);
    ILOC_operation_t *load2 = ILOC_new_operation(LOADA0, $3->temp, "%eax", NULL, NULL);
    ILOC_operation_t *op = ILOC_new_operation(ADD, "%edx", "%eax", NULL, NULL);
    ILOC_operation_t *store = ILOC_new_operation(STOREAI, "%eax", temp, NULL, NULL);
    $$->code = ILOC_concat_operations($1->code, $3->code);
    $$->code = ILOC_concat_operations($$->code, load1);
    $$->code = ILOC_concat_operations($$->code, load2);
    $$->code = ILOC_concat_operations($$->code, op);
    $$->code = ILOC_concat_operations($$->code, store);

    asd_add_child($$, $1);
    asd_add_child($$, $3);
};
expressao_nv3: expressao_nv3 '-' expressao_nv2{
    if ($1->is_int != $3->is_int) {
        fprintf(stderr, "Erro linha %d: Tipos incompatíveis para operador '-'. (is_int=%d e is_int=%d)\n",
                yylineno, $1->is_int, $3->is_int);
        exit(ERR_WRONG_TYPE);
    }
    $$ = asd_new("-");
    $$->is_int = $1->is_int;

    char temp[32];

    ILOC_new_temp(temp);
    $$->temp = strdup(temp);

    ILOC_operation_t *load1 = ILOC_new_operation(LOADA0, $1->temp, "%edx", NULL, NULL);
    ILOC_operation_t *load2 = ILOC_new_operation(LOADA0, $3->temp, "%eax", NULL, NULL);
    ILOC_operation_t *op = ILOC_new_operation(SUB, "%edx", "%eax", NULL, NULL);
    ILOC_operation_t *store = ILOC_new_operation(STOREAI, "%eax", temp, NULL, NULL);
    $$->code = ILOC_concat_operations($1->code, $3->code);
    $$->code = ILOC_concat_operations($$->code, load1);
    $$->code = ILOC_concat_operations($$->code, load2);
    $$->code = ILOC_concat_operations($$->code, op);
    $$->code = ILOC_concat_operations($$->code, store);

    asd_add_child($$, $1);
    asd_add_child($$, $3);
};

expressao_nv2: expressao_nv1 { $$ = $1; };
expressao_nv2: expressao_nv2 '%' expressao_nv1{
    if ($1->is_int != 1 || $3->is_int != 1) {
        fprintf(stderr, "Erro linha %d: Operador '%%' requer operandos do tipo int.\n", yylineno);
        exit(ERR_WRONG_TYPE);
    }
    $$ = asd_new("%");
    $$->is_int = 1;

    char temp[32];

    ILOC_new_temp(temp);
    $$->temp = strdup(temp);

    ILOC_operation_t *load1 = ILOC_new_operation(LOADA0, $1->temp, "%eax", NULL, NULL);
    ILOC_operation_t *op = ILOC_new_operation(DIV, $3->temp, NULL, NULL, NULL);
    ILOC_operation_t *store = ILOC_new_operation(STOREAI, "%edx", temp, NULL, NULL);
    $$->code = ILOC_concat_operations($1->code, $3->code);
    $$->code = ILOC_concat_operations($$->code, load1);
    $$->code = ILOC_concat_operations($$->code, op);
    $$->code = ILOC_concat_operations($$->code, store);

    asd_add_child($$, $1);
    asd_add_child($$, $3);
};
expressao_nv2: expressao_nv2 '/' expressao_nv1{
    if ($1->is_int != $3->is_int) {
        fprintf(stderr, "Erro linha %d: Tipos incompatíveis para operador '/'. (is_int=%d e is_int=%d)\n",
                yylineno, $1->is_int, $3->is_int);
        exit(ERR_WRONG_TYPE);
    }
    $$ = asd_new("/");
    $$->is_int = $1->is_int;

    char temp[32];

    ILOC_new_temp(temp);
    $$->temp = strdup(temp);

    ILOC_operation_t *load1 = ILOC_new_operation(LOADA0, $1->temp, "%eax", NULL, NULL);
    ILOC_operation_t *op = ILOC_new_operation(DIV, $3->temp, NULL, NULL, NULL);
    ILOC_operation_t *store = ILOC_new_operation(STOREAI, "%eax", temp, NULL, NULL);
    $$->code = ILOC_concat_operations($1->code, $3->code);
    $$->code = ILOC_concat_operations($$->code, load1);
    $$->code = ILOC_concat_operations($$->code, op);
    $$->code = ILOC_concat_operations($$->code, store);

    asd_add_child($$, $1);
    asd_add_child($$, $3);
};
expressao_nv2: expressao_nv2 '*' expressao_nv1{
    if ($1->is_int != $3->is_int) {
        fprintf(stderr, "Erro linha %d: Tipos incompatíveis para operador '*'. (is_int=%d e is_int=%d)\n",
                yylineno, $1->is_int, $3->is_int);
        exit(ERR_WRONG_TYPE);
    }
    $$ = asd_new("*");
    $$->is_int = $1->is_int;

    char temp[32];

    ILOC_new_temp(temp);
    $$->temp = strdup(temp);

    ILOC_operation_t *load1 = ILOC_new_operation(LOADA0, $1->temp, "%edx", NULL, NULL);
    ILOC_operation_t *load2 = ILOC_new_operation(LOADA0, $3->temp, "%eax", NULL, NULL);
    ILOC_operation_t *op = ILOC_new_operation(MULT, "%edx", "%eax", NULL, NULL);
    ILOC_operation_t *store = ILOC_new_operation(STOREAI, "%eax", temp, NULL, NULL);
    $$->code = ILOC_concat_operations($1->code, $3->code);
    $$->code = ILOC_concat_operations($$->code, load1);
    $$->code = ILOC_concat_operations($$->code, load2);
    $$->code = ILOC_concat_operations($$->code, op);
    $$->code = ILOC_concat_operations($$->code, store);

    asd_add_child($$, $1);
    asd_add_child($$, $3);
};

expressao_nv1: operando { $$ = $1; };
expressao_nv1: '+' operando{
    $$ = asd_new("+");
    $$->is_int = $2->is_int;

    $$->temp = $2->temp;
    $$->code = $2->code;

    asd_add_child($$, $2);
};
expressao_nv1: '-' operando{
    $$ = asd_new("-");
    $$->is_int = $2->is_int;

    char temp[32];
    ILOC_new_temp(temp);

    $$->temp = strdup(temp);

    ILOC_operation_t *load2 = ILOC_new_operation(LOADA0, $2->temp, "%eax", NULL, NULL);
    ILOC_operation_t *op = ILOC_new_operation(RSUBI, $2->temp, "0", temp, NULL);
    ILOC_operation_t *store = ILOC_new_operation(STOREAI, "%eax", temp, NULL, NULL);
    $$->code = ILOC_concat_operations($2->code, load2);
    $$->code = ILOC_concat_operations($2->code, op);
    $$->code = ILOC_concat_operations($2->code, store);

    asd_add_child($$, $2);
};
expressao_nv1: '!' operando{
    if ($2->is_int != 1) {
        fprintf(stderr, "Erro linha %d: Operador '!' requer operando do tipo int.\n", yylineno);
        exit(ERR_WRONG_TYPE);
    }
    $$ = asd_new("!");
    $$->is_int = 1;

    char temp[32];
    ILOC_new_temp(temp);
    $$->temp = strdup(temp);

    ILOC_operation_t *op = ILOC_new_operation(XOR, $2->temp, "1", temp, NULL);
    $$->code = ILOC_concat_operations($2->code, op);

    asd_add_child($$, $2);
};

/********** Expressoes Nv 0 */
operando: TK_ID {
    Simbolo *s = tabela_buscar(tabela, $1->valor);
    if (s == NULL) {
        fprintf(stderr, "Erro linha %d: identificador '%s' não declarado\n", yylineno, $1->valor);
        exit(ERR_UNDECLARED);
    }
    if (s->natureza == FUNCAO) {
        fprintf(stderr, "Erro linha %d: '%s' é uma função, mas foi usada como variável\n", yylineno, $1->valor);
        exit(ERR_FUNCTION);
    }

    $$ = asd_new($1->valor);
    $$->is_int = (s->tipo == TIPO_INT);

    char temp[32]; ILOC_new_temp(temp);
    $$->temp = strdup(temp);

    char *base_reg = s->is_global ? "rbss" : "rbp";
    char offset_str[16];
    sprintf(offset_str, "%d", s->mem_offset);

    $$->code = ILOC_new_operation(LOADAI, base_reg, offset_str, temp, NULL);

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


/* --- Funções da tabela --- */

TabelaSimbolos *tabela_criar(TabelaSimbolos *anterior) {
    TabelaSimbolos *tabela = malloc(sizeof(TabelaSimbolos));

    tabela->anterior = anterior;
    tabela->primeiro = NULL;

    return tabela;
}

Parametro *parametro_criar(int tipo, Dado dado) {
    Parametro *p = malloc(sizeof(Parametro));

    p->tipo = tipo;
    p->dado = dado;
    p->prox = NULL;

    return p;
}

void parametros_destruir(Parametro *p) {
    if (p != NULL){
        parametros_destruir(p->prox);
        free(p);
    }
}

Simbolo *tabela_buscar(TabelaSimbolos *tabela, const char *nome) {
    TabelaSimbolos *itera_tabela = tabela;

    while (itera_tabela != NULL)
    {
        Simbolo *simbolo_atual = itera_tabela->primeiro;

        while (simbolo_atual != NULL)
        {
            if (strcmp(simbolo_atual->chave, nome) == 0)
            {
                return simbolo_atual;
            }

            simbolo_atual = simbolo_atual->prox;
        }

        itera_tabela = itera_tabela->anterior;
    }

    return NULL;
}

Simbolo *tabela_inserir_funcao(TabelaSimbolos *tabela, char *chave, int natureza, int tipo, Parametro *params, Dado dado) {
    if (tabela_buscar(tabela, chave) != NULL){
        printf("Erro: símbolo '%s' já existe!\n", chave);
        exit(ERR_DECLARED);
    }

    Simbolo *s = malloc(sizeof(Simbolo));
    s->chave = strdup(chave);
    s->natureza = natureza;
    s->tipo = tipo;
    s->parametros = params;
    s->dado = dado;
    s->prox = NULL;
    s->mem_offset = -1;
    s->is_global = 0;

    if (tabela == NULL)
    {
        fprintf(stderr, "Erro: tabela de símbolos não inicializada!\n");
    }


    if (tabela->primeiro == NULL) {
        tabela->primeiro = s;
    }
    else {
        Simbolo *simbolo_buffer = tabela->primeiro;

        while (simbolo_buffer->prox != NULL)
            simbolo_buffer = simbolo_buffer->prox;

        simbolo_buffer->prox = s;
    }

    return s;
}

void simbolos_destruir(Simbolo *simbolo) {
    if (simbolo != NULL) {
        simbolos_destruir(simbolo->prox);
        free(simbolo->chave);
        parametros_destruir(simbolo->parametros);
        free(simbolo);
    }
}

TabelaSimbolos *tabela_destruir(TabelaSimbolos *tabela) {
    TabelaSimbolos *anterior = tabela->anterior;

    simbolos_destruir(tabela->primeiro);
    free(tabela);

    return anterior;
}
