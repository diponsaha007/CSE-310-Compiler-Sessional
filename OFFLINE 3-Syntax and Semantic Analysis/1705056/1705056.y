%{
#include <iostream>
#include <fstream>
#include <map>
#include "SymbolTable.h"
//#define YYSTYPE SymbolInfo*
using namespace std;

int yyparse(void);
int yylex(void);

extern FILE *yyin;
FILE *fp;
ofstream logout;
ofstream error;



extern int line_count;
extern int error_count;
SymbolTable table(30);

struct func_skeletons{
	string func_name;
	vector<string>argtypes;
	string return_type;
};


map<string , func_skeletons>mp; //this is to keep track of all functions

SymbolTable vartype(30); //this is to keep track of variable types found; 
SymbolTable isarray(30); //this is to check if a variable is an array


string parameter_id; //function parameter ids
string parameter_type; // function parameters data type

string curfunc_type; // return type of current function




void yyerror(string s)
{
	//write your code
	error<<"Error at line "<<line_count<<": "<<s<<"\n";
	logout<<"Error at line "<<line_count<<": "<<s<<"\n";
	error_count++;
}
void same(func_skeletons a , func_skeletons b)
{
	if(a.func_name != b.func_name)
		return;
	if(a.return_type != b.return_type)
	{
		yyerror("Return type mismatch with function declaration in function "+a.func_name);
		return;
	}
	if(a.argtypes.size() != b.argtypes.size())
	{
		yyerror("Total number of arguments mismatch with declaration in function "+a.func_name);
		return;
	}
	for(int i=0;i<a.argtypes.size();i++)
	{
		if(a.argtypes[i] != b.argtypes[i])
		{
			string tmp = to_string(i+1);
			yyerror(tmp+"th argument mismatch with declaration in function "+a.func_name);
			return;
		}
	}
}
void insert_function(string name , string types , string return_type)
{
	
	vector<string>p;
	for(int i=0;i<types.size();i++)
    {
        if(types.substr(i,3)=="int")
        {
            p.push_back("int");
        }
        if(types.substr(i,5)=="float")
        {
            p.push_back("float");
        }
    }
    func_skeletons f = {name , p , return_type};
	if(mp.count(name))
	{
		same(mp[name] , f);
	}
	else{
    	mp[name] = f;
	}
	if(vartype.LookUp(name))
	{
		yyerror("Multiple declaration of "+name);
	}
}

bool zero(string s)
{
	for(int i=0;i<s.size();i++)
	{
		if(s[i]!='0')
			return false;
	}
	return true;
}

void consistent(string name, string s)
{
	vector<string>p;
	for(int i=0;i<s.size();i++)
    {
        if(s.substr(i,3)=="int")
        {
            p.push_back("int");
        }
        if(s.substr(i,5)=="float")
        {
            p.push_back("float");
        }
    }
	func_skeletons f = mp[name];

	if(f.argtypes.size()!= p.size())
	{
		yyerror("Total number of arguments mismatch with declaration in function "+name);
		return;
	}
	for(int i=0;i<f.argtypes.size();i++)
	{
		if(f.argtypes[i]=="float" && p[i]=="int")
			continue;
		if(f.argtypes[i]!=p[i])
		{
			string tmp = to_string(i+1);
			yyerror(tmp+"th argument mismatch in function "+name);
			return;
		}
	}
}
vector<string> tokens(string s)
{
	vector<string>p;
    string now = "";
    for(int i=0; i<s.size(); i++)
    {
        if(s[i]==' ')
        {
            if(now.size())
                p.push_back(now);
            now = "";
        }
        else
        {
            now += s[i];
        }
    }
    if(now.size())
        p.push_back(now);
	return p;
}

bool check_int(string s)
{
	for(int i=0;i<s.size();i++)
	{
		if(s[i]>='0' && s[i]<='9')
		{

		}
		else{
			return false;
		}
	}
	return true;
}

void parse_variables(string s, string type)
{
	vector<string>p;
    string now = "";
    for(int i=0; i<s.size(); i++)
    {
        if(s[i]==',')
        {
            if(now.size())
                p.push_back(now);
            now = "";
        }
        else if(s[i]=='[')
        {
            while(i<s.size() && s[i]!=']')
            {
                i++;
            }
        }
        else
        {
            now += s[i];
        }
    }
    if(now.size())
        p.push_back(now);
	for(auto it:p)
	{
		vartype.insert_symbol(it, type);
	}
}

%}
%union{
	SymbolInfo *symbol;
}
%token IF ELSE FOR WHILE DO BREAK INT CHAR FLOAT DOUBLE VOID RETURN SWITCH CASE DEFAULT CONTINUE PRINTLN CONST_CHAR
%token   INCOP DECOP  ASSIGNOP  NOT LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD COMMA SEMICOLON


