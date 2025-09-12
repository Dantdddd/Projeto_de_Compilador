/* A Bison parser, made by GNU Bison 3.8.2.  */

/* Bison interface for Yacc-like parsers in C

   Copyright (C) 1984, 1989-1990, 2000-2015, 2018-2021 Free Software Foundation,
   Inc.

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <https://www.gnu.org/licenses/>.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.

   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

/* DO NOT RELY ON FEATURES THAT ARE NOT DOCUMENTED in the manual,
   especially those whose name start with YY_ or yy_.  They are
   private implementation details that can be changed or removed.  */

#ifndef YY_YY_PARSER_TAB_H_INCLUDED
# define YY_YY_PARSER_TAB_H_INCLUDED
/* Debug traces.  */
#ifndef YYDEBUG
# define YYDEBUG 0
#endif
#if YYDEBUG
extern int yydebug;
#endif

/* Token kinds.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
  enum yytokentype
  {
    YYEMPTY = -2,
    YYEOF = 0,                     /* "end of file"  */
    YYerror = 256,                 /* error  */
    YYUNDEF = 257,                 /* "invalid token"  */
    TK_TIPO = 258,                 /* TK_TIPO  */
    TK_VAR = 259,                  /* TK_VAR  */
    TK_SENAO = 260,                /* TK_SENAO  */
    TK_DECIMAL = 261,              /* TK_DECIMAL  */
    TK_SE = 262,                   /* TK_SE  */
    TK_INTEIRO = 263,              /* TK_INTEIRO  */
    TK_ATRIB = 264,                /* TK_ATRIB  */
    TK_RETORNA = 265,              /* TK_RETORNA  */
    TK_SETA = 266,                 /* TK_SETA  */
    TK_ENQUANTO = 267,             /* TK_ENQUANTO  */
    TK_COM = 268,                  /* TK_COM  */
    TK_OC_LE = 269,                /* TK_OC_LE  */
    TK_OC_GE = 270,                /* TK_OC_GE  */
    TK_OC_EQ = 271,                /* TK_OC_EQ  */
    TK_OC_NE = 272,                /* TK_OC_NE  */
    TK_ID = 273,                   /* TK_ID  */
    TK_LI_INTEIRO = 274,           /* TK_LI_INTEIRO  */
    TK_LI_DECIMAL = 275,           /* TK_LI_DECIMAL  */
    TK_ER = 276                    /* TK_ER  */
  };
  typedef enum yytokentype yytoken_kind_t;
#endif

/* Value type.  */
#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
typedef int YYSTYPE;
# define YYSTYPE_IS_TRIVIAL 1
# define YYSTYPE_IS_DECLARED 1
#endif


extern YYSTYPE yylval;


int yyparse (void);


#endif /* !YY_YY_PARSER_TAB_H_INCLUDED  */
