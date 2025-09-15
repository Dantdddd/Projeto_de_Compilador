CC = gcc
FLEX = flex
BISON = bison
CFLAGS = -Wall

LEX_SRC = scanner.l
LEX_OUT = lex.yy.c
BISON_SRC = parser.y
BISON_OUT = parser.tab.c
SRCS = main.c
EXEC = etapa2

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
	rm -f parser.tab.c
	rm -f parser.tab.h