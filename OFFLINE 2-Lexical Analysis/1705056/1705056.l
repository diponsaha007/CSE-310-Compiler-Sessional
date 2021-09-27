%option noyywrap
%x STRINGSTATE
%x SINGLECOMMENT
%x MULTICOMMENT
%{
#include<stdio.h>
#include<stdlib.h>
#include <fstream>
#include "SymbolTable.h"
using namespace std;

SymbolTable st(7);
int line_count=1;
int error_count =0;
int prvline_count;

ofstream logout;
ofstream tokenout;
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
LETTER [a-zA-Z]
DIGIT [0-9]
NEWLINE \n

%%
{WHITESPACE} {}
{NEWLINE}|"\r\n" {line_count++;}



"if"	{
			tokenout<<"<IF> ";
			logout<<"Line no "<<line_count<<": TOKEN <IF> Lexeme "<<yytext<<" found\n";
		}
		
"else"	{
			tokenout<<"<ELSE> ";
			logout<<"Line no "<<line_count<<": TOKEN <ELSE> Lexeme "<<yytext<<" found\n";
		}

"for"	{
			tokenout<<"<FOR> ";
			logout<<"Line no "<<line_count<<": TOKEN <FOR> Lexeme "<<yytext<<" found\n";	
		}

"while"	{
			tokenout<<"<WHILE> ";
			logout<<"Line no "<<line_count<<": TOKEN <WHILE> Lexeme "<<yytext<<" found\n";		
		}

"do"	{
			tokenout<<"<DO> ";
			logout<<"Line no "<<line_count<<": TOKEN <DO> Lexeme "<<yytext<<" found\n";		
		}


"break"	{
			tokenout<<"<BREAK> ";
			logout<<"Line no "<<line_count<<": TOKEN <BREAK> Lexeme "<<yytext<<" found\n";		
		}

"int"	{
			tokenout<<"<INT> ";
			logout<<"Line no "<<line_count<<": TOKEN <INT> Lexeme "<<yytext<<" found\n";		
		}

"char"	{
			tokenout<<"<CHAR> ";
			logout<<"Line no "<<line_count<<": TOKEN <CHAR> Lexeme "<<yytext<<" found\n";		
		}

"float"	{
			tokenout<<"<FLOAT> ";
			logout<<"Line no "<<line_count<<": TOKEN <FLOAT> Lexeme "<<yytext<<" found\n";		
		}

"double"	{
			tokenout<<"<DOUBLE> ";
			logout<<"Line no "<<line_count<<": TOKEN <DOUBLE> Lexeme "<<yytext<<" found\n";		
			}

"void"	{
			tokenout<<"<VOID> ";
			logout<<"Line no "<<line_count<<": TOKEN <VOID> Lexeme "<<yytext<<" found\n";		
		}

"return"	{
			tokenout<<"<RETURN> ";
			logout<<"Line no "<<line_count<<": TOKEN <RETURN> Lexeme "<<yytext<<" found\n";		
			}

"switch"	{
			tokenout<<"<SWITCH> ";
			logout<<"Line no "<<line_count<<": TOKEN <SWITCH> Lexeme "<<yytext<<" found\n";		
			}

"case"	{
			tokenout<<"<CASE> ";
			logout<<"Line no "<<line_count<<": TOKEN <CASE> Lexeme "<<yytext<<" found\n";		
			}

"default"	{
			tokenout<<"<DEFAULT> ";
			logout<<"Line no "<<line_count<<": TOKEN <DEFAULT> Lexeme "<<yytext<<" found\n";		
			}

"continue"	{
			tokenout<<"<CONTINUE> ";
			logout<<"Line no "<<line_count<<": TOKEN <CONTINUE> Lexeme "<<yytext<<" found\n";		
			}


({DIGIT}*[.]{DIGIT}*[.]{DIGIT}*){1}({DIGIT}*[.]{DIGIT}*)*(E[+-]?({DIGIT}*[.]{DIGIT}*)*)? {
			logout<<"Error at line no "<<line_count<<": Too many decimal points "<<yytext<<"\n";
			error_count++;
}

({DIGIT}+([.]{DIGIT}+)?|[.]{DIGIT}+)(E[+-]?({DIGIT}*[.]{DIGIT}*)*) {
			logout<<"Error at line no "<<line_count<<": Ill formed number "<<yytext<<"\n";
			error_count++;
}




{DIGIT}+ 	{
				tokenout<<"<CONST_INT,"<<yytext<<"> ";
				logout<<"Line no "<<line_count<<": TOKEN <CONST_INT> Lexeme "<<yytext<<" found\n";
                
				if(st.insert_symbol(yytext,"CONST_INT",logout))
                	st.PrintAllScope(logout);
}

({DIGIT}+([.]{DIGIT}+)?|[.]{DIGIT}+)(E[+-]?{DIGIT}+)? {
				tokenout<<"<CONST_FLOAT,"<<yytext<<"> ";
				logout<<"Line no "<<line_count<<": TOKEN <CONST_FLOAT> Lexeme "<<yytext<<" found\n";
                
				if(st.insert_symbol(yytext,"CONST_FLOAT",logout))
                	st.PrintAllScope(logout);
}



['][^\\\n][']|['][\\][n\\'tafrbv0]['] {
				string tmpp = yytext;
				tmpp.erase(tmpp.begin());
				tmpp.pop_back();
				tmpp = check(tmpp);
				char tmp = tmpp[0];

				

				tokenout<<"<CONST_CHAR,"<<tmp<<"> ";
				logout<<"Line no "<<line_count<<": TOKEN <CONST_CHAR> Lexeme "<<yytext<<" found "<<"--> <CONST_CHAR, "<<tmp<<">\n" ;
                
				
				if(st.insert_symbol(yytext,"CONST_CHAR",logout))
                	st.PrintAllScope(logout);
}

['][^\n][^'\n]+['] {

			logout<<"Error at line no "<<line_count<<": Multi character constant error "<<yytext<<"\n";
			error_count++;
}

[']([^'\n])|['][\\]['] {
			logout<<"Error at line no "<<line_count<<": Unterminated character "<<yytext<<"\n";
			error_count++;
}

