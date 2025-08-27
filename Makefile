CC = gcc
FLEX = flex
CFLAGS = -Wall -g

LEX_SRC = scanner.l
LEX_OUT = lex.yy.c
MAIN = main.c
EXEC = etapa1

all: $(EXEC)

$(EXEC): $(MAIN) $(LEX_OUT)
	$(CC) $(CFLAGS) -o $(EXEC) $(MAIN) $(LEX_OUT) -lfl

$(LEX_OUT): $(LEX_SRC)
	$(FLEX) $(LEX_SRC)

clean:
	rm -f $(EXEC) $(LEX_OUT)
