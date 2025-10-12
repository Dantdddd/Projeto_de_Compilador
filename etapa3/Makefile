CC = gcc
FLEX = flex
BISON = bison
CFLAGS = -Wall -Werror -fsanitize=address -fsanitize=address

# No MacOS tem um Bison 2.3 instalado.
# Muda o path do Bison para o instalado pelo Homebrew (Versao 3.8.2)
OS_NAME := $(shell uname -s)
ifeq ($(OS_NAME), Darwin)
	BISON = /opt/homebrew/opt/bison/bin/bison
endif

LEX_SRC = scanner.l
LEX_OUT = lex.yy.c
BISON_SRC = parser.y
BISON_OUT = parser.tab.c
SRCS = main.c asd.c
EXEC = etapa3

all: $(EXEC)

$(EXEC): $(LEX_OUT) $(BISON_OUT)
	$(CC) $(CFLAGS) -o $@ $(SRCS) $(LEX_OUT) $(BISON_OUT)

$(LEX_OUT): $(LEX_SRC)
	$(FLEX) $<

$(BISON_OUT) : $(BISON_SRC)
	$(BISON) -d --report=all $<

clean:
	rm -f $(EXEC) $(LEX_OUT) $(BISOUN_OUT)
	rm -rf *.o
	rm -rf parser.tab.c
	rm -rf parser.tab.h
	rm -rf parser.output