CC = gcc
FLEX = flex
BISON = bison

COMMON_FLAGS = -Wall -Werror
# DEBUG_FLAGS = -g3 -O0 -fsanitize=address
RELEASE_FLAGS = -O3

# CFLAGS = $(COMMON_FLAGS) $(DEBUG_FLAGS)
CFLAGS = $(COMMON_FLAGS) $(RELEASE_FLAGS)

# MacOS Check
OS_NAME := $(shell uname -s)
ifeq ($(OS_NAME), Darwin)
	BISON = /opt/homebrew/opt/bison/bin/bison
endif

LEX_SRC = scanner.l
LEX_OUT = lex.yy.c
BISON_SRC = parser.y
BISON_OUT = parser.tab.c
SRCS = main.c asd.c iloc_lang.c
EXEC = etapa5

all: $(EXEC)

$(EXEC): $(LEX_OUT) $(BISON_OUT)
	$(CC) $(CFLAGS) -o $@ $(SRCS) $(LEX_OUT) $(BISON_OUT)

$(LEX_OUT): $(LEX_SRC)
	$(FLEX) $<

$(BISON_OUT) : $(BISON_SRC)
	$(BISON) -d --report=all $<

# For release
release: CFLAGS = $(COMMON_FLAGS) $(RELEASE_FLAGS)
release: clean $(EXEC)

clean:
	# Corrected typo here (BISOUN_OUT -> BISON_OUT)
	rm -f $(EXEC) $(LEX_OUT) $(BISON_OUT)
	rm -rf *.o
	rm -rf parser.tab.c
	rm -rf parser.tab.h
	rm -rf parser.output
