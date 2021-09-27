%{
#include <iostream>
#include <fstream>
#include <map>
#include <sstream>
#include "SymbolTable.h"
using namespace std;

int yyparse(void);
int yylex(void);

extern FILE *yyin;
FILE *fp;
ofstream logout;
ofstream error;
ofstream asmcode;
ofstream optimized_asmcode;
string code_println()
{
	string ret = ";PRINTS THE NUMBER STORED IN AX\n\
	PUSH AX\n\
	PUSH BX\n\
	PUSH CX\n\
	PUSH DX\n\
	CMP AX,0\n\
	JGE HERE\n\
;NEGATIVE NUMBER\n\
	PUSH AX\n\
	MOV AH, 2\n\
	MOV DL, '-'\n\
	INT 21H\n\
	POP AX\n\
	NEG AX\n\
HERE:\n\
	XOR CX,CX\n\
	MOV BX , 10\n\
LOOP_:\n\
	CMP AX,0\n\
	JE END_LOOP\n\
	XOR DX,DX\n\
	DIV BX\n\
	PUSH DX\n\
	INC CX\n\
	JMP LOOP_\n\
END_LOOP:\n\
	CMP CX,0\n\
	JNE PRINTER\n\
	MOV AH,2\n\
	MOV DL,'0'\n\
	INT 21H\n\
	JMP ENDER\n\
PRINTER:\n\
	MOV AH,2\n\
	POP DX\n\
	OR DL,30H\n\
	INT 21H\n\
	LOOP PRINTER\n\
ENDER:\n\
;PRINT NEW LINE\n\
	MOV AH, 2\n\
	MOV DL , LF\n\
	INT 21H\n\
	MOV DL , CR\n\
	INT 21H\n\
	POP DX\n\
	POP CX\n\
	POP BX\n\
	POP AX\n\
	RET\n";
    return ret;
}

extern int line_count;
extern int error_count;
SymbolTable table(30);

struct func_skeletons{
	string func_name;
	vector<string>argtypes;
	string return_type;
};


class GenerteNames{
public:
	string prefix;
	int now;
	GenerteNames(string s)
	{
		prefix = s;
		now = 0;
	}
	string getName()
	{
		string x = to_string(now);
		string ret = prefix + x;
		now++;
		return ret;
	}
};



map<string , func_skeletons>mp; //this is to keep track of all functions

SymbolTable vartype(30); //this is to keep track of variable types found; 
SymbolTable isarray(30); //this is to check if a variable is an array

GenerteNames labels("LABEL"); //maintain the labels
GenerteNames tempvar("TT"); //maintain the variables
SymbolTable map_variables(30);

string parameter_id; //function parameter ids
string parameter_type; // function parameters data type

string curfunc_type; // return type of current function
string curfunc_name; //name of current function

map<string , string> func_codes; //save the code of current function
string data_segment;   // data segment variables

vector<string>curfunc_parameters;
vector<string>curarguments;
class StackPointer{
public:
	int sp;
	vector<string>v;
	map<string,bool>dont_remove;
	StackPointer()
	{
		sp = 0;
		v.push_back("");
	}
	string add(string var)
	{
		sp+=1;
		v.push_back(var);
		string code = "";
		code += "\tPUSH 0\n";
		return code;
	}
	string add(string var , string val)
	{
		sp+=1;
		v.push_back(var);
		string code = "";
		code += "\tPUSH "+val+"\n";
		return code;
	}
	int get(string var)
	{
		int ret = 0;
		bool fnd = 0;
		for(int i=v.size()-1;i>=0;i--)
		{
			if(v[i]==var)
			{
				ret = i;
				fnd = 1;
				break;
			}
		}
		if(fnd==0)
		{
			//cout<<"Not found "+var<<"\n";
		}
		return (sp-ret)*2;
	}
	bool ache(string var)
	{
		bool fnd = 0;
		for(int i=v.size()-1;i>=0;i--)
		{
			if(v[i]==var)
			{
				fnd = 1;
				break;
			}
		}
		return fnd;
	}
	string remove()
	{
		if(sp<=0)
			return "";
		sp-=1;
		v.pop_back();
		string code = "";
		code += "\tPOP DX\n";
		return code;
	}
	string remove_and_add(string ber , string dhuka, string val)
	{
		
		string ret = "";
		if(dont_remove.count(ber))
		{
			ret += add(dhuka, val);
			return ret;
		}
		if(!ache(ber))
		{
			ret += add(dhuka, val);
			return ret;
		}

		while(sp>0){
			if(dont_remove.count(v.back()))
			{
				ret += add(dhuka, val);
				break;
			}
			if(v.back()==ber)
			{
				ret += remove();
				ret += add(dhuka, val);
				break;
			}
			ret += remove();
		}
		return ret;
	}
	string change_symbol(string ber , string dhuka)
	{
		string ret = "";
		if(dont_remove.count(ber))
		{
			int koi = get(ber);
			ret += "\tMOV BP,SP\n";
			ret += "\tMOV AX,[BP+"+to_string(koi) +"]\n";
			ret += add(dhuka , "AX");
			return ret;
		}
		if(!ache(ber))
		{
			return "";
		}
		for(int i=v.size()-1;i>=0;i--)
		{
			if(v[i]==ber)
			{
				v[i] = dhuka;
				break;
			}
		}
		return "";
	}
	string just_remove(string ber)
	{
		if(!ache(ber))
		{
			return "";
		}
		string ret = "";
		if(dont_remove.count(ber))
		{
			return ret;
		}
		while(sp>0){
			if(dont_remove.count(v.back()))
				break;
			if(v.back()==ber)
			{
				ret += remove();
				break;
			}
			ret += remove();
		}
		return ret;
	}
	string remove_extras()
	{
		string ret = "";
		while(sp>0)
		{
			if(dont_remove.count(v.back()))
				break;
			ret += remove();
		}
		return ret;
	}
	void show()
	{
		cout<<"Showing\n";
		for(string s:v)
		{
			cout<<s<<"\n";
		}
		cout<<"done\n";
	}
	void clear()
	{
		v.clear();
		sp = 0;
		v.push_back("");
		dont_remove.clear();
	}
	void erase_idx(string s)
	{
		int idx = -1;
		for(int i=v.size()-1;i>=0;i--)
		{
			if(v[i]==s)
			{
				idx= i;
				break;
			}
		}
		v.erase(v.begin()+idx);
		sp-=1;
	}
};
StackPointer stp; //maintain the variable stack

vector<string> extract(string s)
{
	vector<string>ret;
	string now = "";
	for(int i=0;i<s.size();i++)
	{
		if(s[i]=='\t' || s[i]=='\n' || s[i]==' ' || s[i]==',')
		{
			if(now.size())
				ret.push_back(now);
			now = "";
		}
		else{
			now += s[i];
		}
	}
	if(now.size())
		ret.push_back(now);
	return ret;

}
bool check_not_important(string s1, string s2)
{
	if(!(s1[0]=='\t' && s2[0]=='\t'))
	{
		return false;
	}
	vector<string>v1 = extract(s1);
	vector<string>v2 = extract(s2);
	if(v1.size()!= v2.size())
	{
		return false;
	}
	if(v1[0]=="MOV" && v2[0]=="MOV")
	{
		return v1[1]==v2[0] && v1[0] == v2[1];
	}
	else if(v1[0]=="PUSH" &&  v2[0]=="POP")
	{
		return true;
	}
	return false;
}

bool level_two_optimization(string s1, string s2, string s3, string s4 , string &ret)
{
	vector<string>v1 = extract(s1);
	vector<string>v2 = extract(s2);
	vector<string>v3 = extract(s3);
	vector<string>v4 = extract(s4);
	if(v1.size()!=2 || v2.size()!=3 || v3.size()!=3 || v4.size() != 2)
	{
		return false;
	}
	if(v1[0]!="PUSH" || v2[0]!="MOV" || v2[1]!="BP" || v2[2]!="SP" ||v3[0]!="MOV" || v3[2]!="[BP+0]" || v4[0]!="POP" ||v4[1]!="DX")
	{
		return false;
	}
	ret = "";
	if(v3[1]!= v1[1])
		ret = "\tMOV "+v3[1] +"," + v1[1];
	return true;
}
string code_optimizer(string code)
{
	string ret = "";
	stringstream s(code); 
    string word;
	
	vector<string>v;

	while (!s.eof())
	{
		getline(s , word);
		if(word.empty() || word[0]==';' )
			continue;
		if(v.size() && check_not_important(v.back() , word) )
		{
			v.pop_back();
			continue;
		}
		string tx;
		if(v.size()>=3 && level_two_optimization( v[v.size()-3],v[v.size()-2] ,v[v.size()-1],word ,tx) )
		{
			v.pop_back();
			v.pop_back();
			v.pop_back();
			if(tx.size())
				v.push_back(tx);
			continue;
		}
		v.push_back(word);
	}
	for(string it:v)
	{
		ret += it+"\n";
	}
	return ret;
}

string print_code()
{
	string ret = "";
	func_codes["PRINTLN"] = code_println();
	ret+=".MODEL SMALL\n\n.STACK 100H\n\n";
	ret+=".DATA\n\n";
	ret+="\tCR EQU 0DH\n\tLF EQU 0AH\n";
	ret+=data_segment+"\n";
	ret+=".CODE\n\n\n";
	for(auto it:func_codes)
	{
		if(it.first=="main")
		{
			ret+="MAIN PROC\n\n";
			ret+="\tMOV AX, @DATA\n\tMOV DS, AX\n";
			ret+=it.second+"\n";
			ret+=";DOS EXIT\n\tMOV AH, 4CH\n\tINT 21H\n";
			ret+="MAIN ENDP\n";
		}
		else{
			ret += it.first +" PROC\n\n";
			ret += it.second;
			ret += it.first + " ENDP\n\n";
		}
		
	}
	ret+="END MAIN\n";
	return ret;
}
string if_code(string exp , string s1)
{
	string code = ";code if ("+exp+")\n";
	int koi = stp.get(exp);
	stp.erase_idx(exp);
	koi = 0;
	string l1 = labels.getName();
	code += "\tMOV BP,SP\n";
	//code += "\tMOV AX, [BP+ "+to_string(koi)+"]\n";
	code += "\tCMP [BP+"+to_string(koi)+"] , 0\n";
	code += "\tJE "+ l1+"\n";
	code += s1;
	code += l1 +":\n";
	code += "\tPOP DX\n";
	return code;
}
string if_code(string exp , string s1, string s2)
{
	string code = ";code if else ("+exp+")\n";
	int koi = stp.get(exp);
	stp.erase_idx(exp);
	koi = 0;
	//cout<<exp<<" "<<koi<<"\n";
	//stp.show();
	string l1 = labels.getName();
	string l2 = labels.getName();
	code += "\tMOV BP,SP\n";
	//code += "\tMOV AX, [BP+ "+to_string(koi)+"]\n";
	code += "\tCMP [BP+ "+to_string(koi)+"] , 0\n";
	code += "\tJE "+ l1+"\n";
	code += s1;
	code += "\tJMP "+l2+"\n";
	code += l1 +":\n";
	code += s2;
	code += l2 +":\n";
	code += "\tPOP DX\n";
	return code;
}
string while_code(string exp , string s1 , string s2)
{
	string code = ";code while ("+exp+")\n";
	int koi = stp.get(exp);
	string l1 = labels.getName();
	string l2 = labels.getName();
	code += l1 +":\n";
	code += s1 ;
	code += "\tMOV BP,SP\n";
	code += "\tMOV AX , [BP+"+to_string(koi)+"]\n";
	code += "\tCMP AX , 0\n";
	code += "\tJE "+l2+"\n";
	code += s2;
	string tmp = stp.just_remove(exp);
	code += tmp;
	code += "\tJMP "+l1+"\n";
	code += l2 +":\n";
	code += tmp;
	return code;
}

string dummy_remove()
{
	//stp.show();
	string code = "";
	int sz = stp.v.size()-1;
	for(int i=0;i<sz;i++)
	{
		code += "\tPOP DX\n";
	}
	return code;
}
string function_call_code(string name, string tot)
{
	int sz = curarguments.size();
	string code = ";calling function "+name +"\n";
	//save the return address
	string x1 = tempvar.getName();
	code += stp.add(x1, "DI");
	for(int i=0;i<sz;i++)
	{
		string eta = curarguments[i];
		int koi = stp.get(eta);
		code += "\tMOV BP,SP\n";
		code += stp.add(eta , "[BP+"+to_string(koi)+"]");
	}
	code += "\tCALL "+name+"\n";
	for(int i=0;i<sz;i++)
	{
		string temp = stp.remove();
	}
	string tmp = stp.remove();
	code += "\tPOP DI\n";
	curarguments.clear();
	code += stp.add(tot,"AX");
	return code;
}
string return_code(string exp , string s)
{
	if(curfunc_name=="main")
	{
		string code = ";Return "+exp+"\n";
		code += s;
		code += stp.just_remove(exp);
		code += ";DOS EXIT\n\tMOV AH, 4CH\n\tINT 21H\n";
		return code;
	}
	//return value is in ax;
	//stp.show();
	string code = ";Return "+exp+"\n";
	int koi = stp.get(exp);
	code += s;
	code += "\tMOV BP,SP\n";
	code += "\tMOV AX,[BP+"+to_string(koi)+"]\n";
	code += stp.just_remove(exp);
	code += dummy_remove();
	code += "\tPUSH DI\n";
	code += "\tRET\n";
	return code;
}

string forloop_code(string exp1 , string s1, string exp2 , string s2 , string exp3, string s3 , string s4)
{
	string code = ";code for ("+exp1+" "+exp2+" "+exp3+")\n";
	code += s1;
	exp1.pop_back();
	exp2.pop_back();
	string l1 = labels.getName();
	string l2 = labels.getName();
	string tm1 = stp.just_remove(exp3);
	int koi = stp.get(exp2);
	//cout<<exp2<<" "<<koi<<" "<<stp.v.back()<<"\n";
	code += l1 +":\n";
	code += s2 ;
	if(!exp2.empty()){
		code += "\tMOV BP,SP\n";
		code += "\tMOV AX , [BP+"+to_string(koi)+"]\n";
		code += "\tCMP AX , 0\n";
		code += "\tJE "+l2+"\n";
	}
	code += "\tPUSH 0\n";
	code += s4;
	code += "\tPOP DX\n";
	code += s3;
	string tmp =  stp.just_remove(exp2);
	code += tm1 + tmp;
	code += "\tJMP "+l1+"\n";
	code += l2 +":\n";
	code += tmp;
	
	//cout<<s3<<"\n\n"<<s4<<"\n\n"<<tmp<<"\n";
	return code;
}
string println_code(string var)
{
	string code = "";
	int koi = stp.get(var);
	
	code += ";printing "+var+"\n";
	code += "\tMOV BP,SP\n";
	code += "\tMOV AX, [BP+ "+to_string(koi)+"]\n";
	code += "\tCALL PRINTLN\n";
	return code;
}
string insert_variable(string name)
{
	string ret =  stp.add(name);
	stp.dont_remove[name] = 1;
	return ret;
}
void insert_variable(string name , string sz)
{
	string tempname = tempvar.getName();
	map_variables.insert_symbol(name , tempname);
	data_segment += "\t"+tempname+" DW "+sz+ " DUP(?)\n";
	
}
string push_in_stack(string var)
{

	if(var.back()!=']')
	{
		return ""; 
	}
	string name ;
	string koto;
	for(int i=0;i<var.size();i++)
	{
		if(var[i]=='[')
		{
			for(int j=i+1;j<var.size();j++)
			{
				if(var[j]==']')
					break;
				koto += var[j];
			}
			break;
		}
		name+= var[i];
	}
	name = map_variables.LookUp(name)->getType();
	int val = stp.get(koto);
	string t1 = "[BP+";
	t1 += to_string(val);
	t1 += "]\n";
	string code = "";
	code += "\tMOV BP,SP\n";
	code += "\tMOV SI , " + t1;
	code += "\tADD SI , SI\n";
	code += "\tMOV AX , " + name + "[SI]\n";
	code += stp.just_remove(koto);
	code += stp.add(var , "AX");
	return code;
}
string addop_unary(string op, string var)
{
	if(op=="+")
	{
		return "";
	}
	string code = "; doing "+op+" "+var+"\n";
	int koi = stp.get(var);
	string t1 = "[BP+" + to_string(koi) + (string)"]";
	code += "\tMOV BP,SP\n";
	code += "\tMOV AX, " +t1+ (string)"\n";
	code += "\tMOV BX, " +t1+ (string)"\n";
	code += "\tSUB AX,BX\n";
	code += "\tSUB AX,BX\n";
	code+= stp.remove_and_add(var , "-"+var , "AX");
	return code;
}

string not_unary(string op , string var)
{
	string code = "; doing "+op+" "+var+"\n";
	int koi1 = stp.get(var);
	string t1 = "[BP+";
	t1 += to_string(koi1);
	t1 += "]";
	string p1 = labels.getName();
	string p2 = labels.getName();
	code += "\tMOV BP,SP\n";
	code += "\tMOV AX, ";
	code += t1+"\n";
	code += "\tCMP AX , 0\n";
	code += "\tJNE "+ p1 +"\n";
	code += "\tMOV BX,1\n";
	code += "\tJMP ";
	code += p2 +"\n";
	code += "\n\n" + p1 +":\n";
	code += "\tMOV BX,0\n";
	code += "\n\n" + p2 +":\n";
	code += stp.remove_and_add(var , op+var , "BX");
	return code;
}
string incop_op(string var , int xx)
{
	string tot = var;
	if(xx==1)
	{
		tot += "++";
	}
	else{
		tot += "--";
	}
	if(var.back()!=']')
	{
		int val = stp.get(var);
		string t1 = "[BP+";
		t1 += to_string(val);
		t1 += "]";
		string code = ";Incrementing varibale "+var+", "+ to_string(xx) + "\n";
		code += "\tMOV BP,SP\n";
		code += "\tMOV AX," + t1 +"\n";
		code += stp.remove_and_add(tot,tot,"AX");
		code += "\tADD AX,"+ to_string(xx) +"\n";
		code += "\tMOV "+t1+" , AX\n";
		return code;
	}
		
	string name ;
	string koto;
	for(int i=0;i<var.size();i++)
	{
		if(var[i]=='[')
		{
			for(int j=i+1;j<var.size();j++)
			{
				if(var[j]==']')
					break;
				koto += var[j];
			}
			break;
		}
		name+= var[i];
	}
	name = map_variables.LookUp(name)->getType();
	//cout<<name<<" "<<koto<<"\n";
	int val = stp.get(koto);
	string t1 = "[BP+";
	t1 += to_string(val);
	t1 += "]\n";
	string code = ";Incrementing varibale "+var+", "+ to_string(xx) + "\n";;
	code += "\tMOV BP,SP\n";
	code += "\tMOV SI , " + t1;
	code += "\tADD SI , SI\n";
	string temp = name + "[SI]";
	code += stp.remove_and_add(tot , tot , temp);
	code += "\tADD " + name + "[SI],"+to_string(xx) + "\n";
	code += stp.just_remove(koto);
	return code;
}
string array_assign(string var , string dan)
{
	string name ;
	string koto;
	for(int i=0;i<var.size();i++)
	{
		if(var[i]=='[')
		{
			for(int j=i+1;j<var.size();j++)
			{
				if(var[j]==']')
					break;
				koto += var[j];
			}
			break;
		}
		name+= var[i];
	}
	name = map_variables.LookUp(name)->getType();
	int val = stp.get(koto);
	int koi1 = stp.get(dan);
	string t1 = "[BP+";
	t1 += to_string(koi1);
	t1 += "]\n";
	string code = "";
	code += "\tMOV BP,SP\n";
	code += "\tMOV SI,[BP+" + to_string(val) +"]\n";
	code += "\tADD SI,SI\n";
	code += "\tMOV AX, " + t1;
	code +="\tMOV "+ name + "[SI] , AX\n";
	code += stp.just_remove(dan);
	code += stp.just_remove(koto);
	return code;
}

string do_logic_op(string op1, string op2,  string kon , string tot)
{
	if(kon=="||")
	{
		string code = "; doing logic operation "+tot+"\n";
		int koi1 = stp.get(op1);
		int koi2 = stp.get(op2);
		string t1 = "[BP+";
		t1 += to_string(koi1);
		t1 += "]\n";
		string t2 = "[BP+";
		t2 += to_string(koi2);
		t2 += "]\n";
		string p1 = labels.getName();
		string p2 = labels.getName();
		code += "\tMOV BP,SP\n";
		code += "\tMOV AX, ";
		code += t1;
		code += "\tOR AX, ";
		code += t2;
		code += "\tCMP AX , 0\n";
		code += "\tJNE "+ p1 +"\n";
		code += "\tMOV BX,0\n";
		code += "\tJMP ";
		code += p2 +"\n";
		code += "\n\n" + p1 +":\n";
		code += "\tMOV BX,1\n";
		code += "\n\n" + p2 +":\n";
		code += stp.just_remove(op2);
		code += stp.remove_and_add(op1 , tot , "BX");
		//code += stp.add(tot,"BX");
		return code;
	}
	string code = "; doing logic operation "+tot+"\n";
	int koi1 = stp.get(op1);
	int koi2 = stp.get(op2);
	string t1 = "[BP+";
	t1 += to_string(koi1);
	t1 += "]";
	string t2 = "[BP+";
	t2 += to_string(koi2);
	t2 += "]";
	string p1 = labels.getName();
	string p2 = labels.getName();
	
	code += "\tMOV BP,SP\n";
	code += "\tCMP "+t1 +" ,0\n";
	code += "\tJE "+p1+"\n";

	code += "\tCMP "+t2 +" ,0\n";
	code += "\tJE "+p1+"\n";


	code += "\tMOV BX,1\n";
	code += "\tJMP ";
	code += p2 +"\n";
	code += "\n\n" + p1 +":\n";
	code += "\tMOV BX,0\n";
	code += "\n\n" + p2 +":\n";
	code += stp.just_remove(op2);
	code += stp.remove_and_add(op1 , tot , "BX");
	//code += stp.add(tot,"BX");
	return code;


}
string relop_code(string op1 , string op2 , string kon , string tot)
{
	string code = "; doing relop operation "+tot + "\n";
	int koi1 = stp.get(op1);
	int koi2 = stp.get(op2);
	string t1 = "[BP+";
	t1 += to_string(koi1);
	t1 += "]\n";
	string t2 = "[BP+";
	t2 += to_string(koi2);
	t2 += "]\n";

	string p1 = labels.getName();
	string p2 = labels.getName();
	string cmd ;
	//"<"|"<="|">"|">="|"=="|"!=" 
	if(kon == "<")
	{
		cmd = "\tJL";
	}
	else if(kon=="<=")
	{
		cmd = "\tJLE";
	}
	else if(kon==">")
	{
		cmd = "\tJG";
	}
	else if(kon==">=")
	{
		cmd = "\tJGE";
	}
	else if(kon=="==")
	{
		cmd = "\tJE";
	}
	else if(kon == "!=")
	{
		cmd = "\tJNE";
	}
	code += "\tMOV BP,SP\n";
	code += "\tMOV AX, ";
	code += t1;
	code += "\tCMP AX , ";
	code += t2;
	code += cmd +" "+ p1 +"\n";
	code += "\tMOV BX,0\n";
	code += "\tJMP ";
	code += p2 +"\n";
	code += "\n\n" + p1 +":\n";
	code += "\tMOV BX,1\n";
	code += "\n\n" + p2 +":\n";

	code += stp.just_remove(op2);
	code += stp.remove_and_add(op1 , tot , "BX");
	return code;
}

string add_mulop_code(string op1 , string op2 , string kon , string tot)
{
	string code = "; doing mulop operation "+tot + "\n";
	int koi1 = stp.get(op1);
	int koi2 = stp.get(op2);
	string t1 = "[BP+";
	t1 += to_string(koi1);
	t1 += "]\n";
	string t2 = "[BP+";
	t2 += to_string(koi2);
	t2 += "]\n";
	if(kon=="*")
	{
		code += "\tMOV BP,SP\n";
		code += "\tMOV AX , [BP+";
		code += to_string(koi1);
		code += "]\n";
		code += "\tIMUL [BP+";
		code += to_string(koi2);
		code += "]\n";
		code += stp.just_remove(op2);
		code += stp.remove_and_add(op1 , tot , "AX");
		//code += stp.add(tot,"AX");
	}
	else if(kon=="/")
	{
		code += "\tMOV BP,SP\n";
		code += "\tMOV AX, ";
		code += t1;
		code +="\tCWD\n";
		code += "\tMOV BX,";
		code += t2;
		code+= "\tIDIV BX\n";
		code += stp.just_remove(op2);
		code += stp.remove_and_add(op1 , tot , "AX");
	}
	else if(kon=="%")
	{
		code += "\tMOV BP,SP\n";
		code += "\tMOV AX, ";
		code += t1;
		code +="\tCWD\n";
		code += "\tMOV BX,";
		code += t2;
		code += "\tIDIV BX\n";
		code += "\tIMUL BX\n";
		code += "\tMOV BX,";
		code += t1;
		code += "\tSUB BX , AX\n";
		code += stp.just_remove(op2);
		code += stp.remove_and_add(op1 , tot , "BX");
	}
	return code;

}

//previous functions for yacc
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
	for(int i=0;i<curfunc_parameters.size();i++)
	{
		string code = "";
		code = insert_variable(curfunc_parameters[i]);
	}
	curfunc_parameters.clear();
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
%token IF ELSE FOR WHILE INT FLOAT VOID RETURN PRINTLN
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
			curfunc_parameters.clear();
			insert_function($2->getName() , $4->getName() , $1->getName());
			
		}
		| type_specifier ID LPAREN RPAREN SEMICOLON
		{
			logout<<"Line "<<line_count<<": "<<" func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON\n\n";
			string now = $1->getName() + " " + $2->getName() + "();";
			$$ = new SymbolInfo(now , "func_declaration");
			logout<<now<<"\n\n";
			table.insert_symbol($2->getName() , "ID");
			curfunc_parameters.clear();
			insert_function($2->getName() , "" , $1->getName());
		}
		;
		 

