#include "stdio.h"
#include "stdlib.h"
#include "string.h"
#include "stdarg.h"
#include "parser.tab.h"

enum node_kind
{
    EXT_DEF_LIST,	
    EXT_VAR_DEF,
    FUN_DEF,		
    FUN_DEC,	
    STRUCT_DEF,		
    STRUCT_DEC,	
    STRUCT_TAG,		
    EXP_ELE,		
    EXP_ARRAY,
    ARRAY_DEC,	
    EXT_DEC_LIST,	
    PARAM_LIST,		
    PARAM_DEC,	
    VAR_DEF,		
    DEC_LIST,		
    DEF_LIST,		
    COMP_STM,		
    STM_LIST,		
    EXP_STMT,		
    FOR_DEC,		
    IF_THEN,		
    IF_THEN_ELSE,	
	CONTINUE_NODE,	
	BREAK_NODE,		
    FUN_CALL,	
    ARGS,		
	Locate
	
};

struct node
{                        //以下对结点属性定义没有考虑存储效率，只是简单地列出要用到的一些属性
    enum node_kind kind; //结点类型
    char struct_name[33];
    union {
        char type_id[33]; //由标识符生成的叶结点
        int type_int;     //由整常数生成的叶结点
        float type_float; //由浮点常数生成的叶结点
        char type_char[3];
        char type_string[31];
        struct Array *type_array;
        struct Struct *type_struct;
    };
    struct node *ptr[3];        //子树指针，由kind确定有多少棵子树
    int level;                  //层号
    char Snext[15];             //该结点对应语句执行后的下一条语句位置标号
    int type;   //结点对应值的类型
    int pos;    //语法单位所在位置行号
};

struct node *mknode(int kind, struct node *first, struct node *second, struct node *third, int pos);
