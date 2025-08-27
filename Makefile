CC = gcc
FLEX = flex
CFLAGS = -Wall -g

LEX_SRC = scanner.l
LEX_OUT = lex.yy.c
MAIN = main.c
EXEC = etapa1

all: $(EXEC)

# gera o executável compilando direto main.c + lex.yy.c
$(EXEC): $(MAIN) $(LEX_OUT)
	$(CC) $(CFLAGS) -o $(EXEC) $(MAIN) $(LEX_OUT) -lfl

# gera o lex.yy.c
$(LEX_OUT): $(LEX_SRC)
	$(FLEX) $(LEX_SRC)

clean:
	rm -f $(EXEC) $(LEX_OUT)