func_definition : type_specifier ID LPAREN  parameter_list RPAREN {table.insert_symbol($2->getName() , "ID");curfunc_type = $1->getName();curfunc_name = $2->getName() ;insert_function($2->getName() , $4->getName() , $1->getName()); }  compound_statement
		{
			logout<<"Line "<<line_count<<": "<<" func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement\n\n";
			string now = $1->getName() + " "+$2->getName() + "("+$4->getName() +")"+$7->getName();
			logout<<now<<"\n\n";
			$$ = new SymbolInfo(now , "func_definition");

			string code = "";
			string code2 = "";
			if(curfunc_name!="main")
			{
				code += "\tPOP DI\n";
				//code2 += dummy_remove();
				code2 += "\tPUSH DI\n";
				code2 += "\tRET\n";
			}
			func_codes[curfunc_name]+= code + $7->getCode() + code2;
			stp.clear();
		}
		| type_specifier ID LPAREN RPAREN {table.insert_symbol($2->getName() , "ID");curfunc_type = $1->getName();insert_function($2->getName() , "" , $1->getName());curfunc_name = $2->getName() ; } compound_statement
		{
			logout<<"Line "<<line_count<<": "<<" func_definition : type_specifier ID LPAREN RPAREN compound_statement\n\n";
			string now = $1->getName() + " "+$2->getName() + "("+")"+$6->getName();
			logout<<now<<"\n\n";
			$$ = new SymbolInfo(now , "func_definition");
			string code = "";
			string code2 = "";
			if(curfunc_name!="main")
			{
				code += "\tPOP DI\n";
				//code2 += dummy_remove();
				code2 += "\tPUSH DI\n";
				code2 += "\tRET\n";
			}
			func_codes[curfunc_name]+= code + $6->getCode()+code2;
			stp.clear();
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
			curfunc_parameters.push_back($4->getName());
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
			curfunc_parameters.clear();
			curfunc_parameters.push_back($2->getName());
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
				map_variables.exit_scope(logout,false);
				$$->setCode($3->getCode());
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
				map_variables.exit_scope(logout,false);
			 }
 		    ;
