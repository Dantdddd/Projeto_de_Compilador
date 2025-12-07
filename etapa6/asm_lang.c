/*
    * Luis Franca
    * Dante
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "asm_lang.h"

int g_n_label = 0;
int g_n_temp = 0;

static const char* get_opcode_str(ILOC_OPERATION_TYPE_t type)
{
    switch(type) {
        case ADD: return "addl";
        case SUB: return "subl";
        case MULT: return "imull";
        case DIV: return "cltd";
        case ADDI: return "addI";
        case SUBI: return "subI";
        case RSUBI: return "negl";
        case MULTI: return "multI";
        case DIVI: return "divI";
        case RDIVI: return "rdivI";
        case LSHIFT: return "lshift";
        case LSHIFTI: return "lshiftI";
        case RSHIFT: return "rshift";
        case RSHIFTI: return "rshiftI";
        case AND: return "movl";
        case OR: return "movl";
        case XOR: return "cmpl";
        case LOAD: return "movl";
        case LOADAI: return "movl";
        case LOADA0: return "movl";
        case LOADI: return "movl";
        case CLOAD: return "cload";
        case CLOADAI: return "cloadI";
        case STORE: return "store";
        case STOREAI: return "movl";
        case STOREA0: return "storeAO";
        case CSTORE: return "cstore";
        case CSTOREAI: return "cstoreAI";
        case CSTOREA0: return "cstoreAO";
        case I2I: return "i2i";
        case C2C: return "c2c";
        case C2I: return "c2i";
        case I2C: return "i2c";
        case JUMPI: return "jmp";
        case CBR: return "jne";
        case CMP_LT: return "movl";
        case CMP_LE: return "cmp_LE";
        case CMP_EQ: return "cmp_EQ";
        case CMP_GE: return "cmp_GE";
        case CMP_GT: return "cmp_GT";
        case CMP_NE: return "cmp_NE";
        case NOP: return "nop";
        default: return "unknown";
    }
}

void ILOC_new_label(char* label)
{
    snprintf(label, 32, "L%d", g_n_label++);
}

void ILOC_new_temp(char* temp)
{
    snprintf(temp, 32, "-%d(%%rbp)", g_n_temp+=4);
}

ILOC_operation_t* ILOC_new_operation(ILOC_OPERATION_TYPE_t type, char* arg1, char* arg2, char* arg3, char* label)
{
    ILOC_operation_t* result;

    result = (ILOC_operation_t*)(malloc(sizeof(ILOC_operation_t)));

    result->next = NULL;

    result->arg1[0] = '\0';
    result->arg2[0] = '\0';
    result->arg3[0] = '\0';
    result->label[0] = '\0';

    result->type = type;

    if (label != NULL)
    {
        strcpy(result->label, label);
    }

    if (arg1 != NULL)
    {
        strcpy(result->arg1, arg1);
    }

    if (arg2 != NULL)
    {
        strcpy(result->arg2, arg2);
    }

    if (arg3 != NULL)
    {
        strcpy(result->arg3, arg3);
    }

    return result;
}

ILOC_operation_t* ILOC_concat_operations(ILOC_operation_t* list1, ILOC_operation_t* list2)
{
    ILOC_operation_t* current = list1;

    if (list1 == NULL)
    {
        return list2;
    }

    if (list2 == NULL)
    {
        return list1;
    }

    while (current->next != NULL)
    {
        current = current->next;
    }

    current->next = list2;

    return list1;
}

void ILOC_clean_operations(ILOC_operation_t* op)
{
    ILOC_operation_t* next;

    while (op != NULL)
    {
        next = op->next;
        free(op);
        op = next;
    }
}

void ILOC_print_operations(ILOC_operation_t* operation)
{
    if (operation == NULL)
       return;

    if (operation->label[0] != '\0') {
        printf("%s: ", operation->label);
    }

    // Opcode
    printf("%s ", get_opcode_str(operation->type));

    switch(operation->type)
    {
        case STOREAI:
        case CSTOREAI:
        case STOREA0:
        case CSTOREA0:
            printf("%s, %s", operation->arg1, operation->arg2);

            if (operation->arg3[0] != '\0')
            {
                printf(", %s", operation->arg3);
            }

            break;

        case CBR:
            printf("%s", operation->arg3);
            break;

        case JUMPI:
        case JUMP:
            if (operation->arg3[0] != '\0')
            {
                printf("%s", operation->arg3);
            }
            else
            {
                printf("%s", operation->arg1);
            }
            break;

        case LOADAI:
            if (operation->arg2[0] != '\0')
            {
                printf("-%s", operation->arg2);
            }
            if (operation->arg1[0] != '\0')
            {
                printf("(%%%s)", operation->arg1);
            }
            if (operation->arg3[0] != '\0')
            {
                printf(", %s", operation->arg3);
            }
            break;

        case LOADI:
            if (operation->arg1[0] != '\0')
            {
                printf("$%s", operation->arg1);
            }
            if (operation->arg3[0] != '\0')
            {
                printf(", %s", operation->arg3);
            }
            break;

        case LOADA0:
            if (operation->arg1[0] != '\0')
            {
                printf("%s", operation->arg1);
            }
            if (operation->arg2[0] != '\0')
            {
                printf(", %s", operation->arg2);
            }
            break;
        
        case DIV:
            printf("\nidivl ");
            if (operation->arg1[0] != '\0')
            {
                printf("%s", operation->arg1);
            }

            if (operation->arg2[0] != '\0')
            {
                printf(", %s", operation->arg2);
            }

            if (operation->arg3[0] != '\0')
            {
                printf(", %s", operation->arg3);
            }
            break;

        case XOR:
            printf("cmpl %s, %%eax\n", operation->arg1);
            printf("sete	%%al\nmovzbl	%%al, %%eax\ncmpl $0, %%eax");
            break;

        case CMP_EQ:
            printf("%s, %%eax\n", operation->arg2);
            printf("cmpl %s, %%eax\n", operation->arg1);
            printf("sete	%%al\nmovzbl	%%al, %%eax\ncmpl $0, %%eax");

        case CMP_NE:
            printf("%s, %%eax\n", operation->arg2);
            printf("cmpl %s, %%eax\n", operation->arg1);
            printf("setne	%%al\nmovzbl	%%al, %%eax\ncmpl $0, %%eax");
            break;

        case CMP_LE:
            printf("%s, %%eax\n", operation->arg2);
            printf("cmpl %s, %%eax\n", operation->arg1);
            printf("setle	%%al\nmovzbl	%%al, %%eax\ncmpl $0, %%eax");
            break;

        case CMP_GE:
        case CMP_LT:
            printf("%s, %%eax\n", operation->arg2);
            printf("cmpl %s, %%eax\n", operation->arg1);
            printf("setg	%%al\nmovzbl	%%al, %%eax\ncmpl $0, %%eax");
            break;

        case CMP_GT:
            printf("%s, %%eax\n", operation->arg1);
            printf("movl %s, %%edx\ncmpl $0, %%eax", operation->arg2);

        case AND:
            printf("%s, %%eax\n", operation->arg1);
            printf("movl %s, %%edx\nandl %%edx, %%eax", operation->arg2);
            break;

        case OR:
            printf("%s, %%eax\n", operation->arg1);
            printf("movl %s, %%edx\norl %%edx, %%eax", operation->arg2);
            break;

        default:
            if (operation->arg1[0] != '\0')
            {
                printf("%s", operation->arg1);
            }

            if (operation->arg2[0] != '\0')
            {
                printf(", %s", operation->arg2);
            }

            if (operation->arg3[0] != '\0')
            {
                printf(", %s", operation->arg3);
            }

            break;
    }

    printf("\n");

    if (operation->next)
        ILOC_print_operations(operation->next);
}