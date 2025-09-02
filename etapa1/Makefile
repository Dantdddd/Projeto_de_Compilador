CC = gcc
FLEX = flex
CFLAGS = -Wall -g

LEX_SRC = scanner.l
LEX_OUT = lex.yy.c
MAIN = $(filter-out $(LEX_OUT), $(wildcard *.c))
EXEC = etapa1

all: $(EXEC)

$(EXEC): $(MAIN) $(LEX_OUT)
	$(CC) $(CFLAGS) -o $@ $(MAIN) $(LEX_OUT) -lfl

$(LEX_OUT): $(LEX_SRC)
	$(FLEX) $<

clean:
	rm -f $(EXEC) $(LEX_OUT)