enter_new_scope : 
			{
				table.enter_scope(logout);
				vartype.enter_scope(logout,false);
				isarray.enter_scope(logout, false);
				map_variables.enter_scope(logout,false);
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
					$$ = new SymbolInfo(now , "var_declaration", $2->getCode());
					logout<<now<<"\n\n";


					//type_specifier must not be void
					if($1->getName()=="void")
					{
						yyerror("Variable type cannot be void");
					}
					else{
						parse_variables($2->getName(),$1->getName());
					}
					//cout<<$2->getName()<<" "<<$2->getCode()<<"\n";
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
			//Code generation part
			string code = insert_variable($3->getName());
			$$->setCode($1->getCode() + code);
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
				insert_variable($3->getName() , $5->getName());
				$$->setCode($1->getCode() );
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
				string code = insert_variable($1->getName());
				$$->setCode(code);
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
				insert_variable($1->getName() , num);
		   }
 		  ;
 		  
statements : statement
		{
			logout<<"Line "<<line_count<<": "<<" statements : statement\n\n";
			//string xx = stp.remove_extras();
			$$ = new SymbolInfo($1->getName() , "statements" , $1->getCode() );
			logout<<$1->getName()<<"\n\n";
			//cout<<$1->getCode()<<"\n";
		}
	   | statements statement
	   {
		   	logout<<"Line "<<line_count<<": "<<" statements : statements statement\n\n";
			string now = $1->getName() + "\n" + $2->getName();
			//string xx = stp.remove_extras();
			$$ = new SymbolInfo(now , "statements" , $1->getCode()+$2->getCode() );
			logout<<now<<"\n\n";
	   }
	   ;
	   