%token<symbol>ID CONST_INT CONST_FLOAT LOGICOP MULOP RELOP ADDOP
%type<symbol>start program unit func_declaration func_definition parameter_list compound_statement var_declaration type_specifier
%type<symbol>declaration_list statements statement expression_statement variable logic_expression rel_expression simple_expression
%type<symbol>term unary_expression factor argument_list arguments expression
%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE




%%

start : program
	{
		//write your code in this block in all the similar blocks below
		logout<<"Line "<<line_count<<": "<<" start : program\n\n";
		// string now = $1->getName();
		// $$ = new SymbolInfo(now , "start");
		// logout<<now<<"\n\n";
	}
	;

program : program unit
	{
		logout<<"Line "<<line_count<<": "<<" program : program unit\n\n";
		string now = $1->getName()+"\n"+$2->getName();
		$$ = new SymbolInfo(now , "program");
		logout<<now<<"\n\n";
	}
	| unit
	{
		logout<<"Line "<<line_count<<": "<<" program : unit\n\n";
		string now = $1->getName();
		$$ = new SymbolInfo(now , "program");
		logout<<now<<"\n\n";
	}
	;
	
unit : var_declaration
		{
			logout<<"Line "<<line_count<<": "<<" unit : var_declaration\n\n";
			string now = $1->getName();
			$$ = new SymbolInfo(now , "unit");
			logout<<now<<"\n\n";
		}
     | func_declaration
	 {
			logout<<"Line "<<line_count<<": "<<" unit : func_declaration\n\n";
			string now = $1->getName();
			$$ = new SymbolInfo(now , "unit");
			logout<<now<<"\n\n";
 
	 }
     | func_definition
	 {
		 	logout<<"Line "<<line_count<<": "<<" unit : func_definition\n\n";
			string now = $1->getName();
			$$ = new SymbolInfo(now , "unit");
			logout<<now<<"\n\n";
	 }
     ;
     

func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON
		{
			parameter_id = "";
			logout<<"Line "<<line_count<<": "<<" func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON\n\n";
			string now = $1->getName() + " " + $2->getName() + "(" + $4->getName() + ");";
			$$ = new SymbolInfo(now , "func_declaration");
			logout<<now<<"\n\n";
			table.insert_symbol($2->getName() , "ID");

			insert_function($2->getName() , $4->getName() , $1->getName());
		}
		| type_specifier ID LPAREN RPAREN SEMICOLON
		{
			logout<<"Line "<<line_count<<": "<<" func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON\n\n";
			string now = $1->getName() + " " + $2->getName() + "();";
			$$ = new SymbolInfo(now , "func_declaration");
			logout<<now<<"\n\n";
			table.insert_symbol($2->getName() , "ID");

			insert_function($2->getName() , "" , $1->getName());
		}
		;
		 
func_definition : type_specifier ID LPAREN  parameter_list RPAREN {table.insert_symbol($2->getName() , "ID");curfunc_type = $1->getName();insert_function($2->getName() , $4->getName() , $1->getName());}  compound_statement
		{
			logout<<"Line "<<line_count<<": "<<" func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement\n\n";
			string now = $1->getName() + " "+$2->getName() + "("+$4->getName() +")"+$7->getName();
			logout<<now<<"\n\n";
			$$ = new SymbolInfo(now , "func_definition");

			
		}
		| type_specifier ID LPAREN RPAREN {table.insert_symbol($2->getName() , "ID");curfunc_type = $1->getName();insert_function($2->getName() , "" , $1->getName());} compound_statement
		{
			logout<<"Line "<<line_count<<": "<<" func_definition : type_specifier ID LPAREN RPAREN compound_statement\n\n";
			string now = $1->getName() + " "+$2->getName() + "("+")"+$6->getName();
			logout<<now<<"\n\n";
			$$ = new SymbolInfo(now , "func_definition");

			
		}
 		;



