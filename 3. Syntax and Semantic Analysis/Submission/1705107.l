%option noyywrap

%x STRING_STATE
%x COMMENT_STATE
%x MUL_COMMENT_STATE

%{
//#include<stdio.h>
#include<bits/stdc++.h>
#include "SymbolTable.h"

#define YYSTYPE SymbolInfo*
#include "y.tab.h"

using namespace std;

//SymbolTable symTable(7);
/*
FILE *tokenfile = fopen("1705107_token.txt", "w");
FILE *logfile = fopen("1705107_log.txt", "w");
*/


extern YYSTYPE yylval;
extern FILE *errorfile, *logfile;
extern SymbolTable *symT;
extern void yyerror(char *s);


int line_count=1;
int tempLineCount = 0;
int errorCount = 0;

string tokenStr, logStr, logComment;

/*void printToken(){
	string tokenName(yytext);
	string upperToken(tokenName);
	for(int i=0; i<upperToken.length(); i++){
		upperToken[i] = toupper(tokenName[i]);
	}
	fprintf(tokenfile, "<%s> ", upperToken.c_str());
	fprintf(logfile, "Line no %d: Token <%s> Lexeme %s found \n", line_count, upperToken.c_str(), yytext);
}

void printSymbolToken(string tokenType){
	string symbolName(yytext);
	fprintf(tokenfile, "<%s, %s> ", tokenType.c_str(), yytext);
	fprintf(logfile, "Line no %d: Token <%s> Lexeme %s found \n", line_count, tokenType.c_str(), yytext);
}*/

void SymbolGen(string s){
	string symbolName(yytext);
	SymbolInfo* symbol = new SymbolInfo();
	symbol->setName(symbolName);
	symbol->setType(s);
	yylval = (YYSTYPE)symbol;
}

%}


LETTER [a-zA-Z]
DIGIT [0-9]
WHITESPACE [ \t\v\r\f]+

NEWLINE [\n|\r\n]

/*KEYWORDS "if"|"else"|"for"|"while"|"do"|"break"|"int"|"char"|"float"|"double"|"void"|"return"|"switch"|"case"|"default"|"continue"*/

/* constants */
EXP ([Ee][-+]?{DIGIT}+)

INT_LITERAL {DIGIT}+

FLOAT_1 ({DIGIT}*\.{DIGIT}+{EXP}?)
FLOAT_2 ({DIGIT}+\.{DIGIT}*{EXP}?)
FLOAT_3 ({DIGIT}+{EXP}?)
FLOAT_LITERAL ({FLOAT_1}|{FLOAT_2}|{FLOAT_3})

NORMAL_CHAR '([ -~]{-}['\\])'
SPECIAL_CHAR '(\\['nt\\afrbv0\"])'
CHAR_LITERAL {NORMAL_CHAR}|{SPECIAL_CHAR}

/* Operators and Punctuators */
ADDOP [+-]
MULOP [*/%]
INCOP ("++")
DECOP ("--")
RELOP (">"|">="|"<"|"<="|"=="|"!=")
ASSIGNOP ("=")
LOGICOP ("&&"|"||")
NOT ("!")
LPAREN ("(")
RPAREN (")")
LCURL ("{")
RCURL ("}")
LTHIRD ("[")
RTHIRD ("]")
COMMA (",")
SEMICOLON (";")

/* IDENTIFIER */
IDENTIFIER ({LETTER}|_)({LETTER}|_|{DIGIT})*

