%option noyywrap
%x STRINGSTATE
%x SINGLECOMMENT
%x MULTICOMMENT
%{
#include<cstdio>
#include<cstdlib>
#include<iostream>
#include <fstream>
#include "SymbolTable.h"
#include "y.tab.h"


using namespace std;

extern SymbolTable table;
//extern YYSTYPE yylval;
void yyerror(char *);

int line_count=1;
int error_count =0;
int prvline_count;

extern ofstream logout;
extern ofstream error;

string curstr;

string check(string s)
{
	string ret = "";
	for(int i=0;i<s.size();)
	{
		char tmp ; 
		if(i+1<s.size() && s[i] == '\\' && s[i+1]=='\n')
		{
			i+=2;
			continue;
		}
		else if(i+1<s.size() && s[i] == '\\' && s[i+1]=='n')
		{
			tmp = '\n';
			i+=2;
		}
		else if(i+1<s.size() && s[i] == '\\' && s[i+1]=='\\')
		{
			tmp = '\\';
			i+=2;
		}
		else if(i+1<s.size() && s[i] == '\\' && s[i+1]=='\'')
		{
			tmp = '\'';
			i+=2;
		}
		else if(i+1<s.size() && s[i] == '\\' && s[i+1]=='t')
		{
			tmp = '\t';
			i+=2;
		}
		else if(i+1<s.size() && s[i] == '\\' && s[i+1]=='a')
		{
			tmp = '\a';
			i+=2;
		}
		else if(i+1<s.size() && s[i] == '\\' && s[i+1]=='f')
		{
			tmp = '\f';
			i+=2;
		}
		else if(i+1<s.size() && s[i] == '\\' && s[i+1]=='r')
		{
			tmp = '\r';
			i+=2;
		}
		else if(i+1<s.size() && s[i] == '\\' && s[i+1]=='b')
		{
			tmp = '\b';
			i+=2;
		}
		else if(i+1<s.size() && s[i] == '\\' && s[i+1]=='v')
		{
			tmp = '\v';
			i+=2;
		}
		else if(i+1<s.size() && s[i] == '\\' && s[i+1]=='0')
		{
			tmp = '\0';
			i+=2;
		}
		else if(i+1<s.size() && s[i] == '\\' && s[i+1]=='\"')
		{
			tmp = '\"';
			i+=2;
		}
		else{
			tmp = s[i];
			i+=1;
		}
		ret += tmp;

		
	}
	return ret;
}

%}

WHITESPACE [ \t\f\r\v]+ 
DIGIT [0-9]
NEWLINE \n

%%
{WHITESPACE} {}
{NEWLINE}|"\r\n" {line_count++;}



"if"	{
			return IF;
		}
		
"else"	{
			return ELSE;
		}

"for"	{
			return FOR;
		}

"while"	{
			return WHILE;
		}

"int"	{
			return INT;
		}

"float"	{
			return FLOAT;
		}

"void"	{
			return VOID;
		}

"return"	{
				return RETURN;
			}

"printf"	{
				return PRINTLN;
			}
"println"	{
				return PRINTLN;
			}


({DIGIT}*[.]{DIGIT}*[.]{DIGIT}*){1}({DIGIT}*[.]{DIGIT}*)*(E[+-]?({DIGIT}*[.]{DIGIT}*)*)? {
			logout<<"Error at line no "<<line_count<<": Too many decimal points "<<yytext<<"\n";
			error<<"Error at line no "<<line_count<<": Too many decimal points "<<yytext<<"\n";
			error_count++;
}

({DIGIT}+([.]{DIGIT}+)?|[.]{DIGIT}+)(E[+-]?({DIGIT}*[.]{DIGIT}*)*) {
			logout<<"Error at line no "<<line_count<<": Ill formed number "<<yytext<<"\n";
			error<<"Error at line no "<<line_count<<": Ill formed number "<<yytext<<"\n";
			error_count++;
}




{DIGIT}+ 	{
				SymbolInfo *s= new  SymbolInfo(yytext, "CONST_INT");
				yylval.symbol = s;
				return CONST_INT;
}

({DIGIT}+([.]{DIGIT}+)?|[.]{DIGIT}+)(E[+-]?{DIGIT}+)? {
				SymbolInfo *s= new  SymbolInfo(yytext, "CONST_FLOAT");
				yylval.symbol = s;
				return CONST_FLOAT; 
}





['][^\n][^'\n]+['] {
			logout<<"Error at line no "<<line_count<<": Multi character constant error "<<yytext<<"\n";
			error<<"Error at line no "<<line_count<<": Multi character constant error "<<yytext<<"\n";
			error_count++;
}