parameter_list  : parameter_list COMMA type_specifier ID
		{
			logout<<"Line "<<line_count<<": "<<" parameter_list : parameter_list COMMA type_specifier ID\n\n";
			string now = $1->getName() + "," + $3->getName() +" "+ $4->getName();
			$$ = new SymbolInfo(now , "parameter_list");
			logout<<now<<"\n\n";

			if($3->getName()=="void")
			{
				yyerror("void cannot be a variable type");
			}
			else{
				parameter_id +=" "+$4->getName();
				parameter_type += " "+$3->getName();
			}
		}
		| parameter_list COMMA type_specifier
		{
			logout<<"Line "<<line_count<<": "<<" parameter_list : parameter_list COMMA type_specifier\n\n";
			string now = $1->getName() + "," + $3->getName();
			$$ = new SymbolInfo(now , "parameter_list");
			logout<<now<<"\n\n";

		}
 		| type_specifier ID
		 {
			logout<<"Line "<<line_count<<": "<<" parameter_list : type_specifier ID\n\n";
			string now = $1->getName() +" "+ $2->getName();
			$$ = new SymbolInfo(now , "parameter_list");
			logout<<now<<"\n\n";

			if($1->getName()=="void")
			{
				yyerror("void cannot be a variable type");
			}
			else{
				parameter_id +=" "+$2->getName();
				parameter_type += " "+$1->getName();
			}
		 }
		| type_specifier
		{
			logout<<"Line "<<line_count<<": "<<" parameter_list : type_specifier\n\n";
			string now = $1->getName();
			$$ = new SymbolInfo(now , "parameter_list");
			logout<<now<<"\n\n";
		}
 		;

 		
compound_statement : LCURL enter_new_scope statements RCURL
			{
				logout<<"Line "<<line_count<<": "<<" compound_statement : LCURL statements RCURL\n\n";
				string now = "{\n" + $3->getName() +"\n}";
				$$ = new SymbolInfo(now , "compound_statement");
				logout<<now<<"\n\n";
				table.PrintAllScope(logout);
				table.exit_scope(logout);

				vartype.exit_scope(logout,false);
				isarray.exit_scope(logout , false);
			}
 		    | LCURL enter_new_scope RCURL
			 {
				logout<<"Line "<<line_count<<": "<<" compound_statement : LCURL RCURL\n\n";
				string now = "{\n}" ;
				$$ = new SymbolInfo(now , "compound_statement");
				logout<<now<<"\n\n";
				table.PrintAllScope(logout);
				table.exit_scope(logout);
				vartype.exit_scope(logout,false);
				isarray.exit_scope(logout , false);
			 }
 		    ;
enter_new_scope : 
			{
				table.enter_scope(logout);
				vartype.enter_scope(logout,false);
				isarray.enter_scope(logout, false);
				vector<string>p = tokens(parameter_id);
				vector<string>q = tokens(parameter_type);
				for(string i:p)
				{
					if(!table.insert_symbol(i, "ID"))
					{
						yyerror("Multiple declaration of "+ i +" in parameter");
					}
				}
				for(int i=0;i<p.size();i++)
				{
					vartype.insert_symbol(p[i] , q[i]);
				}
				parameter_id = "";
				parameter_type = "";
			}
			
var_declaration : type_specifier declaration_list SEMICOLON
				{
					logout<<"Line "<<line_count<<": "<<" var_declaration : type_specifier declaration_list SEMICOLON\n\n";
					string now = $1->getName() + " " + $2->getName() + ";";
					$$ = new SymbolInfo(now , "var_declaration");
					logout<<now<<"\n\n";


					//type_specifier must not be void
					if($1->getName()=="void")
					{
						yyerror("Variable type cannot be void");
					}
					else{
						parse_variables($2->getName(),$1->getName());
					}
				}
 		 ;
 		 
type_specifier	: INT
				{
					logout<<"Line "<<line_count<<": "<<" type_specifier : INT\n\n";
					logout<<"int\n\n";
					$$ = new SymbolInfo("int"  , "type_specifier");
				}
 		| FLOAT
		 {
			    logout<<"Line "<<line_count<<": "<<" type_specifier : FLOAT\n\n";
				logout<<"float\n\n";
				$$ = new SymbolInfo("float"  , "type_specifier");
		 }
 		| VOID
		 {
				logout<<"Line "<<line_count<<": "<<" type_specifier : VOID\n\n";
				logout<<"void\n\n";
				$$ = new SymbolInfo("void"  , "type_specifier");
		 }
 		;