/* STRING */
STRING_START (\")

/* SINGLE LINE COMMNET START*/
COMMENT_START (\/\/)
/* MultiLine COMMENT START */
MUL_COMMENT_START (\/\*)

/*** ERRORS ***/

/*Too many decimal point error*/
DEC_1 {DIGIT}*\.{DIGIT}+\.{DIGIT}*
DEC_2 {FLOAT_LITERAL}\.{DIGIT}*
DECPOINT_ERR {DEC_1}|{DEC_2}

/*Ill formed error*/
ILL_1 ({DIGIT}+[Ee]) 
ILL_2 ({DIGIT}+[Ee]{DIGIT}*\.{DIGIT}*)
ILL_ERR {ILL_1}|{ILL_2}

/*Prefix suffix error*/
PRESUF_ERR (({DIGIT})[a-zA-Z0-9_]*)

/*Multi char error*/
/*pattern:: multiple character within a '' */
CHAR_1 ([ -~]{-}['\\])
CHAR_2 (\\['nt\\afrbv0\"])
MULCHAR_ERR '(({CHAR_1}|{CHAR_2})*)'

/* Empty char error*/
EMPTY_ERR ''

/*Unfinished char error*/
UNFCHAR_ERR '(({CHAR_1}|{CHAR_2})*)|('[\\]')




%%
{NEWLINE} {line_count++;}
"if" {return IF; }
"else" {return ELSE; }
"for" {return FOR; }
"while" {return WHILE; }
"do" {return DO; }
"break" {return BREAK; }
"int" {return INT; }
"char" {return CHAR; }
"float" {return FLOAT; }
"double" {return DOUBLE; }
"void" {return VOID; }
"return" {return RETURN; }
"switch" {return SWITCH; }
"case" {return CASE; }
"default" {return DEFAULT; }
"continue" {return CONTINUE; }
"printf" {return PRINTLN; }


{ADDOP} {SymbolGen("ADDOP"); return ADDOP;}
{MULOP} {SymbolGen("MULOP"); return MULOP;}
{INCOP} {return INCOP;}\
{DECOP} {return DECOP;}
{RELOP} {SymbolGen("RELOP"); return RELOP;}
{ASSIGNOP} {return ASSIGNOP; }
{LOGICOP} {SymbolGen("LOGICOP"); return LOGICOP;}
{NOT} {return NOT; }
{LPAREN} {return LPAREN; }
{RPAREN} {return RPAREN; }
{LCURL} {return LCURL; }
{RCURL} {return RCURL; }
{LTHIRD} {return LTHIRD; }
{RTHIRD} {return RTHIRD; }
{COMMA} {return COMMA; }
{SEMICOLON} {return SEMICOLON; }


{INT_LITERAL} {SymbolGen("CONST_INT"); return CONST_INT;}

{FLOAT_LITERAL} {SymbolGen("CONST_FLOAT"); return CONST_FLOAT;}

{CHAR_LITERAL} {SymbolGen("CONST_CHAR"); return CONST_CHAR;}

{IDENTIFIER} {SymbolGen("ID"); return ID;}





{STRING_START} {
	tokenStr = "";
	logStr = "\"";
	tempLineCount = 0;
	BEGIN STRING_STATE;	
}
<STRING_STATE>\\n {
	logStr += "\\n";
	tokenStr += "\n";
}
<STRING_STATE>\\t {
	logStr += "\\t";
	tokenStr += "\t";
}
<STRING_STATE>\\\\ {
	logStr += "\\\\";
	tokenStr += "\\";
}
<STRING_STATE>\\\' {
	logStr += "\\\'";
	tokenStr += "\'";
}
<STRING_STATE>\\\" {
	logStr += "\\\"";
	tokenStr += "\"";
}
<STRING_STATE>\\a {
	logStr += "\\a";
	tokenStr += "\a";
}
<STRING_STATE>\\f {
	logStr += "\\f";
	tokenStr += "\f";
}
<STRING_STATE>\\r {
	logStr += "\\r";
	tokenStr += "\r";
}
<STRING_STATE>\\b {
	logStr += "\\b";
	tokenStr += "\b";
}
<STRING_STATE>\\v {
	logStr += "\\v";
	tokenStr += "\v";
}
<STRING_STATE>\\0 {
	logStr += "\\0";
	tokenStr += "\0";
}
<STRING_STATE>\\[\r]?[\n] {
	/*handles multiline string with a slash*/
	tempLineCount++;
	string temp(yytext);
	logStr+= temp;
}
<STRING_STATE>[\r]?[\n] {
	/*error: multiline string without putting a slash-> unfinished string*/
	tempLineCount++;
	errorCount++;
	/*
	fprintf(logfile, "Error at line no %d : Unterminated String %s \n", line_count, logStr.c_str());
	*/
	line_count = line_count + tempLineCount;
	tempLineCount = 0;
	logStr = "";
	tokenStr = "";
	BEGIN INITIAL;
}
<STRING_STATE>\" {
	/*String terminated*/
	logStr += "\"";
	/*
	fprintf(tokenfile, "<STRING, \"%s\"> ", tokenStr.c_str());
	fprintf(logfile, "Line no %d: Token <STRING> Lexeme %s found --> <STRING, %s> \n", line_count, logStr.c_str(), tokenStr.c_str());
	*/
	line_count = line_count + tempLineCount;
	tempLineCount = 0;
	logStr = "";
	tokenStr = "";
	BEGIN INITIAL;
}
<STRING_STATE>.  {
	/*any normal character*/
	logStr += yytext;
	tokenStr += yytext;
}





{COMMENT_START} {
	logComment = "//";
	tempLineCount = 0;
	BEGIN COMMENT_STATE;
}
<COMMENT_STATE>\\[\r]?[\n] {
	/*handles multiline comment with a slash and enter*/
	
	tempLineCount++;
	string temp(yytext);
	logComment += temp;
	//logStr+= temp;
}
<COMMENT_STATE>[\r]?[\n] {
	/*A new line (without slash-> end of single line comment)*/
	
	tempLineCount++;
	/*errorCount++;
	fprintf(logfile, "Error at line no %d : Unterminated String %s \n", line_count, logStr.c_str());*/
	/*
	fprintf(logfile, "Line no %d: Token <COMMENT> Lexeme %s found\n", line_count, logComment.c_str());
	*/
	line_count = line_count + tempLineCount;
	logComment = "";
	tempLineCount = 0;
	BEGIN INITIAL;
}
<COMMENT_STATE>. {
	logComment += yytext;
}




{MUL_COMMENT_START} {
	logComment = "/*";
	tempLineCount = 0;
	BEGIN MUL_COMMENT_STATE;
}
<MUL_COMMENT_STATE>[^*\n]+ { 
	string temp(yytext);
	logComment += temp;
}
<MUL_COMMENT_STATE>"*" {
	string temp(yytext);
	logComment += temp;
}
<MUL_COMMENT_STATE>[\r]?[\n] {
	/*new comment line*/
	string temp(yytext);
	logComment += temp;
	tempLineCount++;
}
<MUL_COMMENT_STATE>\*\/ {
	/*end of comment*/
	string temp(yytext);
	logComment += temp;
	/*
	fprintf(logfile, "Line no %d: Token <COMMENT> Lexeme %s found\n", line_count, logComment.c_str());
	*/
	logComment = "";
	line_count = line_count + tempLineCount;
	tempLineCount = 0;
	BEGIN INITIAL;
}
<MUL_COMMENT_STATE><<EOF>> {
	errorCount++;
	/*
	fprintf(logfile, "Error at line no %d: Unfinished Comment %s\n", line_count, logComment.c_str());
	*/
	logComment = "";
	line_count = line_count + tempLineCount;
	tempLineCount = 0;
	BEGIN INITIAL;
}





{ILL_ERR} {
	fprintf(logfile, "Error at line no %d: Ill formed Number Error %s \n", line_count, yytext);
	fprintf(errorfile, "Error at line no %d: Ill formed Number Error %s \n", line_count, yytext);
        errorCount++;
}
{DECPOINT_ERR} {
        fprintf(logfile, "Error at line no %d: Too many decimal points Error %s \n", line_count, yytext);
		fprintf(errorfile, "Error at line no %d: Too many decimal points Error %s \n", line_count, yytext);
        errorCount++;
}
{PRESUF_ERR} {
	fprintf(logfile, "Error at line no %d: Invalid Suffix on numeric constant or invalid prefix on identifier Error %s \n", line_count, yytext);
	fprintf(errorfile, "Error at line no %d: Invalid Suffix on numeric constant or invalid prefix on identifier Error %s \n", line_count, yytext);
        errorCount++;
}
{EMPTY_ERR} {
	fprintf(logfile, "Error at line no %d: Empty character constant Error %s \n", line_count, yytext);
	fprintf(errorfile, "Error at line no %d: Empty character constant Error %s \n", line_count, yytext);
        errorCount++;
}
{MULCHAR_ERR} {
	fprintf(logfile, "Error at line no %d: Multi character constant Error %s \n", line_count, yytext);
	fprintf(errorfile, "Error at line no %d: Multi character constant Error %s \n", line_count, yytext);
        errorCount++;
}
{UNFCHAR_ERR} {
	fprintf(logfile, "Error at line no %d: Unfinished character Error %s \n", line_count, yytext);
	fprintf(errorfile, "Error at line no %d: Unfinished character Error %s \n", line_count, yytext);
        errorCount++;
}

{WHITESPACE} {}
<<EOF>> {
		if( logStr.size() > 0 ) {
			fprintf(logfile, "Error at line no %d: Unterminated String %s\n", line_count, logStr.c_str());
			fprintf(errorfile, "Error at line no %d: Unterminated String %s\n", line_count, logStr.c_str());
			logStr = "";
			errorCount++;
			line_count = line_count + tempLineCount;
			tempLineCount = 0;
		}
        else if(logComment.size() > 0){
			/*
        	fprintf(logfile, "Line no %d: Token <COMMENT> Lexeme %s found\n", line_count, logComment.c_str());
			*/
        	logComment = "";
        	line_count = line_count + tempLineCount;
		tempLineCount = 0;
        }
        return 0;
}

. {
	fprintf(logfile, "Error at line no %d: Unrecognized character %s\n", line_count, yytext);
	fprintf(errorfile, "Error at line no %d: Unrecognized character %s\n", line_count, yytext);
	errorCount++;
}

%%
