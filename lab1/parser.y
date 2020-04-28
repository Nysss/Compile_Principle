%error-verbose
//可以显示错误的性质和行号
%locations
//准确定义第几行第几列有错误
%{

#include "stdio.h"
#include "math.h"
#include "string.h"
#include "def.h"

extern int yylineno;
extern char *yytext;
extern FILE *yyin;
void yyerror(const char* fmt, ...);
void display(struct node *,int);
%}

%union {
    int    	type_int;
    float  	type_float;
    char 	type_char[3];
    char 	type_string[31];
    char   	type_id[32];
    struct 	node *ptr;
};

//  %type 定义非终结符的语义值类型
%type  <ptr> Program ExtDefList ExtDef Specifier StructSpecifier OptTag Tag ExtDecList FunDec CompSt VarDec VarList ParamDec Stmt ForDec StmList DefList Def DecList Dec Exp Args Locate

//% token 定义终结符的语义值类型
%token <type_int> 		INT              				//指定INT的语义值是type_int，由词法分析得到的数值
%token <type_float> 	FLOAT							//指定FLOAT的语义值是type_float，由词法分析得到的数值
%token <type_char>		CHAR 							//指定CHAR的语义是type_char，由词法分析得到的数值
%token <type_string> 	STRING							//指定STRING的语义是type_string，由词法分析得到的数值
%token <type_id>		ID 	TYPE RELOP 					//指定ID的语义是type_id，由词法分析得到的数值

%token STRUCT LP RP LB RB LC RC SEMI COMMA DOT
%token ONE_PLUS ATUO_MINUS PLUS_ONE MINUS_ONE PLUS MINUS STAR DIV ASSIGNOP ASSIGNOP_MINUS ASSIGNOP_PLUS ASSIGNOP_DIV ASSIGNOP_STAR AND OR NOT IF ELSE WHILE FOR RETURN
%token BREAK CONTINUE 

%right	ASSIGNOP ASSIGNOP_MINUS ASSIGNOP_PLUS ASSIGNOP_DIV ASSIGNOP_STAR 	// 赋值符号
%left 	OR	
%left 	AND	
%left 	RELOP																//关系运算符号
%left 	PLUS MINUS			
%left 	STAR DIV
%right 	UMINUS NOT PLUS_ONE MINUS_ONE ONE_PLUS ATUO_MINUS										// 负号、非、自增和自减
%right 	LB
%left 	RB
%left 	DOT

//降低了规约相对于移进else的优先级
%nonassoc LOWER_THEN_ELSE
%nonassoc ELSE

%%

Program:	ExtDefList	{display($1,0);} 
			;
			
ExtDefList:						{$$=NULL;}
			| ExtDef ExtDefList	{$$=mknode(EXT_DEF_LIST,$1,$2,NULL,yylineno);}   //每一个EXTDEFLIST的结点，其第1棵子树对应一个外部变量声明或函数
			;
			
ExtDef:	Specifier ExtDecList SEMI	{$$=mknode(EXT_VAR_DEF,$1,$2,NULL,yylineno);}   		//该结点对应一个外部变量声明
		| Specifier SEMI																	//默认执行$$={$1}		
		| Specifier FunDec CompSt	{$$=mknode(FUN_DEF,$1,$2,$3,yylineno);}					//该结点对应一个函数定义
		| error SEMI   				{$$=NULL;}												//进入错误恢复 希望error后面跟的内容越多越好
		;

ExtDecList:	VarDec	
			| VarDec COMMA ExtDecList	{$$=mknode(EXT_DEC_LIST,$1,$3,NULL,yylineno);}
			;

Specifier:	TYPE						{$$=mknode(TYPE,NULL,NULL,NULL,yylineno);strcpy($$->type_id,$1);if($1=="int")$$->type=INT;if($1=="float")$$->type=FLOAT;if($1=="char")$$->type=CHAR;if($1=="string")$$->type=STRING;}
			| StructSpecifier	 
			;
			
StructSpecifier:	STRUCT OptTag LC DefList RC {$$=mknode(STRUCT_DEF,$2,$4,NULL,yylineno);}
					| STRUCT Tag  				{$$=mknode(STRUCT_DEC,$2,NULL,NULL,yylineno);}
					;
					
OptTag:			{$$=NULL;}
		| ID	{$$=mknode(STRUCT_TAG,NULL,NULL,NULL,yylineno);strcpy($$->struct_name,$1);}
		;
	   
Tag:	ID 		{$$=mknode(STRUCT_TAG,NULL,NULL,NULL,yylineno);strcpy($$->struct_name,$1);}
		;