declaration_list : declaration_list COMMA ID
		{
			logout<<"Line "<<line_count<<": "<<" declaration_list : declaration_list COMMA ID\n\n";
			string now = $1->getName() + "," + $3->getName();
			logout<<now<<"\n\n";
			$$ = new SymbolInfo(now, "declaration_list");

			if(!table.insert_symbol($3->getName() , "ID"))
			{
				yyerror("Multiple Declaration of " + $3->getName() );
			}

		}
 		  | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
		   {
			    logout<<"Line "<<line_count<<": "<<" declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD\n\n";
				string now = $1->getName() + "," + $3->getName() +"[" + $5->getName() + "]";
				logout<<now<<"\n\n";
				$$ = new SymbolInfo(now, "declaration_list");

				if(!table.insert_symbol($3->getName() , "ID"))
				{
					yyerror("Multiple Declaration of " + $3->getName() );
				}
				else{
					isarray.insert_symbol($3->getName() , "1");
				}
		   }

 		  | ID
		   {
			   	logout<<"Line "<<line_count<<": "<<" declaration_list : ID\n\n";
				logout<<$1->getName()<<"\n\n";
				$$ = new SymbolInfo($1->getName(), "declaration_list");

				if(!table.insert_symbol($1->getName() , "ID"))
				{
					yyerror("Multiple Declaration of " + $1->getName() );
				}
		   }
 		  | ID LTHIRD CONST_INT RTHIRD
		   {
			    logout<<"Line "<<line_count<<": "<<" declaration_list : ID LTHIRD CONST_INT RTHIRD\n\n";
				string id = $1->getName();
				string num = $3->getName();
				string now = id + "[" + num + "]";
				logout<<now<<"\n\n";
				$$ = new SymbolInfo(now, "declaration_list");

				if(!table.insert_symbol($1->getName() , "ID"))
				{
					yyerror("Multiple Declaration of " + $1->getName() );
				}
				else{
					isarray.insert_symbol($1->getName() , "1");
				}
		   }
 		  ;
 		  
statements : statement
		{
			logout<<"Line "<<line_count<<": "<<" statements : statement\n\n";
			$$ = new SymbolInfo($1->getName() , "statements");
			logout<<$1->getName()<<"\n\n";

		}
	   | statements statement
	   {
		   	logout<<"Line "<<line_count<<": "<<" statements : statements statement\n\n";
			string now = $1->getName() + "\n" + $2->getName();
			$$ = new SymbolInfo(now , "statements");
			logout<<now<<"\n\n";
	   }
	   ;
	   
statement : var_declaration
		{
			logout<<"Line "<<line_count<<": "<<" statement : var_declaration\n\n";
			string now = $1->getName();
			$$ = new SymbolInfo(now , "statement");
			logout<<now<<"\n\n";
		}
	  | expression_statement
	  {
		  	logout<<"Line "<<line_count<<": "<<" statement : expression_statement\n\n";
			string now = $1->getName();
			$$ = new SymbolInfo(now , "statement");
			logout<<now<<"\n\n";
	  }
	  | compound_statement
	  {
		  	logout<<"Line "<<line_count<<": "<<" statement : compound_statement\n\n";
			string now = $1->getName();
			$$ = new SymbolInfo(now , "statement");
			logout<<now<<"\n\n";
	  }
	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement
	  {
		  	logout<<"Line "<<line_count<<": "<<" statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement\n\n";
			string now = "for(" + $3->getName() + $4->getName() + $5->getName() + ")" + $7->getName();

			$$ = new SymbolInfo(now , "statement");
			logout<<now<<"\n\n";
	  }
	  | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE
	  {
		  	logout<<"Line "<<line_count<<": "<<" statement : IF LPAREN expression RPAREN statement\n\n";
			string now = "if(" + $3->getName() +  ")" + $5->getName();

			$$ = new SymbolInfo(now , "statement");
			logout<<now<<"\n\n";

			if($3->getType()=="void")
			{
				yyerror("Void expression used inside if");
			}
	  }
	  | IF LPAREN expression RPAREN statement ELSE statement
	  {
		  	logout<<"Line "<<line_count<<": "<<" statement : IF LPAREN expression RPAREN statement ELSE statement\n\n";
			string now = "if(" + $3->getName() + ")" + $5->getName() + "\nelse " + $7->getName();

			$$ = new SymbolInfo(now , "statement");
			logout<<now<<"\n\n";

			if($3->getType()=="void")
			{
				yyerror("Void expression used inside if");
			}
	  }
	  | WHILE LPAREN expression RPAREN statement
	  {
		  	logout<<"Line "<<line_count<<": "<<" statement : WHILE LPAREN expression RPAREN statement\n\n";
			string now = "while(" + $3->getName()  + ")" + $5->getName();

			$$ = new SymbolInfo(now , "statement");
			logout<<now<<"\n\n";

			if($3->getType()=="void")
			{
				yyerror("Void expression used inside while");
			}
	  }
	  | PRINTLN LPAREN ID RPAREN SEMICOLON
	  {
		  	logout<<"Line "<<line_count<<": "<<" statement : PRINTLN LPAREN ID RPAREN SEMICOLON\n\n";
			string now = "printf(" + $3->getName() + ");";
			$$ = new SymbolInfo(now , "statement");
			logout<<now<<"\n\n";

			if(!table.LookUp($3->getName()))
			{
				yyerror("Undeclared Variable "+$3->getName());
			}
	  }
	  | RETURN expression SEMICOLON
	  {
		  	logout<<"Line "<<line_count<<": "<<" statement : RETURN expression SEMICOLON\n\n";
			string now = "return "+$2->getName() + ";";
			$$ = new SymbolInfo(now , "statement");
			logout<<now<<"\n\n";

			//check if current function is void but returning something
			if(curfunc_type=="void" )
			{
				yyerror("Return statement with value from void function");
			}
			if(curfunc_type=="int" && $2->getType()=="float")
			{
				yyerror("Returning float value from a int function");
			}
	  }
	  ;
	  
