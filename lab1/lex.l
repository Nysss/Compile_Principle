%{
#include "string.h"
#include "parser.tab.h"
#include "def.h"

int yycolumn=1;
#define YY_USER_ACTION    	yylloc.first_line=yylloc.last_line=yylineno; \
	yylloc.first_column=yycolumn;	yylloc.last_column=yycolumn+yyleng-1; yycolumn+=yyleng;

//其中first_line和first_column表示该语法单元第一个单词出现的行号和列号，last_line和last_column表示该语法单元最后一个单词出现的行号和列号

typedef union {
		int 	type_int;
		int 	type_float;
		char 	type_char[3];
		char 	type_string[31];
		char 	type_id[32];
		struct 	node *ptr;
	} YYLVAL;
	#define YYSTYPE YYLVAL
	//yylval用来保存单词属性，默认int，修改成YYLVAL

%}

%option yylineno

id 		[_A-Za-z][A-Za-z0-9]*
int 	[+-]?[0-9]+
float 	[-+]?[0-9]*\.?[0-9]*?([eE][-+]?[0-9]+)?
char 	'([a-zA-Z0-9])'
string 	(\"[A-Za-z0-9]*\")

%%
"+"			{return PLUS;}
"-"			{return MINUS;}
"."         {return DOT;}
{int}  		{yylval.type_int = atoi(yytext);	return INT;}
{float}		{yylval.type_float = atof(yytext); 	return FLOAT;}
{char}		{strcpy(yylval.type_char, yytext);	return CHAR;}
{string}    {strcpy(yylval.type_string,yytext);	return STRING;}

"int"		{strcpy(yylval.type_id, yytext);		return TYPE;}
"float"		{strcpy(yylval.type_id, yytext);		return TYPE;}
"char"		{strcpy(yylval.type_id, yytext);		return TYPE;}
"string"    {strcpy(yylval.type_id, yytext);		return TYPE;}

"struct"	{return STRUCT;}
"return"	{return RETURN;}
"if"		{return IF;}	
"else"	 	{return ELSE;}
"while"		{return WHILE;}
"for"       {return FOR;}
"break"		{return BREAK;}
"continue"	{return CONTINUE;}


{id}       	{strcpy(yylval.type_id, yytext); return ID;/*由于关键字的形式也符合表示符的规则，所以把关键字的处理全部放在标识符的前面，优先识别*/}
";"			{return SEMI;}
","			{return COMMA;}
">"|"<"|">="|"<="|"=="|"!=" {strcpy(yylval.type_id, yytext);return RELOP;}
"="			{return ASSIGNOP;}
"*"			{return STAR;}
"--"		{return ATUO_MINUS;}
"/"			{return DIV;}
"&&"        {return AND;}
"||"        {return OR;}
"!"			{return NOT;}
"("			{return LP;}
")"			{return RP;}
"["         {return LB;}
"]"         {return RB;}
"{"			{return LC;}
"}"			{return RC;}
[\n]        {yycolumn=1;}			
[ \r\t]     {}   
"//"[^\n]*  		{/* 注释 */}
"/*"(.|\n)*"*/"		{/* 注释 */}
.		{printf("Error type A at Line %d: Mysterious characters \'%s\'\n",yylineno, yytext);}
%%

/* 和bison联用时，不需要这部分
void main()
{
yylex();
return 0;
}

*/
int yywrap()
{
return 1;
}