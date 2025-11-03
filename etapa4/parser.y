%code requires{
    #include "asd.h"
    #include <string.h>

    #define LITERAL 0
    #define IDENTIFICADOR 1
    #define FUNCAO 2
    #define TIPO_INT 3
    #define TIPO_FLOAT 4

    #define ERR_UNDECLARED       10 //2.2
    #define ERR_DECLARED         11 //2.2
    #define ERR_VARIABLE         20 //2.3
    #define ERR_FUNCTION         21 //2.3
    #define ERR_WRONG_TYPE       30 //2.4
    #define ERR_MISSING_ARGS     40 //2.5
    #define ERR_EXCESS_ARGS      41 //2.5
    #define ERR_WRONG_TYPE_ARGS  42 //2.5

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
        char* valor;  // sempre uma string duplicada com strdup()
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
        Parametro *parametros;    // NULL se não for função
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
    TabelaSimbolos *tabela_inserir_funcao(TabelaSimbolos *tabela, char *chave, int natureza, int tipo, Parametro *params, Dado dado);
    TabelaSimbolos *tabela_destruir(TabelaSimbolos *tabela);

    void tabela_imprimir(TabelaSimbolos *tabela);
    void simbolos_destruir(Simbolo *simbolo);
    Parametro *parametro_criar(int tipo, Dado dado);

    void parametros_destruir(Parametro *p);
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
    Parametro *parametro;
    int TipoSimbolo;
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

%type <parametro> lista_parametros_opcional lista_parametros elemento_lista_parametros
%type <TipoSimbolo> tipo

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
bloco_comandos: '[' escopo_ini lista_comandos escopo_fim ']' { $$ = $3; };

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

tipo: TK_INTEIRO { $$ = TIPO_INT; };
tipo: TK_DECIMAL { $$ = TIPO_FLOAT; };

declaracao_variavel_global: TK_VAR TK_ID TK_ATRIB tipo {
    // Verificar se já foi declarado
    if (tabela_buscar(tabela, $2->valor) != NULL) {
        fprintf(stderr, "Erro linha %d: variável '%s' já declarada\n", yylineno, $2->valor);
        exit(ERR_DECLARED);
    }

    Dado d; // inicial vazio
    tabela = tabela_inserir_funcao(tabela, $2->valor, IDENTIFICADOR, $4, NULL, d);

    free($2->valor);
    free($2);
    $$ = NULL;
};


/********************** Declaracao de variaveis locais*/
declaracao_variavel_local: TK_VAR TK_ID TK_ATRIB tipo TK_COM literal {
    if (tabela_buscar(tabela, $2->valor) != NULL) {
        exit(ERR_DECLARED);
    }

    Dado d; // exemplo: preencher valor se quiser
    tabela = tabela_inserir_funcao(tabela, $2->valor, IDENTIFICADOR, $4, NULL, d);

    $$ = asd_new("com");
    asd_add_child($$, asd_new($2->valor));
    asd_add_child($$, $6);

    free($2->valor);
    free($2);
};


/********************** Atribuicao de variaveis */
atribuicao_variavel: TK_ID TK_ATRIB expressao {
    Simbolo *s = tabela_buscar(tabela, $1->valor);
    if (s == NULL) {
        fprintf(stderr, "Erro linha %d: identificador '%s' não declarado\n", yylineno, $1->valor);
        exit(ERR_UNDECLARED);
    }

    $$ = asd_new(":=");
    asd_add_child($$, asd_new($1->valor));
    if ($3) asd_add_child($$, $3);

    free($1->valor);
    free($1);
};


/********************** Definicao de funcoes */
definicao_funcao: TK_ID TK_SETA tipo lista_parametros_opcional TK_ATRIB bloco_comandos {
    if (tabela_buscar(tabela, $1->valor) != NULL) {
        fprintf(stderr, "Erro linha %d: função '%s' já declarada\n", yylineno, $1->valor);
        exit(ERR_DECLARED);
    }

    Dado dado; // valor vazio para agora
    tabela = tabela_inserir_funcao(tabela, $1->valor, FUNCAO, $3, $4, dado);

    $$ = asd_new($1->valor);
    if ($6) asd_add_child($$, $6);

    free($1->valor);
    free($1);
    };

lista_parametros_opcional: %empty { $$ = NULL; };
lista_parametros_opcional: TK_COM lista_parametros { $$ = $2; };
lista_parametros_opcional: lista_parametros { $$ = $1; };

lista_parametros: elemento_lista_parametros { $$ = $1; };
lista_parametros: lista_parametros ',' elemento_lista_parametros {
    // Conectar as listas
    Parametro *ultimo = $1;
    while (ultimo->prox != NULL) ultimo = ultimo->prox;
    ultimo->prox = $3;
    $$ = $1;
};

elemento_lista_parametros: TK_ID TK_ATRIB tipo {
    Dado dado;
    $$ = parametro_criar($3, dado); // devolve Parametro*

    free($1->valor);
    free($1);
};

chamada_funcao: TK_ID '(' lista_argumentos_opcional ')' {
    Simbolo *s = tabela_buscar(tabela, $1->valor);
    if (s == NULL) {
         exit(ERR_UNDECLARED);
    }
    if (s->natureza != FUNCAO) {
        exit(ERR_FUNCTION);
    }


    char label[64];
    sprintf(label, "call %s", $1->valor);
    $$ = asd_new(label);
    if ($3) asd_add_child($$, $3);

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
    while (itera_tabela != NULL){
        Simbolo *simbolo_atual = itera_tabela->primeiro;
        while (simbolo_atual != NULL) {
            if (strcmp(simbolo_atual->chave, nome) == 0){
                return simbolo_atual;
            }
            simbolo_atual = simbolo_atual->prox;
        }
        itera_tabela = itera_tabela->anterior;
    }

    return NULL;
}

TabelaSimbolos *tabela_inserir_funcao(TabelaSimbolos *tabela, char *chave, int natureza, int tipo, Parametro *params, Dado dado) {
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

    if (tabela == NULL) {
        fprintf(stderr, "Erro: tabela de símbolos não inicializada!\n");}


    if (tabela->primeiro == NULL) {
        tabela->primeiro = s;
    }
    else {
        Simbolo *simbolo_buffer = tabela->primeiro;
        while (simbolo_buffer->prox != NULL)
            simbolo_buffer = simbolo_buffer->prox;
        simbolo_buffer->prox = s;
    }

    return tabela;
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

/* --- Função auxiliar para imprimir --- */
void tabela_imprimir(TabelaSimbolos *tabela) {
    printf("=== Tabela de Símbolos ===\n");
    Simbolo *s = tabela->primeiro;
    while (s != NULL) {
        printf("Nome: %s | Natureza: %d | Tipo: %s\n",
               s->chave,
               s->natureza,
               s->tipo == TIPO_INT ? "int" : "float");

        if (s->parametros) {
            printf("  Parâmetros:\n");
            Parametro *p = s->parametros;
            int i = 1;
            while (p) {
                printf("    #%d tipo=%s\n", i++, p->tipo == TIPO_INT ? "int" : "float");
                p = p->prox;
            }
        }

        s = s->prox;
    }
    printf("===========================\n\n");
}