expression_statement 	: SEMICOLON
			{
				logout<<"Line "<<line_count<<": "<<" expression_statement : SEMICOLON\n\n";
				string now =  ";";
				$$ = new SymbolInfo(now , "expression_statement");
				logout<<now<<"\n\n";
			}		
			| expression SEMICOLON
			{
				logout<<"Line "<<line_count<<": "<<" expression_statement : expression SEMICOLON\n\n";
				string now = $1->getName() + ";";
				$$ = new SymbolInfo(now , "expression_statement");
				logout<<now<<"\n\n";
			} 
			;
	  
variable : ID
		{
			logout<<"Line "<<line_count<<": "<<" variable : ID\n\n";
			$$ = new SymbolInfo($1->getName() , "variable");
			logout<<$1->getName()<<"\n\n";

			if(!table.LookUp($1->getName()))
			{
				yyerror("Undeclared Variable "+$1->getName());
			}
			else{
				//variable is declared
				//must check if this is an array;
				SymbolInfo *x = isarray.LookUp($1->getName());
				if(x==NULL)
				{
					//ok
				}
				else{
					yyerror("Type mismatch, "+$1->getName() +" is an array");
				}
				SymbolInfo *y = vartype.LookUp($1->getName());
				if(y!=NULL)
				{
					$$->setType(y->getType());
				}
			}
		}
	 | ID LTHIRD expression RTHIRD
	 {
		 	logout<<"Line "<<line_count<<": "<<" variable : ID LTHIRD expression RTHIRD\n\n";
			
			string now = $1->getName() + "[" + $3->getName() +"]";
			$$ = new SymbolInfo(now , "variable");
			logout<<now<<"\n\n";

			if($3->getType()!="int")
			{
				yyerror("Expression inside third brackets not an integer");
			}
			if(!table.LookUp($1->getName()))
			{
				yyerror("Undeclared Variable "+$1->getName());
			}
			else{
				//variable is declared
				//must check if this is an array;
				SymbolInfo *x = isarray.LookUp($1->getName());
				if(x==NULL)
				{
					//ok
					yyerror("Type mismatch, "+$1->getName() +" is not an array");
				}
				else{
					
				}
				SymbolInfo *y = vartype.LookUp($1->getName());
				if(y!=NULL)
				{
					$$->setType(y->getType());
				}
			}
	 }
	 ;
	 
 expression : logic_expression
		{
			logout<<"Line "<<line_count<<": "<<" expression : logic_expression\n\n";
			$$ = new SymbolInfo($1->getName() , $1->getType());
			logout<<$1->getName()<<"\n\n";
		}
	   | variable ASSIGNOP logic_expression
	   {
		   	logout<<"Line "<<line_count<<": "<<" expression : variable ASSIGNOP logic_expression\n\n";
			
			string now = $1->getName() + "=" + $3->getName();
			$$ = new SymbolInfo(now , $1->getType());

			if($1->getType()=="int" && $3->getType()=="float")
			{
				yyerror("Type Mismatch");
			}
			if($3->getType()=="void")
			{
				yyerror("Void function used in expression");
			}

			logout<<now<<"\n\n";
	   } 	
	   ;
			