VarDec:	ID						{$$=mknode(ID,NULL,NULL,NULL,yylineno);strcpy($$->type_id,$1);}   //ID结点，标识符符号串存放结点的type_id
		| VarDec LB Locate RB 	{$$=mknode(ARRAY_DEC,$1,$3,NULL,yylineno);}
        ;
		
Locate: INT					{$$=mknode(INT,NULL,NULL,NULL,yylineno);$$->type_int=$1;$$->type=INT;}
		;
		
FunDec:	ID LP VarList RP   	{$$=mknode(FUN_DEC,$3,NULL,NULL,yylineno);strcpy($$->type_id,$1);}//函数名存放在$$->type_id
		|ID LP  RP   		{$$=mknode(FUN_DEC,NULL,NULL,NULL,yylineno);strcpy($$->type_id,$1);}//函数名存放在$$->type_id
        ;

VarList:	ParamDec  					{$$=mknode(PARAM_LIST,$1,NULL,NULL,yylineno);}
			| ParamDec COMMA  VarList  	{$$=mknode(PARAM_LIST,$1,$3,NULL,yylineno);}
			;

ParamDec:	Specifier VarDec        {$$=mknode(PARAM_DEC,$1,$2,NULL,yylineno);}
			;

CompSt:	LC DefList StmList RC    	{$$=mknode(COMP_STM,$2,$3,NULL,yylineno);}
		| error RC					{$$=NULL;}	
		;
		
StmList:					{$$=NULL; }
			| Stmt StmList  {$$=mknode(STM_LIST,$1,$2,NULL,yylineno);}
			;
			
Stmt:	Exp SEMI    								{$$=mknode(EXP_STMT,$1,NULL,NULL,yylineno);}
		| CompSt      								{$$=$1;}      //复合语句结点直接最为语句结点，不再生成新的结点
		| RETURN Exp SEMI   						{$$=mknode(RETURN,$2,NULL,NULL,yylineno);}
		| IF LP Exp RP Stmt %prec LOWER_THEN_ELSE   {$$=mknode(IF_THEN,$3,$5,NULL,yylineno);}		//prec声明某个规则的优先级
		| IF LP Exp RP Stmt ELSE Stmt   			{$$=mknode(IF_THEN_ELSE,$3,$5,$7,yylineno);}
		| WHILE LP Exp RP Stmt 						{$$=mknode(WHILE,$3,$5,NULL,yylineno);}
		| FOR LP ForDec RP Stmt 					{$$=mknode(FOR,$3,$5,NULL,yylineno);}
		| BREAK SEMI								{$$=mknode(BREAK_NODE,NULL,NULL,NULL,yylineno);strcpy($$->type_id,"BREAK");}
		| CONTINUE SEMI								{$$=mknode(CONTINUE_NODE,NULL,NULL,NULL,yylineno);strcpy($$->type_id,"CONTINUE");}
		| error SEMI								{$$=NULL;}	
		;

ForDec:	Exp SEMI Exp SEMI Exp {$$=mknode(FOR_DEC,$1,$3,$5,yylineno);}
		;

DefList:					{$$=NULL; }
			| Def DefList	{$$=mknode(DEF_LIST,$1,$2,NULL,yylineno);}
			;
			
Def:	Specifier DecList SEMI	{$$=mknode(VAR_DEF,$1,$2,NULL,yylineno);}
        ;
		
DecList:	Dec					{$$=mknode(DEC_LIST,$1,NULL,NULL,yylineno);}
			| Dec COMMA DecList	{$$=mknode(DEC_LIST,$1,$3,NULL,yylineno);}
			;
			
Dec:	VarDec  				{$$=$1;}
		| VarDec ASSIGNOP Exp  	{$$=mknode(ASSIGNOP,$1,$3,NULL,yylineno);strcpy($$->type_id,"ASSIGNOP");}
		;
		