statement : var_declaration
		{
			logout<<"Line "<<line_count<<": "<<" statement : var_declaration\n\n";
			string now = $1->getName();
			$$ = new SymbolInfo(now , "statement" , $1->getCode() );
			logout<<now<<"\n\n";

			//cout<<$1->getCode()<<"\n";
		}
	  | expression_statement
	  {
		  	logout<<"Line "<<line_count<<": "<<" statement : expression_statement\n\n";
			string now = $1->getName();
			string temp = now;
			temp.pop_back();
			string code ="";
			if(temp.size())
				code = stp.just_remove(temp);
			$$ = new SymbolInfo(now , "statement" , $1->getCode()+code);
			logout<<now<<"\n\n";
	  }
	  | compound_statement
	  {
		  	logout<<"Line "<<line_count<<": "<<" statement : compound_statement\n\n";
			string now = $1->getName();
			$$ = new SymbolInfo(now , "statement",$1->getCode());
			logout<<now<<"\n\n";
	  }
	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement
	  {
		  	logout<<"Line "<<line_count<<": "<<" statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement\n\n";
			string now = "for(" + $3->getName() + $4->getName() + $5->getName() + ")" + $7->getName();

			$$ = new SymbolInfo(now , "statement");
			logout<<now<<"\n\n";

			//todo for loop 
			$$->setCode(forloop_code($3->getName() ,$3->getCode() , $4->getName(),$4->getCode(),$5->getName(),$5->getCode(),$7->getCode()   ));

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

			$$->setCode($3->getCode() + if_code($3->getName() , $5->getCode()));

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
			$$->setCode($3->getCode() + if_code($3->getName() , $5->getCode() , $7->getCode() ));
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

			//code
			$$->setCode(while_code($3->getName() , $3->getCode() , $5->getCode()));
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

			//code
			string code = println_code($3->getName());
			$$->setCode(code);
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
				yyerror("Returning float value from an int function");
			}
			$$->setCode(return_code($2->getName() , $2->getCode()  ));
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
				
				$$ = new SymbolInfo(now , "expression_statement",$1->getCode());
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
			$$->setCode($3->getCode());
	 }
	 ;
	 
 expression : logic_expression
		{
			logout<<"Line "<<line_count<<": "<<" expression : logic_expression\n\n";
			$$ = new SymbolInfo($1->getName() , $1->getType() ,$1->getCode());
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

			//CODE part
			//doing for simple variable 
			string nam = $1->getName();
			if(nam[nam.size()-1]==']')
			{
				string code = array_assign(nam , $3->getName());
				$$->setCode($1->getCode() + $3->getCode()+  code);
			}
			else{
				int koi2 = stp.get($3->getName());
				string code = "";
				code += "\tMOV BP,SP\n";
				code += "\tMOV AX , [BP+";
				code += to_string(koi2);
				code += "]\n";
				
				code += stp.just_remove($3->getName());
				
				int koi = stp.get($1->getName());
				code += "\tMOV BP,SP\n";
				code += "\tMOV [BP+";
				code += to_string(koi);
				code += "] , AX\n";
				$$->setCode($1->getCode() + $3->getCode()+  code);
			
			}
	   } 	
	   ;
			