[']['] {

			logout<<"Error at line no "<<line_count<<": Empty character constant error "<<yytext<<"\n";
			error_count++;
}

[+]|[-] {
	tokenout<<"<ADDOP,"<<yytext<<"> ";
	logout<<"Line no "<<line_count<<": TOKEN <ADDOP> Lexeme "<<yytext<<" found\n";
}

"*"|"/"|"%" {
	tokenout<<"<MULOP,"<<yytext<<"> ";
	logout<<"Line no "<<line_count<<": TOKEN <MULOP> Lexeme "<<yytext<<" found\n";
}

"++"|"--" {
	tokenout<<"<INCOP,"<<yytext<<"> ";
	logout<<"Line no "<<line_count<<": TOKEN <INCOP> Lexeme "<<yytext<<" found\n";
}

"<"|"<="|">"|">="|"=="|"!=" {
	tokenout<<"<RELOP,"<<yytext<<"> ";
	logout<<"Line no "<<line_count<<": TOKEN <RELOP> Lexeme "<<yytext<<" found\n";
}

"=" {
	tokenout<<"<ASSIGNOP,"<<yytext<<"> ";
	logout<<"Line no "<<line_count<<": TOKEN <ASSIGNOP> Lexeme "<<yytext<<" found\n";
}

"&&"|"||" {
	tokenout<<"<LOGICOP,"<<yytext<<"> ";
	logout<<"Line no "<<line_count<<": TOKEN <LOGICOP> Lexeme "<<yytext<<" found\n";
}

"!" {
	tokenout<<"<NOT,"<<yytext<<"> ";
	logout<<"Line no "<<line_count<<": TOKEN <NOT> Lexeme "<<yytext<<" found\n";
}

"(" {
	tokenout<<"<LPAREN,"<<yytext<<"> ";
	logout<<"Line no "<<line_count<<": TOKEN <LPAREN> Lexeme "<<yytext<<" found\n";
}

")" {
	tokenout<<"<RPAREN,"<<yytext<<"> ";
	logout<<"Line no "<<line_count<<": TOKEN <RPAREN> Lexeme "<<yytext<<" found\n";
}

"{" {
	tokenout<<"<LCURL,"<<yytext<<"> ";
	logout<<"Line no "<<line_count<<": TOKEN <LCURL> Lexeme "<<yytext<<" found\n";
	st.enter_scope(logout);
}