Exp:	Exp ASSIGNOP Exp	{$$=mknode(ASSIGNOP,$1,$3,NULL,yylineno);strcpy($$->type_id,"ASSIGNOP");}//$$结点type_id空置未用，正好存放运算符
		| Exp AND Exp   	{$$=mknode(AND,$1,$3,NULL,yylineno);strcpy($$->type_id,"AND");}
		| Exp OR Exp    	{$$=mknode(OR,$1,$3,NULL,yylineno);strcpy($$->type_id,"OR");}
		| Exp RELOP Exp 	{$$=mknode(RELOP,$1,$3,NULL,yylineno);strcpy($$->type_id,$2);}  //词法分析关系运算符号自身值保存在$2中
		| Exp PLUS Exp  	{$$=mknode(PLUS,$1,$3,NULL,yylineno);strcpy($$->type_id,"PLUS");}
		| Exp PLUS PLUS  	{$$=mknode(PLUS_ONE,$1,NULL,NULL,yylineno);strcpy($$->type_id,"PLUS_ONE");}
		| PLUS PLUS Exp 	{$$=mknode(ONE_PLUS,$3,NULL,NULL,yylineno);strcpy($$->type_id,"ONE_PLUS");}
		| Exp PLUS ASSIGNOP Exp 			{$$=mknode(ASSIGNOP_PLUS,$1,$4,NULL,yylineno);strcpy($$->type_id,"ASSIGNOP_PLUS");}
		| Exp MINUS Exp 					{$$=mknode(MINUS,$1,$3,NULL,yylineno);strcpy($$->type_id,"MINUS");}
		| Exp MINUS MINUS  					{$$=mknode(MINUS_ONE,$1,NULL,NULL,yylineno);strcpy($$->type_id,"MINUS_ONE");}
		| ATUO_MINUS Exp					{$$=mknode(ATUO_MINUS,$2,NULL,NULL,yylineno);strcpy($$->type_id,"ONE_MINUS");}
		| Exp MINUS ASSIGNOP Exp 			{$$=mknode(ASSIGNOP_MINUS,$1,$4,NULL,yylineno);strcpy($$->type_id,"ASSIGNOP_MINUS");}
		| Exp STAR Exp  					{$$=mknode(STAR,$1,$3,NULL,yylineno);strcpy($$->type_id,"STAR");}
		| Exp STAR ASSIGNOP Exp 			{$$=mknode(ASSIGNOP_STAR,$1,$4,NULL,yylineno);strcpy($$->type_id,"ASSIGNOP_STAR");}
		| Exp DIV Exp   					{$$=mknode(DIV,$1,$3,NULL,yylineno);strcpy($$->type_id,"DIV");}
		| Exp DIV ASSIGNOP Exp 				{$$=mknode(ASSIGNOP_DIV,$1,$4,NULL,yylineno);strcpy($$->type_id,"ASSIGNOP_DIV");}
		| LP Exp RP     					{$$=$2;}
		| MINUS Exp %prec UMINUS 			{$$=mknode(UMINUS,$2,NULL,NULL,yylineno);strcpy($$->type_id,"UMINUS");}
		| NOT Exp       					{$$=mknode(NOT,$2,NULL,NULL,yylineno);strcpy($$->type_id,"NOT");}
		| ID LP Args RP 					{$$=mknode(FUN_CALL,$3,NULL,NULL,yylineno);strcpy($$->type_id,$1);}
		| ID LP RP      					{$$=mknode(FUN_CALL,NULL,NULL,NULL,yylineno);strcpy($$->type_id,$1);}
		| Exp LB Exp RB 					{$$=mknode(EXP_ARRAY,$1,$3,NULL,yylineno);}
		| Exp DOT ID 						{$$=mknode(EXP_ELE,$1,$3,NULL,yylineno);strcpy($$->type_id,$3);}
		| ID            					{$$=mknode(ID,NULL,NULL,NULL,yylineno);strcpy($$->type_id,$1);}
		| INT           					{$$=mknode(INT,NULL,NULL,NULL,yylineno);$$->type_int=$1;$$->type=INT;}
		| FLOAT         					{$$=mknode(FLOAT,NULL,NULL,NULL,yylineno);$$->type_float=$1;$$->type=FLOAT;}
		| CHAR           					{$$=mknode(CHAR,NULL,NULL,NULL,yylineno);strcpy($$->type_char,$1);$$->type=CHAR;}
		| STRING         					{$$=mknode(STRING,NULL,NULL,NULL,yylineno);strcpy($$->type_string,$1);$$->type=STRING;}
		| error RP							{$$=NULL;}	
		;

Args:	Exp COMMA Args	{$$=mknode(ARGS,$1,$3,NULL,yylineno);}
		| Exp			{$$=mknode(ARGS,$1,NULL,NULL,yylineno);}
		;

%%

int main(int argc, char *argv[]){
	yyin=fopen(argv[1],"r");
	if (!yyin) return;
	yylineno=1;
	yyparse();
	return 0;
	}

#include<stdarg.h>
void yyerror(const char* fmt, ...)
{
    va_list ap;
    va_start(ap, fmt);
    fprintf(stderr, "Grammar Error at Line %d Column %d: ", yylloc.first_line,yylloc.first_column);
    vfprintf(stderr, fmt, ap);
    fprintf(stderr, ".\n");
}