logic_expression : rel_expression
		{
			logout<<"Line "<<line_count<<": "<<" logic_expression : rel_expression\n\n";
			$$ = new SymbolInfo($1->getName() , $1->getType(),$1->getCode());
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

			string code = do_logic_op($1->getName() , $3->getName() , $2->getName() , $$->getName());
			$$->setCode($1->getCode() + $3->getCode()+  code);
		 }	
		 ;
			
rel_expression	: simple_expression
		{
			logout<<"Line "<<line_count<<": "<<" rel_expression : simple_expression\n\n";
			$$ = new SymbolInfo($1->getName() , $1->getType() ,$1->getCode());
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

			//code part
			string code = relop_code($1->getName() , $3->getName() , $2->getName() , now);
			$$->setCode($1->getCode() + $3->getCode()+  code);
		}
		;
				
simple_expression : term
		{
			logout<<"Line "<<line_count<<": "<<" simple_expression : term\n\n";
			$$ = new SymbolInfo($1->getName() , $1->getType() ,$1->getCode());
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

			  //code part
			  int koi1 = stp.get($1->getName());
			  int koi2 = stp.get($3->getName());
			  string code = "";
			  code += "\tMOV BP,SP\n\tMOV AX, [BP+" +to_string(koi1) + "]\n";
			  if($2->getName() =="+")
			  {
					code += "\tADD AX, ";
					code+= "[BP+";
					code +=  to_string(koi2) ;
					code += "]\n";
			  }
			  else{
				  	code += "\tSUB AX, ";
					code+= "[BP+";
					code +=  to_string(koi2) ;
					code += "]\n";
			  }
			  code += stp.just_remove($3->getName());
			  code += stp.remove_and_add($1->getName() , $$->getName() , "AX");	
			  //code += stp.add( $$->getName() , "AX");

			  $$->setCode($1->getCode() + $3->getCode()+  code);	  
		  } 
		  ;
					
