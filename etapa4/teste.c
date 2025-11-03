#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define LITERAL 0
#define IDENTIFICADOR 1
#define FUNCAO 2

typedef enum {
    TK_TIPO_ID,
    TK_TIPO_LITERAL
} TipoToken;

typedef enum {
    TIPO_INT,
    TIPO_FLOAT
} TipoSimbolo;

typedef union {
    int DadoInt;
    float DadoFloat;
} Dado;

typedef struct Parametro {
    TipoSimbolo tipo;
    Dado dado;
    struct Parametro *prox;
} Parametro;

typedef struct Simbolo {
    char *chave;
    int natureza;
    TipoSimbolo tipo;
    Parametro *parametros;
    Dado dado;
    struct Simbolo *prox;
} Simbolo;

typedef struct TabelaSimbolos {
    Simbolo *primeiro;
    struct TabelaSimbolos *anterior;
} TabelaSimbolos;

/* --- Funções da tabela --- */

TabelaSimbolos *tabela_criar(TabelaSimbolos *anterior) {
    TabelaSimbolos *tabela = malloc(sizeof(TabelaSimbolos));
    tabela->anterior = anterior;
    tabela->primeiro = NULL;
    return tabela;
}

Parametro *parametro_criar(TipoSimbolo tipo, Dado dado) {
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

void tabela_inserir_funcao(TabelaSimbolos *tabela, char *chave, int natureza, TipoSimbolo tipo, Parametro *params, Dado dado) {
    if (tabela_buscar(tabela, chave) != NULL){
        printf("Erro: símbolo '%s' já existe!\n", chave);
        return;
    }

    Simbolo *s = malloc(sizeof(Simbolo));
    s->chave = strdup(chave);
    s->natureza = natureza;
    s->tipo = tipo;
    s->parametros = params;
    s->dado = dado;
    s->prox = NULL;

    // Inserir no início da lista
    s->prox = tabela->primeiro;
    tabela->primeiro = s;
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

/* --- MAIN DE TESTE --- */

int main() {
    printf("Iniciando teste da Tabela de Símbolos...\n\n");

    // Criar tabela global
    TabelaSimbolos *global = tabela_criar(NULL);

    // Criar parâmetros para uma função
    Dado d1, d2;
    d1.DadoInt = 10;
    d2.DadoFloat = 3.14;

    Parametro *p1 = parametro_criar(TIPO_INT, d1);
    Parametro *p2 = parametro_criar(TIPO_FLOAT, d2);
    p1->prox = p2;

    // Inserir uma função
    Dado retorno;
    retorno.DadoInt = 0;
    tabela_inserir_funcao(global, "soma", FUNCAO, TIPO_INT, p1, retorno);

    // Inserir uma variável
    Dado var;
    var.DadoFloat = 5.5;
    tabela_inserir_funcao(global, "x", IDENTIFICADOR, TIPO_FLOAT, NULL, var);

    // Tentar inserir duplicado
    tabela_inserir_funcao(global, "soma", FUNCAO, TIPO_INT, NULL, retorno);

    // Buscar símbolo existente
    Simbolo *res = tabela_buscar(global, "x");
    if (res) {
        printf("Busca: símbolo '%s' encontrado! Tipo: %s\n\n",
               res->chave,
               res->tipo == TIPO_INT ? "int" : "float");
    }

    // Buscar símbolo inexistente
    res = tabela_buscar(global, "nao_existe");
    if (!res) {
        printf("Busca: símbolo 'nao_existe' não encontrado (OK)\n\n");
    }

    // Imprimir a tabela
    tabela_imprimir(global);

    // Destruir tabela
    global = tabela_destruir(global);

    printf("Tabela destruída com sucesso.\n");
    return 0;
}