logic_expression : rel_expression
		{
			logout<<"Line "<<line_count<<": "<<" logic_expression : rel_expression\n\n";
			$$ = new SymbolInfo($1->getName() , $1->getType());
			logout<<$1->getName()<<"\n\n";
		}

		 | rel_expression LOGICOP rel_expression 
		 {
			logout<<"Line "<<line_count<<": "<<" logic_expression : rel_expression LOGICOP rel_expression\n\n";
			string now = $1->getName() + $2->getName() +$3->getName() ;
			$$ = new SymbolInfo(now , "int");

			if($1->getType()=="void" || $3->getType()=="void")
			{
				yyerror("Void function used in expression");
			}

			logout<<now<<"\n\n";
		 }	
		 ;
			
rel_expression	: simple_expression
		{
			logout<<"Line "<<line_count<<": "<<" rel_expression : simple_expression\n\n";
			$$ = new SymbolInfo($1->getName() , $1->getType());
			logout<<$1->getName()<<"\n\n";
		}
		| simple_expression RELOP simple_expression
		{
			logout<<"Line "<<line_count<<": "<<" rel_expression : simple_expression RELOP simple_expression\n\n";
			string now = $1->getName() + $2->getName() + $3->getName();
			$$ = new SymbolInfo(now, "int");
			logout<<now<<"\n\n";

			if($1->getType()=="void" || $3->getType()=="void")
			{
				yyerror("Void function used in expression");
			}
		}
		;
				
simple_expression : term
		{
			logout<<"Line "<<line_count<<": "<<" simple_expression : term\n\n";
			$$ = new SymbolInfo($1->getName() , $1->getType() );
			logout<<$1->getName()<<"\n\n";
		}
		  | simple_expression ADDOP term
		  {
			  logout<<"Line "<<line_count<<": "<<" simple_expression : simple_expression ADDOP term\n\n";
			  string now = $1->getName() + $2->getName() + $3->getName();
			  $$ = new SymbolInfo(now , "int");

			  if($1->getType()=="float" || $3->getType()=="float")
			  {
				  $$->setType("float");
			  }
			  if($1->getType()=="void" || $3->getType()=="void")
				{
					yyerror("Void function used in expression");
				}
			  logout<<now<<"\n\n";
		  } 
		  ;
					
term :	unary_expression
		{
			logout<<"Line "<<line_count<<": "<<" term : unary_expression\n\n";
			$$ = new SymbolInfo($1->getName() , $1->getType());
			logout<<$1->getName()<<"\n\n";
		}
     |  term MULOP unary_expression
	 	{
		 	logout<<"Line "<<line_count<<": "<<" term : term MULOP unary_expression\n\n";
			string now = $1->getName() + $2->getName() + $3->getName();
			$$ = new SymbolInfo(now , "int");

			if($1->getType()=="float" || $3->getType()=="float")
			{
				$$->setType("float");
			}
			if($2->getName()=="%")
			{
				if($1->getType()=="float" || $3->getType()=="float")
				{
					yyerror("Non-Integer operand on modulus operator");
					$$->setType("int");
				}
				if(zero($3->getName()))
				{
					yyerror("Modulus by Zero");
				}
			}
			if($2->getName()=="/")
			{
				if(zero($3->getName()))
				{
					yyerror("Division by Zero");
				}
			}
			if($1->getType()=="void" || $3->getType()=="void")
			{
				yyerror("Void function used in expression");
			}
			logout<<now<<"\n\n";
	 	}
     ;