term :	unary_expression
		{
			logout<<"Line "<<line_count<<": "<<" term : unary_expression\n\n";
			$$ = new SymbolInfo($1->getName() , $1->getType(),$1->getCode());
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
			// CODE part
			string code = add_mulop_code($1->getName() , $3->getName() , $2->getName() ,now);
			$$->setCode($1->getCode() + $3->getCode()+  code);
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
			//code
			$$->setCode( $2->getCode()+ addop_unary( $1->getName() , $2->getName() ) );
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

			$$->setCode( $2->getCode()+ not_unary( "!" , $2->getName() ) );
		 }
		 | factor
		 {
			logout<<"Line "<<line_count<<": "<<" unary_expression : factor\n\n";
			$$ = new SymbolInfo($1->getName() , $1->getType(),$1->getCode());
			logout<<$1->getName()<<"\n\n";
		 }
		 ;
	
factor	: variable
	{
		logout<<"Line "<<line_count<<": "<<" factor : variable\n\n";
		$$ = new SymbolInfo($1->getName() , $1->getType());
		logout<<$1->getName()<<"\n\n";

		//code part
		
		string name = $1->getName();
		string code = push_in_stack(name);
		$$->setCode($1->getCode()+code);
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

		//todo

		$$->setCode($3->getCode() + function_call_code($1->getName(), now));

	}
	| LPAREN expression RPAREN
	{
		logout<<"Line "<<line_count<<": "<<" factor : LPAREN expression RPAREN\n\n";
		string now = "("+$2->getName() + ")";
		$$ = new SymbolInfo(now, $2->getType() );
		logout<<now<<"\n\n";

		//code_part
		//todo code add
		string code = stp.change_symbol($2->getName() , now);
		$$->setCode($2->getCode() + code);
	}
	| CONST_INT
	{
		logout<<"Line "<<line_count<<": "<<" factor : CONST_INT\n\n";
		$$ = new SymbolInfo($1->getName() , "int");
		logout<<$1->getName()<<"\n\n";

		//code part
		string code = stp.add($1->getName(),$1->getName());
		$$->setCode(code);
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

		// code part
		string name = $1->getName();
		string code = incop_op(name,1);
		$$->setCode($1->getCode()+code);
	}
	| variable DECOP
	{
		logout<<"Line "<<line_count<<": "<<" factor : variable DECOP\n\n";
		string now = $1->getName() + "--";
		$$ = new SymbolInfo(now, $1->getType() );
		logout<<now<<"\n\n";

		// code part
		string name = $1->getName();
		string code = incop_op(name,-1);
		$$->setCode($1->getCode()+code);
	}
	;
	
