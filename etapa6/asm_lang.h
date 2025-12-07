
/*
    * Luis Franca
    * Dante
*/

#ifndef ASM_LANG_H
#define ASM_LANG_H

#include <stdio.h>

#define ILOC_MAX_TOKEN_STR_LEN 64

typedef enum {
    NOP,
    ADD,
    SUB,
    MULT,
    DIV,
    ADDI,
    SUBI,
    RSUBI,
    MULTI,
    DIVI,
    RDIVI,
    LSHIFT,
    LSHIFTI,
    RSHIFT,
    RSHIFTI,
    AND,
    OR,
    XOR,
    LOAD,
    LOADI,
    LOADAI,
    LOADA0,
    CLOAD,
    CLOADAI,
    STORE,
    STOREAI,
    STOREA0,
    CSTORE,
    CSTOREAI,
    CSTOREA0,
    I2I,
    C2C,
    C2I,
    I2C,
    JUMP,
    JUMPI,
    CBR,
    CMP_LT,
    CMP_LE,
    CMP_EQ,
    CMP_GE,
    CMP_GT,
    CMP_NE

} ILOC_OPERATION_TYPE_t;


typedef struct ILOC_operation {
    ILOC_OPERATION_TYPE_t type;
    char label [ILOC_MAX_TOKEN_STR_LEN];
    char arg1  [ILOC_MAX_TOKEN_STR_LEN];
    char arg2  [ILOC_MAX_TOKEN_STR_LEN];
    char arg3  [ILOC_MAX_TOKEN_STR_LEN];
    struct ILOC_operation* next;

} ILOC_operation_t;

/*
 * The labels name control are kept as global varialbes inside asm_lang.c.
*/
void ILOC_new_label(char* label);
void ILOC_new_temp(char* label);

ILOC_operation_t* ILOC_new_operation(ILOC_OPERATION_TYPE_t type, char* arg1, char* arg2, char* arg3, char* label);
ILOC_operation_t* ILOC_concat_operations(ILOC_operation_t* op1, ILOC_operation_t* op2);

/*
 * Must be called to clean the memory used to stores the operations.
*/
void ILOC_clean_operations(ILOC_operation_t* op);

/* Helper function. */
void ILOC_print_operations(ILOC_operation_t* operation);


#endif