[']([^'\n])|['][\\]['] {
			logout<<"Error at line no "<<line_count<<": Unterminated character "<<yytext<<"\n";
			error<<"Error at line no "<<line_count<<": Unterminated character "<<yytext<<"\n";
			error_count++;
}

[']['] {
		logout<<"Error at line no "<<line_count<<": Empty character constant error "<<yytext<<"\n";
		error<<"Error at line no "<<line_count<<": Empty character constant error "<<yytext<<"\n";
		error_count++;
}

[+]|[-] {
			SymbolInfo *s= new  SymbolInfo(yytext, "ADDOP");
			yylval.symbol = s;
			return ADDOP;
}

"*"|"/"|"%" {
			SymbolInfo *s= new  SymbolInfo(yytext, "MULOP");
			yylval.symbol = s;
			return MULOP;
}

"++" 	{
			return INCOP;
}

"--" 	{
			return DECOP;
}

"<"|"<="|">"|">="|"=="|"!=" {
			SymbolInfo *s= new  SymbolInfo(yytext, "RELOP");
			yylval.symbol = s;
			return RELOP;
}

"=" {
			return ASSIGNOP;
}

"&&"|"||" {
			SymbolInfo *s= new  SymbolInfo(yytext, "LOGICOP");
			yylval.symbol = s;
			return LOGICOP;
}

"!" {
			return NOT;
}

"(" {
			return LPAREN;
}

")" {
			return RPAREN;
}

"{" 	{
	return LCURL;
}

"}" 	{
	return RCURL;
}

"[" 	{
	return LTHIRD;
}

"]" 	{
	return RTHIRD;
}

"," {
	return COMMA;
}

";" {
	return SEMICOLON;
}


[0-9]+[A-Za-z_]+[A-Za-z_0-9]* {
	logout<<"Error at line no "<<line_count<<": Invalid prefix on ID or invalid suffix on Number "<<yytext<<"\n";
	error<<"Error at line no "<<line_count<<": Invalid prefix on ID or invalid suffix on Number "<<yytext<<"\n";
	error_count++;
}

[A-Za-z_]+[A-Za-z_0-9]* {
				SymbolInfo *s= table.LookUp(yytext);
				if(s==NULL)
				{					
					s= new SymbolInfo(yytext, "ID");
				}
				yylval.symbol = s;
				return ID;
}

"\"" {
	curstr = "";
	curstr += yytext;
	prvline_count = line_count;
	BEGIN STRINGSTATE;
}
<STRINGSTATE>"\\\n"|"\\\r\n" {
	curstr += yytext;
	line_count++;
}

<STRINGSTATE>"\\\"" {
	curstr += yytext;
}

<STRINGSTATE>"\"" {
	curstr += yytext;
	string tmp = curstr;
	curstr = check(curstr);
	curstr = ""; 
	BEGIN INITIAL;
}

<STRINGSTATE>[^\n] {
	curstr += yytext;
}

<STRINGSTATE>[\n]|"\r\n" {
	logout<<"Error at line no "<<prvline_count<<": Unterminated String "<<curstr<<"\n";
	error<<"Error at line no "<<prvline_count<<": Unterminated String "<<curstr<<"\n";
	line_count++;
	error_count++;
	curstr = "";
	BEGIN INITIAL;

}

"//" {
	curstr = "";
	prvline_count = line_count;
	curstr += yytext;
	BEGIN SINGLECOMMENT;
}

<SINGLECOMMENT>"\\\n"|"\\\r\n" {
	curstr += yytext;
	line_count++;
}

<SINGLECOMMENT>"\n"|"\r\n" {
	line_count++;
	curstr = ""; 
	BEGIN INITIAL;
}

<SINGLECOMMENT>. {
	curstr += yytext;
}

"/*" {
	curstr = "";
	prvline_count = line_count;
	curstr += yytext;
	BEGIN MULTICOMMENT;
}

<MULTICOMMENT>"\n"|"\r\n" {
	line_count++;
	curstr+= yytext;
}

<MULTICOMMENT>"*/" {
	curstr += yytext;
	curstr = ""; 
	BEGIN INITIAL;
}

<MULTICOMMENT>. {
	curstr += yytext;
}


. {
	string ss = yytext;
	if(ss[0]=='\'')
	{
		logout<<"Error at line no "<<line_count<<": Unterminated character "<<yytext<<"\n";
		error<<"Error at line no "<<line_count<<": Unterminated character "<<yytext<<"\n";
	}
	else{
		logout<<"Error at line no "<<line_count<<": Unrecognized character "<<yytext<<"\n";
		error<<"Error at line no "<<line_count<<": Unrecognized character "<<yytext<<"\n";
	}
	error_count++;
}
%%