argument_list : arguments
				{
					logout<<"Line "<<line_count<<": "<<" argument_list : arguments\n\n";
					string now = $1->getName();
					$$ = new SymbolInfo(now, $1->getType());
					logout<<now<<"\n\n";

					$$->setCode($1->getCode());
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

				//code 
				$$->setCode($1->getCode()+ $3->getCode());
				curarguments.push_back($3->getName());
			}
	      | logic_expression
		  {
			    logout<<"Line "<<line_count<<": "<<" arguments : logic_expression\n\n";
				string now = $1->getName();
				$$ = new SymbolInfo(now, $1->getType());
				logout<<now<<"\n\n";


				//code
				$$->setCode($1->getCode());
				curarguments.clear();
				curarguments.push_back($1->getName());
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
	asmcode.open("code.asm");
	optimized_asmcode.open("optimized_code.asm");
	yyin=fp;
	yyparse();
	
	logout<<"symbol table:\n";
	table.PrintAllScope(logout);

	logout<<"Total Lines: "<<line_count<<"\n\n";
	logout<<"Total Errors: "<<error_count<<"\n";
	error<<"Total Errors: "<<error_count<<"\n";
	if(error_count==0)
	{
		string code = print_code();
		asmcode<<code<<"\n";
		optimized_asmcode<<code_optimizer(code)<<"\n";
	}
	fclose(yyin);
	logout.close();
	error.close();
	asmcode.close();
	optimized_asmcode.close();
	
	return 0;
}