unary_expression : ADDOP unary_expression
		{
			logout<<"Line "<<line_count<<": "<<" unary_expression : ADDOP unary_expression\n\n";
			string now = $1->getName() + $2->getName();
			$$ = new SymbolInfo(now , $2->getType());
			logout<<now<<"\n\n";
			if($2->getType()=="void")
			{
				yyerror("Void function used in expression");
			}
		}
		 | NOT unary_expression 
		 {
			logout<<"Line "<<line_count<<": "<<" unary_expression : NOT unary_expression\n\n";
			string now = "!"+ $2->getName();
			$$ = new SymbolInfo(now , $2->getType());
			logout<<now<<"\n\n";
			if($2->getType()=="void")
			{
				yyerror("Void function used in expression");
			}
		 }
		 | factor
		 {
			logout<<"Line "<<line_count<<": "<<" unary_expression : factor\n\n";
			$$ = new SymbolInfo($1->getName() , $1->getType());
			logout<<$1->getName()<<"\n\n";
		 }
		 ;
	
factor	: variable
	{
		logout<<"Line "<<line_count<<": "<<" factor : variable\n\n";
		$$ = new SymbolInfo($1->getName() , $1->getType());
		logout<<$1->getName()<<"\n\n";
	}
	| ID LPAREN argument_list RPAREN
	{
		logout<<"Line "<<line_count<<": "<<" factor : ID LPAREN argument_list RPAREN\n\n";
		string now = $1->getName() + "("+$3->getName() + ")";
		$$ = new SymbolInfo(now, "factor");
		logout<<now<<"\n\n";
		if(mp.count($1->getName()))
		{
			$$->setType(mp[$1->getName()].return_type );
			consistent($1->getName() ,$3->getType());
		}
		else{
			yyerror("Undeclared Function "+$1->getName());
		}

		


	}
	| LPAREN expression RPAREN
	{
		logout<<"Line "<<line_count<<": "<<" factor : LPAREN expression RPAREN\n\n";
		string now = "("+$2->getName() + ")";
		$$ = new SymbolInfo(now, $2->getType() );
		logout<<now<<"\n\n";
	}
	| CONST_INT
	{
		logout<<"Line "<<line_count<<": "<<" factor : CONST_INT\n\n";
		$$ = new SymbolInfo($1->getName() , "int");
		logout<<$1->getName()<<"\n\n";
	}
	| CONST_FLOAT
	{
		logout<<"Line "<<line_count<<": "<<" factor : CONST_FLOAT\n\n";
		$$ = new SymbolInfo($1->getName() , "float");
		logout<<$1->getName()<<"\n\n";
	}
	| variable INCOP
	{
		logout<<"Line "<<line_count<<": "<<" factor : variable INCOP\n\n";
		string now = $1->getName() + "++";
		$$ = new SymbolInfo(now, $1->getType());
		logout<<now<<"\n\n";
	}
	| variable DECOP
	{
		logout<<"Line "<<line_count<<": "<<" factor : variable DECOP\n\n";
		string now = $1->getName() + "--";
		$$ = new SymbolInfo(now, $1->getType() );
		logout<<now<<"\n\n";
	}
	;
	
argument_list : arguments
				{
					logout<<"Line "<<line_count<<": "<<" argument_list : arguments\n\n";
					string now = $1->getName();
					$$ = new SymbolInfo(now, $1->getType());
					logout<<now<<"\n\n";
				}
			  |
			  {
				  	logout<<"Line "<<line_count<<": "<<" argument_list : \n\n";
					string now = "";
					$$ = new SymbolInfo(now, "");
			  }
			  ;
	
arguments : arguments COMMA logic_expression
			{
				logout<<"Line "<<line_count<<": "<<" arguments : arguments COMMA logic_expression\n\n";
				string now = $1->getName() + "," + $3->getName();
				$$ = new SymbolInfo(now, $1->getType() +"," + $3->getType());
				logout<<now<<"\n\n";
			}
	      | logic_expression
		  {
			    logout<<"Line "<<line_count<<": "<<" arguments : logic_expression\n\n";
				string now = $1->getName();
				$$ = new SymbolInfo(now, $1->getType());
				logout<<now<<"\n\n";
		  }
	      ;
 

%%
int main(int argc,char *argv[])
{
	
	if((fp=fopen(argv[1],"r"))==NULL)
	{
		printf("Cannot Open Input File.\n");
		exit(1);
	}
	
	logout.open("log.txt");
	error.open("error.txt");

	yyin=fp;
	yyparse();
	
	logout<<"symbol table:\n";
	table.PrintAllScope(logout);

	logout<<"Total Lines: "<<line_count<<"\n\n";
	logout<<"Total Errors: "<<error_count<<"\n";
	error<<"Total Errors: "<<error_count<<"\n";
	fclose(yyin);
	logout.close();
	error.close();
	
	
	return 0;
}