"}" {
	tokenout<<"<RCURL,"<<yytext<<"> ";
	logout<<"Line no "<<line_count<<": TOKEN <RCURL> Lexeme "<<yytext<<" found\n";
	st.exit_scope(logout);
}


"[" {
	tokenout<<"<LTHIRD,"<<yytext<<"> ";
	logout<<"Line no "<<line_count<<": TOKEN <LTHIRD> Lexeme "<<yytext<<" found\n";
}

"]" {
	tokenout<<"<RTHIRD,"<<yytext<<"> ";
	logout<<"Line no "<<line_count<<": TOKEN <RTHIRD> Lexeme "<<yytext<<" found\n";
}

"," {
	tokenout<<"<COMMA,"<<yytext<<"> ";
	logout<<"Line no "<<line_count<<": TOKEN <COMMA> Lexeme "<<yytext<<" found\n";
}

";" {
	tokenout<<"<SEMICOLON,"<<yytext<<"> ";
	logout<<"Line no "<<line_count<<": TOKEN <SEMICOLON> Lexeme "<<yytext<<" found\n";
}


[0-9]+[A-Za-z_]+[A-Za-z_0-9]* {
	logout<<"Error at line no "<<line_count<<": Invalid prefix on ID or invalid suffix on Number "<<yytext<<"\n";
	error_count++;
}

[A-Za-z_]+[A-Za-z_0-9]* {
				tokenout<<"<ID,"<<yytext<<"> ";
				logout<<"Line no "<<line_count<<": TOKEN <ID> Lexeme "<<yytext<<" found\n";
                
				if(st.insert_symbol(yytext,"ID",logout))
                	st.PrintAllScope(logout);
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
	tokenout<<"<STRING,"<<curstr<<"> ";
	logout<<"Line no "<<prvline_count<<": Token <STRING> Lexeme "<<tmp<<" found --> <STRING, "<<curstr<<">\n";
	curstr = ""; 
	BEGIN INITIAL;
}

<STRINGSTATE>[^\n] {
	curstr += yytext;
}

<STRINGSTATE>[\n]|"\r\n" {
	logout<<"Error at line no "<<prvline_count<<": Unterminated String "<<curstr<<"\n";
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
	logout<<"Line no "<<prvline_count<<": Token <COMMENT> Lexeme "<<curstr<<" found\n";
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
	logout<<"Line no "<<prvline_count<<": Token <COMMENT> Lexeme "<<curstr<<" found\n";
	curstr = ""; 
	BEGIN INITIAL;
}

<MULTICOMMENT>. {
	curstr += yytext;
}

<<EOF>> {
	if(curstr.size())
	{
		if(curstr[0]=='/'){
			if(curstr[0]=='/' && curstr[1]=='*')
			{
				int sz = curstr.size();
				if(curstr[sz-2] == '*' && curstr[sz-2] == '/' )
				{
					logout<<"Line no "<<prvline_count<<": Token <COMMENT> Lexeme "<<curstr<<" found\n";
				}
				else{
					logout<<"Error at line no "<<prvline_count<<": Unterminated Comment "<<curstr<<"\n";
					error_count++;
				}
			}
			else{
				logout<<"Line no "<<prvline_count<<": Token <COMMENT> Lexeme "<<curstr<<" found\n";
			}
		}
		else{
			logout<<"Error at line no "<<prvline_count<<": Unterminated String "<<curstr<<"\n";
			error_count++;
		}
	}
	st.PrintAllScope(logout);
	logout<<"Total lines: "<<line_count<<"\n";
	logout<<"Total errors: "<<error_count<<"\n";
	return 0;
}
. {
	string ss = yytext;
	if(ss[0]=='\'')
	{
		logout<<"Error at line no "<<line_count<<": Unterminated character "<<yytext<<"\n";
	}
	else{
		logout<<"Error at line no "<<line_count<<": Unrecognized character "<<yytext<<"\n";
	}
	error_count++;
}		

%%

int main(int argc,char *argv[]){
	
	if(argc!=2){
		printf("Please provide input file name and try again\n");
		return 0;
	}
	
	FILE *fin=fopen(argv[1],"r");
	if(fin==NULL){
		printf("Cannot open specified file\n");
		return 0;
	}
	
	logout.open("1705056_log.txt");
	tokenout.open("1705056_token.txt");
	yyin= fin;
	yylex();
	fclose(yyin);
	tokenout.close();
	logout.close();
	return 0;
}