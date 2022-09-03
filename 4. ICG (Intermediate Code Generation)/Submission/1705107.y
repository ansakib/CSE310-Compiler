%{

#include<bits/stdc++.h>
#include "SymbolTable.h"

#define YYSTYPE SymbolInfo*

using namespace std;

SymbolTable symT(30);
FILE *errorfile = fopen("error.txt", "w");
FILE *logfile = fopen("log.txt", "w");
FILE *asmFile = fopen("code.asm", "w");
FILE *optAsmFile = fopen("optimized_code.asm", "w");
bool ErrFunc = false;

bool RETtoCaller = true;
string runningAsmCode = "";
string runningOptAsmCode = "";
string DS = "";
string optDS = "";
string runningProc;
bool isOptimized = false;

int yyparse(void);
int yylex(void);

int labelCount = 0;
int tempVarCount = 0;

extern int line_count;
extern int errorCount;
extern FILE* yyin;

vector< pair<string,string> > paramsList;
vector< pair<string,bool> > tempVarList; //kon temp var gula use hocche segula track rakhar jonno




void yyerror(string s)
{
	//write your code
    //cout<<s<<endl;
	fprintf(logfile, "Error at line no %d : %s \n\n", line_count, s.c_str());
    fprintf(errorfile, "Error at line no %d : %s \n\n", line_count, s.c_str());
    errorCount++;

}

///////////////////////////optimization code starts here/////////////////////////////

string FinalOptimization(string asmCode)
{
    vector<string> line;
    vector< vector<string> > codeLines;
    bool nl = true;
    /*  
        get rid of ' ' and ',' except those in statement comments
    */
    for(int i=0; i<asmCode.length(); i++){
        if(asmCode[i]==';')
        {
            string statementComment = "";
            if(nl==true)
            {
                nl = false;
                statementComment += "\n";
            }
            while(asmCode[i]!='\n')
            {
                statementComment += asmCode[i];
                i++;
            }
            nl = true;
            line.push_back(statementComment);
        }
        else if(asmCode[i]!='\n')
        {
            string actualCode = "";
            while(asmCode[i]!='\n')
            {
                actualCode += asmCode[i];
                i++;
            }
            nl = true;
            line.push_back(actualCode);
        }
    }
    for(int i=0; i<line.size(); i++)
    {
        vector<string> temp;
        for(int j=0; j<line[i].length(); j++)
        {
            if(line[i][j]!=' ' && line[i][j]!=',')
            {
                string tempCode = "";
                while(line[i][j]!=' ' && line[i][j]!=',')
                {
                    tempCode += line[i][j];
                    j++;
                    if(j==line[i].length())
                        break;
                }
                temp.push_back(tempCode);
            }
        }
        codeLines.push_back(temp);
    }

    
    
    while(1)
    {
        
        for(int i=0; i<codeLines.size(); i++)
        {
            
            int len = codeLines[i].size();
            if(len!=3)
                continue;

            string first_name = codeLines[i][0];
            string second_name = codeLines[i][1];
            string third_name = codeLines[i][2];

            bool isSecond_var = false;
            for(int i=0; i<second_name.size(); i++) {
                if( second_name[i] == '_' ) 
                    isSecond_var = true;
            }
            for(int i=0; i<second_name.size(); i++) {
                if( second_name[i] == '[' || second_name[i] == ']' )
                    isSecond_var = false; //array type variable
            }
            
            bool isThird_var = false;
            for(int i=0; i<third_name.size(); i++) {
                if( third_name[i] == '_' ) 
                    isThird_var = true;
            }
            for(int i=0; i<third_name.size(); i++) {
                if(third_name[i] == '[' || third_name[i] == ']')
                    isThird_var = false; //array type variable
            }

            bool isSecond_Temp = false;
            if(second_name[0]=='t')
                isSecond_Temp = true;
            for(int i=0; i<second_name.size(); i++) {
                if( second_name[i] == '_' )   //declared variable  
                    isSecond_Temp = false;
            }

            bool isThird_Temp = false;
            if(third_name[0]=='t')
                isThird_Temp = true;
            for(int i=0; i<third_name.size(); i++) {
                if( third_name[i] == '_' )   //declared variable  
                    isThird_Temp = false;
            }




            if(first_name=="MOV" && second_name==third_name)
            {
                /*
                1. MOV X, X  --> delete it
                */
                codeLines.erase(codeLines.begin()+i);
                i--;
                isOptimized = true;
            }
            else if(first_name=="ADD" || first_name=="SUB")
            {
                if(third_name=="0")
                {
                    /*
                    2. ADD/SUB X, 0  --> delete it 
                    */
                    codeLines.erase(codeLines.begin()+i);
                    i--;
                    isOptimized = true;
                }
            }
            else if(i!=codeLines.size()-1)
            {
                if(first_name=="MOV" && (second_name == "AX" || second_name=="BX") && isThird_var)
                {
                    /*
                    3. MOV AX, X 
                       MOV X, AX  --> delete it
                    */
                    if(codeLines[i+1][0]=="MOV" && codeLines[i+1][1]==third_name && codeLines[i+1][2]==second_name)
                    {
                        codeLines.erase(codeLines.begin()+i+1);
                        i++;
                        isOptimized = true;
                    }
                }
                

            }
            
            
        }

        if(isOptimized==false)
            break;
        else
            isOptimized = false;
    }
    

    string optimizedAsmCodee = "";
    for(int i=0; i<codeLines.size(); i++)
    {
        vector<string> pointedLine = codeLines[i];
        for(int j=0; j<pointedLine.size(); j++)
        {
            if(pointedLine.size()==3){
                if(j==1){
                    optimizedAsmCodee += pointedLine[j];
                    optimizedAsmCodee += ", ";
                }
                else{
                    optimizedAsmCodee += pointedLine[j];
                    optimizedAsmCodee += " ";
                }
            }
            else{
                optimizedAsmCodee += pointedLine[j];
                optimizedAsmCodee += " ";
            }
        }

        optimizedAsmCodee += "\n";
        
    }
    return optimizedAsmCodee;
}





////////////////////////////optimization code ends here/////////////////////////////







bool isArray(string s)
{
    bool left = false;
    bool right = false;
    for(int i = 0; i < s.length(); i++)
    {
        if(s[i] == '[')
            left = true;
        if(s[i] == ']' && left==true)
            right = true;
    }
    return left && right;
}

bool checkAssignOp(string type1, string type2){
    bool arrayType1 = isArray(type1);
    bool arrayType2 = isArray(type2);
    /*if(type1.size()>=2){
        if(type1[type1.size()-2]=='[' && type1[type1.size()-1]==']'){
            arrayType1 = true;
        }
    }
    if(type2.size()>=2){
        if(type2[type2.size()-2]=='[' && type2[type2.size()-1]==']'){
            arrayType2 = true;
        }
    }*/

    if(type1=="none" || type2=="none") return true;
    else if(type1=="" || type2=="") return true;
    else if(type1=="void" || type2=="void") return false;
    else if(arrayType1) return false;
    else if(arrayType2) return false;
    else if(type1=="float" && type2=="int") return true;
    else if(type1!=type2) return false;
    else return true;

}

void rulePrint(string leftTerm, string rightTerm){
    fprintf(logfile, "Line %d: %s : %s\n\n", line_count, leftTerm.c_str(), rightTerm.c_str());
}

void logPrint(string tempName){
    fprintf(logfile, "%s\n\n", tempName.c_str());
}

void errorPrint(string errorMsg){
    fprintf(logfile, "Error at line %d: %s\n\n", line_count, errorMsg.c_str());
    fprintf(errorfile, "Error at line %d: %s\n\n", line_count, errorMsg.c_str());
}

string newLabel()
{
	char *lb= new char[4];
	strcpy(lb,"L");
	char b[3];
	sprintf(b,"%d", labelCount);
	labelCount++;
	strcat(lb,b);
	return string(lb);
}

 string newTemp()
{
	/*char *t= new char[4];
	strcpy(t,"t");
	char b[3];
	sprintf(b,"%d", tempVarCount);
	tempVarCount++;
	strcat(t,b);
	return string(t);*/
    tempVarCount++;
    if(tempVarList.size()<tempVarCount){
        tempVarList.push_back(make_pair(string("t")+to_string(tempVarCount), false));
    }
    //prothom available temp var ta return korbo
    for(int i=0; i<tempVarList.size(); i++){
        if(tempVarList[i].second==false){
            tempVarList[i].second=true;
            return tempVarList[i].first;
        }
    }

}

string arrayIndex(string s)
{
    string size = "";
    bool isIndex = false;
    for(int i = 0; i < s.length(); i++)
    {
        if(s[i] == '[')
            isIndex = true;
        else if(s[i] == ']' && isIndex)
            break;
        else if(isIndex)
            size += s[i];
    }
    return size;
}

string getNameWithoutIndex(string s)
{
    string name = "";
    for(int i=0; i<s.length(); i++)
    {
        if(s[i]=='[')
            break;
        else
            name += s[i];
    }
    return name;
}

void deleteTemp(string tempName)
{
    for(int i=0; i<tempVarList.size(); i++){
        if(tempVarList[i].first==tempName){
            tempVarCount--;
            tempVarList[i].second=false;
        }
    }
}


%}


%error-verbose

%token IF ELSE FOR WHILE DO BREAK INT CHAR FLOAT DOUBLE VOID RETURN SWITCH CASE DEFAULT CONTINUE
%token CONST_INT CONST_FLOAT CONST_CHAR ADDOP MULOP INCOP DECOP RELOP ASSIGNOP LOGICOP NOT LPAREN 
%token RPAREN LCURL RCURL LTHIRD RTHIRD COMMA SEMICOLON ID PRINTLN

%nonassoc LOWER_THAN_ELSE 
%nonassoc ELSE


%%

start : program {
                $$ = new SymbolInfo();
                $$->setName($1->getName());
                $$->setType("start");
                $$->setAsmCode("");
                rulePrint("start", "program");
        }

program : program unit {

                string tempName = $1->getName() + $2->getName();
                $$ = new SymbolInfo(tempName, "unit");
                $$->setAsmCode("");
                rulePrint("program", "program unit");
                logPrint(tempName);

        }
	    | unit{
                $$ = new SymbolInfo();
                $$->setType("program");
                $$->setName($1->getName());
                $$->setAsmCode("");
                rulePrint("program", "unit");
                logPrint($$->getName());
        }
	    ;
 
unit : var_declaration {
                $$ = $1;
                $$->setType("unit");
                string _unitST = $1->getName() + "\n"; //to add a new line after every unit
                $$->setName(_unitST);
                $$->setAsmCode("");
                rulePrint("unit", "var_declaration");
                logPrint($$->getName());

     }
     | func_declaration{
                $$ = $1;
                $$->setType("unit");
                string _unitST = $1->getName() + "\n"; //to add a new line after every unit
                $$->setName(_unitST);
                $$->setAsmCode("");
                runningAsmCode += $1->getAsmCode();
                rulePrint("unit", "func_declaration");
                logPrint($$->getName());

     }
     | func_definition{
                $$ = new SymbolInfo();
                $$->setType("unit");
                string _unitST = $1->getName() + "\n"; //to add a new line after every unit
                $$->setName(_unitST);
                $$->setAsmCode("");
                //indentation kora baki
                runningAsmCode += $1->getAsmCode();
                rulePrint("unit", "func_definition");
                logPrint($$->getName());

     }
     ;
     
func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON{
                                string stmt = $1->getName()+ " " + $2->getName() + "(" + $4->getName() + ");";
                                string _id = $2->getName();

                                $$ = new SymbolInfo(stmt,"func_declaration");
                                SymbolInfo *checker = new SymbolInfo();
                                checker = symT.lookup($2->getName()); //need to check all scopetables
                                if(checker!=nullptr){
                                    errorPrint("Multiple Declaration of "+_id);
                                    errorCount++;
                                }
                                else{
                                    SymbolInfo *newFunc = new SymbolInfo(_id, "ID");


                                    int paramsNo = paramsList.size();
                                    for(int i=0; i<paramsNo; i++){
                                        /*
                                            param er type list1 e store hobe
                                            param er name list2 e store hobe
                                        */
                                        string _type = paramsList[i].first;
                                        string _name = paramsList[i].second;
                                        newFunc->insertToList1(_type);
                                        newFunc->insertToList2(_name);
                                        
                                    }

                                    paramsList.clear();

                                    newFunc->setTypeVar($1->getName());
                                    newFunc->setFuncSt("declaration"); //marked func statement type as "declaration"
                                    symT.insertt(newFunc);
                                }


                                string asmcodee = "";
                                asmcodee += $2->getName();
                                asmcodee += " PROC";
                                asmcodee += "\n";
                                asmcodee += $2->getName();
                                asmcodee += " ENDP";
                                asmcodee += "\n";

                                $$->setAsmCode(asmcodee);

                                rulePrint("func_declaration", "type_specifier ID LPAREN parameter_list RPAREN SEMICOLON");
                                logPrint(stmt);
                }
                |type_specifier ID LPAREN parameter_list RPAREN error {
                                /*
                                    Error recovery of func_definition like:
                                    int foo(string a)
                                */
                                string stmt = $1->getName()+ " " + $2->getName() + "(" + $4->getName() + ")";
                                string _id = $2->getName();

                                $$ = new SymbolInfo(stmt,"func_declaration");
                                SymbolInfo *checker = new SymbolInfo();
                                checker = symT.lookup($2->getName()); //need to check all scopetables
                                if(checker!=nullptr){
                                    errorPrint("Multiple Declaration of "+_id);
                                    errorCount++;
                                }
                                else{
                                    SymbolInfo *newFunc = new SymbolInfo(_id, "ID");


                                    int paramsNo = paramsList.size();
                                    for(int i=0; i<paramsNo; i++){
                                        /*
                                            param er type list1 e store hobe
                                            param er name list2 e store hobe
                                        */
                                        string _type = paramsList[i].first;
                                        string _name = paramsList[i].second;
                                        newFunc->insertToList1(_type);
                                        newFunc->insertToList2(_name);
                                        
                                    }

                                    paramsList.clear();

                                    newFunc->setTypeVar($1->getName());
                                    newFunc->setFuncSt("declaration"); //marked func statement type as "declaration"
                                    symT.insertt(newFunc);
                                }



                                rulePrint("func_declaration", "type_specifier ID LPAREN parameter_list RPAREN");
                                logPrint(stmt);

                }
                |type_specifier ID LPAREN parameter_list error RPAREN SEMICOLON {
                                /*
                                    Error recovery of func_definition like:
                                    int foo(int a+b);
                                */
                                string stmt = $1->getName()+ " " + $2->getName() + "(" + $4->getName() + ");";
                                string _id = $2->getName();

                                $$ = new SymbolInfo(stmt,"func_declaration");
                                SymbolInfo *checker = new SymbolInfo();
                                checker = symT.lookup($2->getName()); //need to check all scopetables
                                if(checker!=nullptr){
                                    errorPrint("Multiple Declaration of "+_id);
                                    errorCount++;
                                }
                                else{
                                    SymbolInfo *newFunc = new SymbolInfo(_id, "ID");


                                    int paramsNo = paramsList.size();
                                    for(int i=0; i<paramsNo; i++){
                                        /*
                                            param er type list1 e store hobe
                                            param er name list2 e store hobe
                                        */
                                        string _type = paramsList[i].first;
                                        string _name = paramsList[i].second;
                                        newFunc->insertToList1(_type);
                                        newFunc->insertToList2(_name);
                                        
                                    }

                                    paramsList.clear();

                                    newFunc->setTypeVar($1->getName());
                                    newFunc->setFuncSt("declaration"); //marked func statement type as "declaration"
                                    symT.insertt(newFunc);
                                }



                                rulePrint("func_declaration", "type_specifier ID LPAREN parameter_list RPAREN SEMICOLON");
                                logPrint(stmt);

                }
                | type_specifier ID LPAREN parameter_list error RPAREN error {
                                /*
                                    Error recovery of func_definition like:
                                    int foo(int a+b)
                                */
                                string stmt = $1->getName()+ " " + $2->getName() + "(" + $4->getName() + ")";
                                string _id = $2->getName();

                                $$ = new SymbolInfo(stmt,"func_declaration");
                                SymbolInfo *checker = new SymbolInfo();
                                checker = symT.lookup($2->getName()); //need to check all scopetables
                                if(checker!=nullptr){
                                    errorPrint("Multiple Declaration of "+_id);
                                    errorCount++;
                                }
                                else{
                                    SymbolInfo *newFunc = new SymbolInfo(_id, "ID");


                                    int paramsNo = paramsList.size();
                                    for(int i=0; i<paramsNo; i++){
                                        /*
                                            param er type list1 e store hobe
                                            param er name list2 e store hobe
                                        */
                                        string _type = paramsList[i].first;
                                        string _name = paramsList[i].second;
                                        newFunc->insertToList1(_type);
                                        newFunc->insertToList2(_name);
                                        
                                    }

                                    paramsList.clear();

                                    newFunc->setTypeVar($1->getName());
                                    newFunc->setFuncSt("declaration"); //marked func statement type as "declaration"
                                    symT.insertt(newFunc);
                                }



                                rulePrint("func_declaration", "type_specifier ID LPAREN parameter_list RPAREN");
                                logPrint(stmt);
                }
		        | type_specifier ID LPAREN RPAREN SEMICOLON{
                                string stmt = $1->getName()+ " " + $2->getName() + "();";
                                string _id = $2->getName();
                                
                                $$ = new SymbolInfo(stmt,"func_declaration");
                                //SymbolInfo *checker = new SymbolInfo();
                                SymbolInfo *checker = symT.lookup($2->getName()); //need to check all scopetables
                                if(checker!=nullptr){
                                    errorPrint("Multiple Declaration of "+_id);
                                    errorCount++;
                                }
                                else{
                                    SymbolInfo *newFunc = new SymbolInfo(_id, "ID");
                                    newFunc->setTypeVar($1->getName());
                                    newFunc->setFuncSt("declaration"); //marked func statement type as "declaration"
                                    symT.insertt(newFunc);
                                }


                                string asmcodee = "";
                                asmcodee += $2->getName();
                                asmcodee += " PROC";
                                asmcodee += "\n";
                                asmcodee += $2->getName();
                                asmcodee += " ENDP";
                                asmcodee += "\n";

                                $$->setAsmCode(asmcodee);

                                rulePrint("func_declaration", "type_specifier ID LPAREN RPAREN SEMICOLON");
                                logPrint(stmt);

                }
                | type_specifier ID LPAREN RPAREN error {
                                /*
                                    Error recovery of func_definition like:
                                    int foo()
                                */
                                string stmt = $1->getName()+ " " + $2->getName() + "()";
                                string _id = $2->getName();

                                $$ = new SymbolInfo(stmt,"func_declaration");
                                SymbolInfo *checker = new SymbolInfo();
                                checker = symT.lookup($2->getName()); //need to check all scopetables
                                if(checker!=nullptr){
                                    errorPrint("Multiple Declaration of "+_id);
                                    errorCount++;
                                }
                                else{
                                    SymbolInfo *newFunc = new SymbolInfo(_id, "ID");
                                    newFunc->setTypeVar($1->getName());
                                    newFunc->setFuncSt("declaration"); //marked func statement type as "declaration"
                                    symT.insertt(newFunc);
                                }



                                rulePrint("func_declaration", "type_specifier ID LPAREN RPAREN");
                                logPrint(stmt);
                }
                | type_specifier ID LPAREN error RPAREN SEMICOLON {
                                /*
                                    Error recovery of func_definition like:
                                    int foo(*);
                                */
                                string stmt = $1->getName()+ " " + $2->getName() + "();";
                                string _id = $2->getName();

                                $$ = new SymbolInfo(stmt,"func_declaration");
                                SymbolInfo *checker = new SymbolInfo();
                                checker = symT.lookup($2->getName()); //need to check all scopetables
                                if(checker!=nullptr){
                                    errorPrint("Multiple Declaration of "+_id);
                                    errorCount++;
                                }
                                else{
                                    SymbolInfo *newFunc = new SymbolInfo(_id, "ID");
                                    newFunc->setTypeVar($1->getName());
                                    newFunc->setFuncSt("declaration"); //marked func statement type as "declaration"
                                    symT.insertt(newFunc);
                                }



                                rulePrint("func_declaration", "type_specifier ID LPAREN RPAREN SEMICOLON");
                                logPrint(stmt);
                }
                | type_specifier ID LPAREN error RPAREN error{
                                /*
                                    Error recovery of func_definition like:
                                    int foo(*)
                                */
                                string stmt = $1->getName()+ " " + $2->getName() + "()";
                                string _id = $2->getName();

                                $$ = new SymbolInfo(stmt,"func_declaration");
                                SymbolInfo *checker = new SymbolInfo();
                                checker = symT.lookup($2->getName()); //need to check all scopetables
                                if(checker!=nullptr){
                                    errorPrint("Multiple Declaration of "+_id);
                                    errorCount++;
                                }
                                else{
                                    SymbolInfo *newFunc = new SymbolInfo(_id, "ID");
                                    newFunc->setTypeVar($1->getName());
                                    newFunc->setFuncSt("declaration"); //marked func statement type as "declaration"
                                    symT.insertt(newFunc);
                                }



                                rulePrint("func_declaration", "type_specifier ID LPAREN RPAREN");
                                logPrint(stmt);
                }
		        ;
		 
func_definition : type_specifier ID LPAREN parameter_list RPAREN {
                                string _def = $1->getName() + " " + $2->getName() + "(" + $4->getName() + ")";

                                SymbolInfo *returnedSym = symT.lookup($2->getName());
                                if(returnedSym!=nullptr){
                                    string retSymFuncST = returnedSym->getFuncSt();
                                    string retSymType = returnedSym->getTypeVar();
                                    if(retSymFuncST!="declaration"){
                                        errorPrint("Multiple Declaration of " + $2->getName());
                                        errorCount++;
                                    }
                                    else if(retSymFuncST=="declaration" && retSymType!=$1->getName()){
                                        errorPrint("Return type mismatch with function declaration in function "+$2->getName());
                                        errorCount++;

                                    }
                                    else if(retSymFuncST=="declaration" && retSymType==$1->getName()){
                                        vector<string> decParamsTypeList = returnedSym->getList1(); //type list of paramsList in declaration
                                        if(decParamsTypeList.size() == paramsList.size()){
                                            bool checker = true;
                                            for(int i=0; i<paramsList.size(); i++){
                                                string _paramType = paramsList[i].first;
                                                if(decParamsTypeList[i]!=_paramType){
                                                    int x = i+1;
                                                    errorPrint(x + "th argument mismatch in function "+$2->getName());
                                                    errorCount++;
                                                    checker = false;
                                                    break;

                                                }
                                            }
                                            if(checker == true){
                                                returnedSym->setFuncSt("definition");
                                            }
                                        }
                                        else{
                                            errorPrint("Total number of arguments mismatch with declaration in function "+$2->getName());
                                            errorCount++;
                                        }
                                        decParamsTypeList.clear();
                                    }
                                }
                                else{
                                    SymbolInfo *symbol = new SymbolInfo($2->getName(), "ID");
                                    int params_no = paramsList.size();
                                    for(int i=0; i<params_no; i++){
                                        string paramsType = paramsList[i].first;
                                        string paramsName = paramsList[i].second;
                                        symbol->insertToList1(paramsType);
                                        symbol->insertToList2(paramsName);
                                    }
                                    symbol->setTypeVar($1->getName());
                                    symbol->setFuncSt("definition");
                                    symT.insertt(symbol);
                                    runningProc = $2->getName();
                                    //cout<<symbol->getTypeVar()<<" "<<symbol->getName()<<endl;
                                    
                                }


                                $$ = new SymbolInfo(_def, "func_definition_st");

                }
                compound_statement {
                                string _name = $6->getName() + $7->getName();
                                $$ = new SymbolInfo(_name, "func_definition");
                                string asmcodee;
                                asmcodee = $2->getName();
                                asmcodee += " PROC";
                                asmcodee += "\n";
                                asmcodee += $7->getAsmCode();
                                asmcodee += "\n";
                                asmcodee += $2->getName();
                                asmcodee += " ENDP";
                                asmcodee += "\n";

                                $$->setAsmCode(asmcodee);

                                string optasmcodee;
                                optasmcodee = FinalOptimization($7->getAsmCode());
                                asmcodee = $2->getName();
                                asmcodee += " PROC";
                                asmcodee += "\n";
                                asmcodee += optasmcodee;
                                asmcodee += "\n";
                                asmcodee += $2->getName();
                                asmcodee += " ENDP";
                                asmcodee += "\n";

                                runningOptAsmCode +=asmcodee;

                                

                                //runningProc = $2->getName();
                                /* indentation baki */
                                /* Optimization baki */
                                rulePrint("func_definition", "type_specifier ID LPAREN parameter_list RPAREN compound_statement");
                                logPrint(_name);
                               
                }
                | type_specifier ID LPAREN parameter_list error RPAREN {
                                string _def = $1->getName() + " " + $2->getName() + "(" + $4->getName() + ")";

                                SymbolInfo *returnedSym = symT.lookup($2->getName());
                                if(returnedSym!=nullptr){
                                    string retSymFuncST = returnedSym->getFuncSt();
                                    string retSymType = returnedSym->getTypeVar();
                                    if(retSymFuncST!="declaration"){
                                        errorPrint("Multiple Declaration of " + $2->getName());
                                        errorCount++;
                                    }
                                    else if(retSymFuncST=="declaration" && retSymType!=$1->getName()){
                                        errorPrint("Return type mismatch with function declaration in function "+$2->getName());
                                        errorCount++;

                                    }
                                    else if(retSymFuncST=="declaration" && retSymType==$1->getName()){
                                        vector<string> decParamsTypeList = returnedSym->getList1(); //type list of paramsList in declaration
                                        if(decParamsTypeList.size() == paramsList.size()){
                                            bool checker = true;
                                            for(int i=0; i<paramsList.size(); i++){
                                                string _paramType = paramsList[i].first;
                                                if(decParamsTypeList[i]!=_paramType){
                                                    int x = i+1;
                                                    errorPrint(x + "th argument mismatch in function "+$2->getName());
                                                    errorCount++;
                                                    checker = false;
                                                    break;

                                                }
                                            }
                                            if(checker == true){
                                                returnedSym->setFuncSt("definition");
                                            }
                                        }
                                        else{
                                            errorPrint("Total number of arguments mismatch with declaration in function "+$2->getName());
                                            errorCount++;
                                        }
                                        decParamsTypeList.clear();
                                    }
                                }
                                else{
                                    SymbolInfo *symbol = new SymbolInfo($2->getName(), "ID");
                                    int params_no = paramsList.size();
                                    for(int i=0; i<params_no; i++){
                                        string paramsType = paramsList[i].first;
                                        string paramsName = paramsList[i].second;
                                        symbol->insertToList1(paramsType);
                                        symbol->insertToList2(paramsName);
                                    }
                                    symbol->setTypeVar($1->getName());
                                    symbol->setFuncSt("definition");
                                    symT.insertt(symbol);
                                    
                                }


                                $$ = new SymbolInfo(_def, "func_definition_st");

                }
                compound_statement {
                                string _name = $7->getName() + $8->getName();
                                $$ = new SymbolInfo(_name, "func_definition");
                                rulePrint("func_definition", "type_specifier ID LPAREN parameter_list RPAREN compound_statement");
                                logPrint(_name);
                               
                }
                | error LPAREN parameter_list RPAREN {
                                string _name = "error (" + $3->getName()  + ")";
                                $$ = new SymbolInfo(_name, "func_definition_st");
                }
                compound_statement {
                                string _name = $5->getName() + $6->getName();
                                $$ = new SymbolInfo(_name, "func_definition");
                                ErrFunc = false;
                                rulePrint("func_definition", "type_specifier ID LPAREN parameter_list RPAREN compound_statement");
                                logPrint(_name);
                }
		        | type_specifier ID LPAREN RPAREN {
                                string _def = $1->getName() + " " + $2->getName() + "()";

                                SymbolInfo *returnedSym = symT.lookup($2->getName());
                                if(returnedSym!=nullptr){
                                    string retSymFuncST = returnedSym->getFuncSt();
                                    string retSymType = returnedSym->getTypeVar();
                                    if(retSymFuncST!="declaration"){
                                        errorPrint("Multiple Declaration of " + $2->getName());
                                        errorCount++;
                                    }
                                    else if(retSymFuncST=="declaration" && retSymType!=$1->getName()){
                                        errorPrint("Return type mismatch with function declaration in function "+$2->getName());
                                        errorCount++;

                                    }
                                    else if(retSymFuncST=="declaration" && retSymType==$1->getName()){
                                        vector<string> decParamsTypeList = returnedSym->getList1(); //type list of paramsList in declaration
                                        if(decParamsTypeList.size() == 0){
                                            returnedSym->setFuncSt("definition");
                                            
                                        }
                                        else{
                                            errorPrint("Total number of arguments mismatch with declaration in function "+$2->getName());
                                            errorCount++;
                                        }
                                        decParamsTypeList.clear();
                                    }
                                }
                                else{
                                    SymbolInfo *symbol = new SymbolInfo($2->getName(), "ID");
                                    int params_no = paramsList.size();
                                    /*
                                    for(int i=0; i<params_no; i++){
                                        string paramsType = paramsList[i].first;
                                        string paramsName = paramsList[i].second;
                                        symbol->insertToList1(paramsType);
                                        symbol->insertToList2(paramsName);
                                    }
                                    */
                                    symbol->setTypeVar($1->getName());
                                    symbol->setFuncSt("definition");
                                    symT.insertt(symbol);
                                    
                                }
                                runningProc = $2->getName();


                                $$ = new SymbolInfo(_def, "func_definition_st");

                }
                compound_statement {
                                string _name = $5->getName() + $6->getName();
                                $$ = new SymbolInfo(_name, "func_definition");

                                //runningProc = $2->getName();
                                string asmcodee = $6->getAsmCode();
                                
                                

                                if(runningProc == "main")
                                {
                                    
                                    for(int i=0; i<asmcodee.length()-3; i++){
                                        if(asmcodee[i]=='R' && asmcodee[i+1]=='E' && asmcodee[i+2]=='T'){
                                            asmcodee.erase(i,3);
                                            break;
                                        }
                                    }
                                    string asmcodee2 = runningProc;
                                    asmcodee2 += " PROC";
                                    asmcodee2 += "\n";
                                    asmcodee2 += ";initialize DS";
                                    asmcodee2 += "\n";
                                    asmcodee2 += "MOV AX, @DATA";
                                    asmcodee2 += "\n";
                                    asmcodee2 += "MOV DX, AX";
                                    asmcodee2 += "\n";
                                    asmcodee2 += asmcodee;
                                    asmcodee2 += "\n";
                                    asmcodee2 += ";DOS EXIT";
                                    asmcodee2 += "\n";
                                    asmcodee2 += "MOV AH, 4CH";
                                    asmcodee2 += "\n";
                                    asmcodee2 += "INT 21H";
                                    asmcodee2 += "\n";
                                    asmcodee2 += runningProc;
                                    asmcodee2 += " ENDP";
                                    asmcodee2 += "\n";


                                    /*indentation baki*/
                                    /* Optimization baki */

                                    string optasmcodee = runningProc;
                                    optasmcodee += " PROC";
                                    optasmcodee += "\n";
                                    optasmcodee += ";initialize DS";
                                    optasmcodee += "\n";
                                    optasmcodee += "MOV AX, @DATA";
                                    optasmcodee += "\n";
                                    optasmcodee += "MOV DX, AX";
                                    optasmcodee += "\n";
                                    optasmcodee += FinalOptimization(asmcodee);
                                    optasmcodee += "\n";
                                    optasmcodee += ";DOS EXIT";
                                    optasmcodee += "\n";
                                    optasmcodee += "MOV AH, 4CH";
                                    optasmcodee += "\n";
                                    optasmcodee += "INT 21H";
                                    optasmcodee += "\n";
                                    optasmcodee += runningProc;
                                    optasmcodee += " ENDP";
                                    optasmcodee += "\n";


                                    runningOptAsmCode += optasmcodee;
                                    $$->setAsmCode(asmcodee2);
                                    

                                }
                                else
                                {
                                    string asmcodee2 = runningProc;
                                    asmcodee2 += " PROC";
                                    asmcodee2 += "\n";
                                    asmcodee2 += asmcodee;
                                    asmcodee2 += "\n";
                                    asmcodee2 += runningProc;
                                    asmcodee2 += " ENDP";
                                    asmcodee2 += "\n";
                                    /*indentation baki*/
                                    /* Optimization baki */

                                    string optasmcodee = runningProc;
                                    optasmcodee += " PROC";
                                    optasmcodee += "\n";
                                    optasmcodee += FinalOptimization(asmcodee);
                                    optasmcodee += "\n";
                                    optasmcodee += runningProc;
                                    optasmcodee += " ENDP";
                                    optasmcodee += "\n";


                                    runningOptAsmCode += optasmcodee;
                                    $$->setAsmCode(asmcodee2);
                                }
                                
                                
                                rulePrint("func_definition", "type_specifier ID LPAREN RPAREN compound_statement");
                                logPrint(_name);
                }
                | type_specifier ID LPAREN error RPAREN {
                                string _def = $1->getName() + " " + $2->getName() + "()";

                                SymbolInfo *returnedSym = symT.lookup($2->getName());
                                if(returnedSym!=nullptr){
                                    string retSymFuncST = returnedSym->getFuncSt();
                                    string retSymType = returnedSym->getTypeVar();
                                    if(retSymFuncST!="declaration"){
                                        errorPrint("Multiple Declaration of " + $2->getName());
                                        errorCount++;
                                    }
                                    else if(retSymFuncST=="declaration" && retSymType!=$1->getName()){
                                        errorPrint("Return type mismatch with function declaration in function "+$2->getName());
                                        errorCount++;

                                    }
                                    else if(retSymFuncST=="declaration" && retSymType==$1->getName()){
                                        vector<string> decParamsTypeList = returnedSym->getList1(); //type list of paramsList in declaration
                                        if(decParamsTypeList.size() == 0){
                                            returnedSym->setFuncSt("definition");
                                            
                                        }
                                        else{
                                            errorPrint("Total number of arguments mismatch with declaration in function "+$2->getName());
                                            errorCount++;
                                        }
                                        decParamsTypeList.clear();
                                    }
                                }
                                else{
                                    SymbolInfo *symbol = new SymbolInfo($2->getName(), "ID");
                                    int params_no = paramsList.size();
                                    /*
                                    for(int i=0; i<params_no; i++){
                                        string paramsType = paramsList[i].first;
                                        string paramsName = paramsList[i].second;
                                        symbol->insertToList1(paramsType);
                                        symbol->insertToList2(paramsName);
                                    }
                                    */
                                    symbol->setTypeVar($1->getName());
                                    symbol->setFuncSt("definition");
                                    symT.insertt(symbol);
                                    
                                }


                                $$ = new SymbolInfo(_def, "func_definition_st");

                }
                compound_statement {
                                string _name = $6->getName() + $7->getName();
                                $$ = new SymbolInfo(_name, "func_definition");
                                rulePrint("func_definition", "type_specifier ID LPAREN RPAREN compound_statement");
                                logPrint(_name);
                }
                | error {
                                if(ErrFunc==false){
                                    ErrFunc = true;
                                    paramsList.clear();
                                }
                                $$ = new SymbolInfo("error", "func_definition_st");
                }
                compound_statement {
                                ErrFunc = false;
                                string _name = $2->getName() + $3->getName();
                                $$ = new SymbolInfo(_name, "func_definition");
                                rulePrint("func_definition", "type_specifier ID LPAREN RPAREN compound_statement");
                                logPrint(_name);
                }
 		        ;				


parameter_list  : parameter_list COMMA type_specifier ID{
                        pair<string, string> newParam;
                        newParam.first = $3->getName(); //type
                        newParam.second = $4->getName(); //var_name
                        paramsList.push_back(newParam);
                        string newList = $1->getName() + ", " + $3->getName() + " "+ $4->getName();
                        $$ = new SymbolInfo(newList, "parameter_list");
                        rulePrint("parameter_list", "parameter_list COMMA type_specifier ID");
                        logPrint(newList);

                }

                | parameter_list error COMMA type_specifier ID{
                        /*
                            Error recovery of parameter_list like:
                            int foo(int a+b, float c)
                        */
                        pair<string, string> newParam;
                        newParam.first = $4->getName(); //type
                        newParam.second = $5->getName(); //var_name
                        paramsList.push_back(newParam);
                        string newList = $1->getName() + ", " + $4->getName() + " "+ $5->getName();
                        $$ = new SymbolInfo(newList, "parameter_list");
                        rulePrint("parameter_list", "parameter_list COMMA type_specifier ID");
                        logPrint(newList);

                }
                
		        | parameter_list COMMA type_specifier{
                        pair<string, string> newParam;
                        newParam.first = $3->getName(); //type
                        newParam.second = ""; //var_name=empty
                        paramsList.push_back(newParam);
                        string newList = $1->getName() + ", " + $3->getName();
                        $$ = new SymbolInfo(newList, "parameter_list");
                        rulePrint("parameter_list", "parameter_list COMMA type_specifier");
                        logPrint(newList);

                }

                | parameter_list error COMMA type_specifier{
                        /*
                            Error recovery of parameter_list like:
                            int foo(int a+b, float)
                        */
                        pair<string, string> newParam;
                        newParam.first = $4->getName(); //type
                        newParam.second = ""; //var_name=empty
                        paramsList.push_back(newParam);
                        string newList = $1->getName() + ", " + $4->getName();
                        $$ = new SymbolInfo(newList, "parameter_list");
                        rulePrint("parameter_list", "parameter_list COMMA type_specifier");
                        logPrint(newList);

                }

 		        | type_specifier ID{
                        pair<string, string> newParam;
                        newParam.first = $1->getName(); //type
                        newParam.second = $2->getName(); //var_name=empty
                        paramsList.push_back(newParam);
                        string newList = $1->getName() + " " + $2->getName();
                        $$ = new SymbolInfo(newList, "parameter_list");
                        rulePrint("parameter_list", "type_specifier ID");
                        logPrint(newList);

                }
		        | type_specifier{
                        pair<string, string> newParam;
                        newParam.first = $1->getName(); //type
                        newParam.second = ""; //var_name=empty
                        paramsList.push_back(newParam);
                        string newList = $1->getName();
                        $$ = new SymbolInfo(newList, "parameter_list");
                        rulePrint("parameter_list", "type_specifier");
                        logPrint(newList);

                }
 		        ;

 		
compound_statement : LCURL scopeController statements RCURL{
                        string asmcodee2;
                        asmcodee2 = $2->getAsmCode() + $3->getAsmCode();
                        asmcodee2 += "\n";
                        if(RETtoCaller==false)
                        {
                            RETtoCaller = true;
                            //asmcodee2 += "RET";
                            asmcodee2 += "\n";
                        }
                        string compSt = "{\n" + $3->getName() + "\n}";
                        $$ = new SymbolInfo(compSt, "compound_statement");
                        $$->setAsmCode(asmcodee2);
                        rulePrint("compound_statement", "LCURL statements RCURL");
                        logPrint(compSt);
                        symT.printAllScopeTable(logfile);
                        symT.exitScope();

                    }
                    | LCURL scopeController RCURL{
                        string asmcodee2;
                        asmcodee2 = $2->getAsmCode() + $3->getAsmCode();
                        asmcodee2 += "\n";
                        if(RETtoCaller==false)
                        {
                            RETtoCaller = true;
                            //asmcodee2 += "RET";
                            asmcodee2 += "\n";
                        }
                        string compSt = "{}";
                        $$ = new SymbolInfo(compSt, "compound_statement");
                        $$->setAsmCode(asmcodee2);
                        rulePrint("compound_statement", "LCURL RCURL");
                        logPrint(compSt);
                        symT.printAllScopeTable(logfile);
                        symT.exitScope();
                        
                    }
                    | LCURL scopeController statements error RCURL{
                        string compSt = "{\n" + $3->getName() + "\n}";
                        $$ = new SymbolInfo(compSt, "compound_statement");
                        rulePrint("compound_statement", "LCURL statements RCURL");
                        logPrint(compSt);
                        symT.printAllScopeTable(logfile);
                        symT.exitScope();
                    }
                    | LCURL scopeController error statements RCURL {
                        string compSt = "{\n" + $3->getName() + "\n}";
                        $$ = new SymbolInfo(compSt, "compound_statement");
                        rulePrint("compound_statement", "LCURL statements RCURL");
                        logPrint(compSt);
                        symT.printAllScopeTable(logfile);
                        symT.exitScope();
                    }
                    
                    ;
scopeController: {
                bool isParameterized;
                if(paramsList.size()>0){
                    isParameterized = true;
                }
                else{
                    isParameterized = false;
                }
                string asmcodee = "";
                if(isParameterized)
                {
                    asmcodee += "POP AX";
                    asmcodee += "\n";
                    RETtoCaller = false;
                }
                symT.enterScope();
                for(int i=paramsList.size()-1; i>=0; i--){
                    string _varType = paramsList[i].first;
                    string _name = paramsList[i].second;
                    SymbolInfo *symbol = new SymbolInfo(_name, "ID");
                    symbol->setTypeVar(_varType);
                    string paramStPointer = _name;
                    paramStPointer += "_" + symT.getCrntScpTableID();
                    symbol->setStPointer(paramStPointer);

                    asmcodee += "POP " + paramStPointer;
                    asmcodee += "\n";

                    DS += "\t" + paramStPointer + " DW ?";
                    DS += "\n";

                    symbol->markTemp(false);
                    
                    
                    if(symT.insertt(symbol)==false){
                        errorPrint("Multiple Declaration of "+ _name);
                        errorCount++;
                    }
                    
                }
                if(isParameterized){
                    asmcodee += "PUSH AX";
                    asmcodee += "\n";
                }

                $$ = new SymbolInfo();
                $$->setAsmCode(asmcodee);
                paramsList.clear();

            }
            ;
 		    
var_declaration : type_specifier declaration_list SEMICOLON{
                    string varType = $1->getName();
                    string varName = $2->getName();

                    // Error check: varType = void
                    if(varType=="void"){
                        errorCount++;
                        string errormsg = "Variable type can't be void";
                        errorPrint(errormsg);
                    }
                    else{
                        vector<string> list1 = $2->getList1();
                        vector<string> list2 = $2->getList2();
                        
                        for(int i=0; i<list1.size(); i++){
                            SymbolInfo *symbol = new SymbolInfo(list1[i], "ID");
                            string stPointer = list1[i] + "_" + symT.getCrntScpTableID();
                            symbol->setStPointer(stPointer);
                            symbol->markTemp(false);
                            //symbol->setTypeVar(varType+list2[i]);
                            
                            if(list2[i].size()>0){
                                string temp = varType + "[]";
                                symbol->setTypeVar(temp);
                            }
                            else{
                                symbol->setTypeVar(varType);
                            }

                            string typeVar = varType + list2[i];
                            
                            bool arrayT = isArray(typeVar);
                            if(!arrayT){
                                DS += "\t" + stPointer + " DW ? \n";
                            }
                            else{
                                DS += "\t" + stPointer + " DW " + arrayIndex(typeVar) + " DUP (0) \n";
                            }


                              //symbol->setTypeVar($1->getName()+list2[i]);
                            //string newVarType = varType+list2[i];
                            //symbol->setTypeVar(newVarType);
                            if(symT.insertt(symbol)==false){
                                errorCount++;
                                errorPrint("Multiple declaration of "+list1[i]);
                            }
                            //symT->removee("");
                            //cout<<list1[i]<<list2[i]<<endl;
                        }

                        
                    }

                    
                    string st = $1->getName()+ " " + $2->getName() + ";";
                    $$ = new SymbolInfo(st, "var_declaration");
                    $$->setAsmCode("");
                    rulePrint("var_declaration", "type_specifier declaration_list SEMICOLON");
                    logPrint(st);

                }
 		        ;
 		 
type_specifier	: INT{
                    SymbolInfo *newSymbol = new SymbolInfo("int", "type_spec");
                    $$ = newSymbol;
                    rulePrint("type_specifier", "INT");
                    logPrint($$->getName());
                    $$->setAsmCode("");

                }
 		        | FLOAT{
                    SymbolInfo *newSymbol = new SymbolInfo("float", "type_spec");
                    $$ = newSymbol;
                    rulePrint("type_specifier", "FLOAT");
                    logPrint($$->getName());
                    $$->setAsmCode("");

                }
 		        | VOID{
                    SymbolInfo *newSymbol = new SymbolInfo("void", "type_spec");
                    $$ = newSymbol;
                    rulePrint("type_specifier", "VOID");
                    logPrint($$->getName());
                    $$->setAsmCode("");

                }
 		        ;
 		
declaration_list : declaration_list COMMA ID{
                    string new_list = $1->getName()+ "," + $3->getName();
                    $1->insertToList1($3->getName()); //append new id to parent list
                    $1->insertToList2("");
                    $$ = $1;
                    $1->setName(new_list);
                    $$->setName(new_list);
                    rulePrint("declaration_list", "declaration_list COMMA ID");
                    logPrint($$->getName());

                }
                | declaration_list error COMMA ID{
                    /*
                        Error recovery of declaration_list like:
                        int a+b, c;
                    */
                    string new_list = $1->getName()+ "," + $4->getName();
                    $1->insertToList1($4->getName()); //append new id to parent list
                    $1->insertToList2("");
                    $$ = $1;
                    $1->setName(new_list);
                    $$->setName(new_list);
                    rulePrint("declaration_list", "declaration_list COMMA ID");
                    logPrint($$->getName());

                }
                | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD{
                    string new_list = $1->getName() + "," + $3->getName() + "[" + $5->getName() + "]";
                    $1->insertToList1($3->getName()); //append new id to parent list
                    $1->insertToList2("["+$5->getName()+"]"); //mark as array
                    $$ = $1;
                    $1->setName(new_list);
                    $$->setName(new_list);
                    rulePrint("declaration_list", "declaration_list COMMA ID LTHIRD CONST_INT RTHIRD");
                    logPrint($$->getName());
                    
                }
                | declaration_list error COMMA ID LTHIRD CONST_INT RTHIRD{
                    /*
                        Error recovery of declaration_list like:
                        int a+b, c[10];
                    */
                    string new_list = $1->getName() + "," + $4->getName() + "[" + $6->getName() + "]";
                    $1->insertToList1($4->getName()); //append new id to parent list
                    $1->insertToList2("[]"); //mark as array
                    $$ = $1;
                    $1->setName(new_list);
                    $$->setName(new_list);
                    rulePrint("declaration_list", "declaration_list COMMA ID LTHIRD CONST_INT RTHIRD");
                    logPrint($$->getName());
                    
                }
 		        | ID{
                    string new_id = $1->getName();
                    SymbolInfo *newSymbol = new SymbolInfo(new_id, "declaration_list");
                    $$ = newSymbol;
                    $$->insertToList1(new_id); //started a new declaration_list
                    $$->insertToList2("");
                    $$->setAsmCode("");
                    rulePrint("declaration_list", "ID");
                    logPrint($$->getName());

                }
 		        | ID LTHIRD CONST_INT RTHIRD{
                    string new_id = $1->getName() + "[" + $3->getName() + "]";
                    SymbolInfo *newSymbol = new SymbolInfo(new_id, "declaration_list");
                    $$ = newSymbol;
                    $$->insertToList1($1->getName()); //started a new declaration_list
                    $$->insertToList2("["+$3->getName()+"]"); //mark as array
                    $$->setAsmCode("");
                    rulePrint("declaration_list", "ID LTHIRD CONST_INT RTHIRD");
                    logPrint($$->getName());

                }
                | declaration_list COMMA ID LTHIRD CONST_FLOAT RTHIRD{
                    string new_list = $1->getName() + "," + $3->getName() + "[" + $5->getName() + "]";
                    $1->insertToList1($3->getName()); //append new id to parent list
                    $1->insertToList2("[]"); //mark as array
                    $$ = $1;
                    $1->setName(new_list);
                    $$->setName(new_list);
                    rulePrint("declaration_list", "declaration_list COMMA ID LTHIRD CONST_FLOAT RTHIRD");
                    //logPrint($$->getName());
                    errorPrint("Non-Integer Array Size");
                    errorCount++;
                    
                }
                | ID LTHIRD CONST_FLOAT RTHIRD{
                    string new_id = $1->getName() + "[" + $3->getName() + "]";
                    SymbolInfo *newSymbol = new SymbolInfo(new_id, "declaration_list");
                    $$ = newSymbol;
                    $$->insertToList1($1->getName()); //started a new declaration_list
                    $$->insertToList2("[]");
                    rulePrint("declaration_list", "ID LTHIRD CONST_FLOAT RTHIRD");
                    //logPrint($$->getName());
                    errorPrint("Non-Integer Array Size");
                    errorCount++;
                }
                | ID LTHIRD RTHIRD{
                    string new_id = $1->getName() + "[]";
                    SymbolInfo *newSymbol = new SymbolInfo(new_id, "declaration_list");
                    $$ = newSymbol;
                    $$->insertToList1($1->getName()); //started a new declaration_list
                    $$->insertToList2("[]");
                    $$->setAsmCode("");
                    rulePrint("declaration_list", "ID LTHIRD RTHIRD");
                    //logPrint($$->getName());
                    errorPrint("Undefined Array Size");
                    errorCount++;
                }
 		        ;
 		  
statements : statement {
                    string _st = $1->getName();
                    $$ = new SymbolInfo(_st, "statements");
                    string asmCode = "";
                    string stmt = "";
                    asmCode += "\n";

                    stmt += ";";
                    for( int i=0; i<_st.size(); i++ ) {
                        stmt += _st[i];
                        if( _st[i]=='\n' && i<_st.size()-1 && _st[i+1]!='\n' ) {
                            stmt += "; ";
                        }
                    }

                    asmCode += stmt;
                    
                    asmCode += "\n";
                    asmCode += $1->getAsmCode();

                    $$->setAsmCode(asmCode);
                    rulePrint("statements","statement");
                    logPrint(_st);

           }
    	   | statements statement {
                    string _st = $1->getName() + "\n" + $2->getName();
                    string _st2 = $2->getName();
                    $$ = new SymbolInfo(_st, "statements");

                    string asmCode = "";
                    string stmt = "";
                    asmCode += $1->getAsmCode();
                    asmCode += "\n";

                    stmt += ";";
                    for( int i=0; i<_st2.size(); i++ ) {
                        stmt += _st2[i];
                        if( _st2[i]=='\n' && i<_st2.size()-1 && _st2[i+1]!='\n' ) {
                            stmt += "; ";
                        }
                    }

                    asmCode += stmt;
                    
                    asmCode += "\n";
                    asmCode += $2->getAsmCode();

                    $$->setAsmCode(asmCode);

                    rulePrint("statements","statements statement");
                    logPrint(_st);

           }
           | statements error statement  {
                    string _st = $1->getName() + "\n" + $3->getName();
                    $$ = new SymbolInfo(_st, "statements");
                    rulePrint("statements","statements statement");
                    logPrint(_st);
           }
	       ;
	   
statement : var_declaration{
                string _stmt = $1->getName();
                $$ = new SymbolInfo(_stmt, "statement");
                $$->setAsmCode("");
                rulePrint("statement", "var_declaration");
                logPrint(_stmt);

        }
        | expression_statement{
                string _stmt = $1->getName();
                $$ = $1;
                rulePrint("statement", "expression_statement");
                logPrint(_stmt);

        }
        | compound_statement{
                string _stmt = $1->getName();
                //$$ = new SymbolInfo(_stmt, "statement");
                $$ = $1;
                rulePrint("statement", "compound_statement");
                logPrint(_stmt);

        }
        | FOR LPAREN expression_statement expression_statement expression RPAREN statement{
                string _stmt = "for(" + $3->getName() + " " + $4->getName() + " " +$5->getName() + ") " + $7->getName();
                $$ = new SymbolInfo(_stmt, "statement");
                string newLabel1 = newLabel();
                string newLabel2 = newLabel();
                string condType = $4->getType();
                string condStPointer = $4->getStPointer();

                string asmcodee = "";
                asmcodee += $3->getAsmCode();
                asmcodee += newLabel1 + ":";
                asmcodee += "\n";
                asmcodee += $4->getAsmCode();
                asmcodee += "\n";
                if(condType == "array")
                {
                    string arrayidx = arrayIndex(condStPointer);
                    //deleteTemp(arrayidx);
                    asmcodee += "MOV BX, " + arrayidx;
                    asmcodee += "\n";
                    asmcodee += "ADD BX, BX"; //jehetu word type
                    asmcodee += "\n";
                    string newStpointer = getNameWithoutIndex(condStPointer);
                    newStpointer += "[BX]";
                    $4->setStPointer(newStpointer);
                }
                //asmcodee += "CONDSTPOINTER: "+$4->getStPointer();
                asmcodee += "CMP " + condStPointer + ", 0";
                asmcodee += "\n";
                asmcodee += "JE " + newLabel2;
                asmcodee += "\n";
                asmcodee += $7->getAsmCode();
                asmcodee += "\n";
                asmcodee += $5->getAsmCode();
                asmcodee += "\n";
                asmcodee += "JMP " + newLabel1;
                asmcodee += "\n";
                asmcodee += newLabel2 + ":";
                asmcodee += "\n";

                $$->setAsmCode(asmcodee);
                

                rulePrint("statement", "FOR LPAREN expression_statement expression_statement expression RPAREN statement");
                logPrint(_stmt);

        }
        | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE{
                string _stmt = "if(" + $3->getName() + ") " + $5->getName();
                string asmcodee = $3->getAsmCode();
                string _type = $3->getType();
                if(_type=="array"){
                    string arrayidx = arrayIndex($3->getStPointer());
                    deleteTemp(arrayidx);
                    asmcodee += "MOV BX, " + arrayidx;
                    asmcodee += "\n";
                    asmcodee += "ADD BX, BX"; //jehetu word type
                    asmcodee += "\n";
                    string newStpointer = getNameWithoutIndex($3->getStPointer());
                    newStpointer += "[BX]";
                    $3->setStPointer(newStpointer);
                }
                string newLabel1 = newLabel();

                asmcodee += "CMP " + $3->getStPointer() + ", 0";
                asmcodee += "\n";
                asmcodee += "JE " + newLabel1;
                asmcodee += "\n";
                asmcodee += $5->getAsmCode();
                asmcodee += "\n";
                asmcodee += newLabel1 + ":";
                asmcodee += "\n";


                $$ = new SymbolInfo(_stmt, "statement");
                $$->setAsmCode(asmcodee);
                rulePrint("statement", "IF LPAREN expression RPAREN statement");
                logPrint(_stmt);

        }
        | IF LPAREN expression RPAREN statement ELSE statement{

                string _stmt = "if(" + $3->getName() + ") " + $5->getName() + "else " + $7->getName();
                string asmcodee = $3->getAsmCode();
                string _type = $3->getType();
                if(_type=="array"){
                    string arrayidx = arrayIndex($3->getStPointer());
                    deleteTemp(arrayidx);
                    asmcodee += "MOV BX, " + arrayidx;
                    asmcodee += "\n";
                    asmcodee += "ADD BX, BX"; //jehetu word type
                    asmcodee += "\n";
                    string newStpointer = getNameWithoutIndex($3->getStPointer());
                    newStpointer += "[BX]";
                    $3->setStPointer(newStpointer);
                }
                string newLabel1 = newLabel();
                string newLabel2 = newLabel();

                asmcodee += "CMP " + $3->getStPointer() + ", 0";
                asmcodee += "\n";
                asmcodee += "JE " + newLabel1;
                asmcodee += "\n";
                asmcodee += $5->getAsmCode();
                asmcodee += "\n";
                asmcodee += "JMP " + newLabel2;
                asmcodee += "\n";
                asmcodee += newLabel1 + ":";
                asmcodee += "\n";
                asmcodee += $7->getAsmCode();
                asmcodee += "\n";
                asmcodee += newLabel2 + ":";
                asmcodee += "\n";


                $$ = new SymbolInfo(_stmt, "statement");
                $$->setAsmCode(asmcodee);
                rulePrint("statement", "IF LPAREN expression RPAREN statement ELSE statement");
                logPrint(_stmt);
        }
        | WHILE LPAREN expression RPAREN statement{
                string _stmt = "while(" + $3->getName() + ") " + $5->getName();
                $$ = new SymbolInfo(_stmt, "statement");

                string newLabel1 = newLabel();
                string newLabel2 = newLabel();
                string condType = $3->getType();
                string condStPointer = $3->getStPointer();

                string asmcodee = "";
                
                asmcodee += newLabel1 + ":";
                asmcodee += "\n";
                asmcodee += $3->getAsmCode();
                asmcodee += "\n";
                if(condType == "array")
                {
                    string arrayidx = arrayIndex(condStPointer);
                    //deleteTemp(arrayidx);
                    asmcodee += "MOV BX, " + arrayidx;
                    asmcodee += "\n";
                    asmcodee += "ADD BX, BX"; //jehetu word type
                    asmcodee += "\n";
                    string newStpointer = getNameWithoutIndex(condStPointer);
                    newStpointer += "[BX]";
                    $3->setStPointer(newStpointer);
                }
                asmcodee += "CMP " + condStPointer + ", 0";
                asmcodee += "\n";
                asmcodee += "JE " + newLabel2;
                asmcodee += "\n";
                asmcodee += $5->getAsmCode();
                asmcodee += "\n";
                asmcodee += "JMP " + newLabel1;
                asmcodee += "\n";
                asmcodee += newLabel2 + ":";
                asmcodee += "\n";

                $$->setAsmCode(asmcodee);

                rulePrint("statement", "WHILE LPAREN expression RPAREN statement");
                logPrint(_stmt);

        }
        | PRINTLN LPAREN ID RPAREN SEMICOLON{
                SymbolInfo *retSymbol = symT.lookup($3->getName());
                string asmcodee = "";
                if(retSymbol==nullptr){
                    errorPrint("Undeclared Variable: " + $3->getName());
                    errorCount++;
                }
                else{
                    asmcodee += "PUSH " + retSymbol->getStPointer();
                    asmcodee += "\n";
                }
                asmcodee += "CALL PRINTproc";
                asmcodee += "\n";
                string _stmt = "println(" + $3->getName() + ");";
                $$ = new SymbolInfo(_stmt, "statement");
                $$->setAsmCode(asmcodee);
                rulePrint("statement", "PRINTLN LPAREN ID RPAREN SEMICOLON");
                logPrint(_stmt);

        }
        | RETURN expression SEMICOLON{
                string _st = "return " + $2->getName() + ";";
                string asmcodee = $2->getAsmCode();
                RETtoCaller = true;

                if($2->getType()=="array"){
                    string arrayidx = arrayIndex($2->getStPointer());
                    deleteTemp(arrayidx);
                    asmcodee += "MOV BX, " + arrayidx;
                    asmcodee += "\n";
                    asmcodee += "ADD BX, BX"; //jehetu word type
                    asmcodee += "\n";
                    string newStpointer = getNameWithoutIndex($2->getStPointer());
                    newStpointer += "[BX]";
                    $2->setStPointer(newStpointer);
                }

                asmcodee += "MOV BP, SP";
                asmcodee += "\n";
                asmcodee += "MOV AX, " + $2->getStPointer();
                asmcodee += "\n";
                asmcodee += "MOV [BP+2], AX";   
                asmcodee += "\n";
                asmcodee += "RET";
                asmcodee += "\n";
                

                $$ = new SymbolInfo(_st, "statement");
                $$->setAsmCode(asmcodee);
                rulePrint("statement", "RETURN expression SEMICOLON");
                logPrint(_st);

        }
        ;
	  
expression_statement : SEMICOLON{
                            $$ = new SymbolInfo(";", "expression_statement");
                            $$->setAsmCode("");
                            rulePrint("expression_statement", "SEMICOLON");
                            logPrint(";");

                    }
			        | expression SEMICOLON {
                            string _st = $1->getName() + ";";
                            $$ = new SymbolInfo(_st, $1->getType());
                            $$->setAsmCode($1->getAsmCode());
                            $$->setTypeVar($1->getTypeVar());
                            $$->setStPointer($1->getStPointer());
                            rulePrint("expression_statement", "expression SEMICOLON");
                            logPrint(_st);
                    }
			        ;
	  
variable : ID {
                string _name = $1->getName();
                SymbolInfo *existingVar = symT.lookup(_name); //find if variable is declared
                if(existingVar!=nullptr){
                    $$ = existingVar;
                }
                else{
                    SymbolInfo *errorVar = new SymbolInfo(_name, "not array");
                    $$ = errorVar;
                    //$$->setTypeVar("none");
                    string eMsg = "Undeclared Variable '"+ _name +"'";
                    errorPrint(eMsg);
                    errorCount++;
                    //cout<<errorVar->getTypeVar()<<endl;
                }
                $$->setAsmCode("");
                $$->setType("not array");
                rulePrint("Variable", "ID");
                logPrint(_name);

        }		
	    | ID LTHIRD expression RTHIRD {
                string _name = $1->getName() + "[" + $3->getName() + "]";
                SymbolInfo *existingVar = symT.lookup($1->getName()); //find if variable is declared
                string existingVarType = existingVar->getTypeVar();
                string indexType = $3->getTypeVar();
                SymbolInfo *newVar = new SymbolInfo(_name, "array");
                if(indexType!="int"){
                    errorPrint("Expression inside third brackets not an integer");
                    errorCount++;
                }
                if(existingVar!=nullptr){
                    if(existingVarType=="int[]"){
                        $$ = newVar;
                        $$->setTypeVar("int");
                    }
                    else if(existingVarType=="float[]"){
                        $$ = newVar;
                        $$->setTypeVar("float");
                    }
                    else if(existingVarType=="char[]"){
                        $$ = newVar;
                        $$->setTypeVar("char");
                    }
                    else{
                        $$ = newVar;
                        string eMsg = "Type mismatch. Variable '" + $1->getName() + "' is not an array";
                        errorPrint(eMsg);
                        errorCount++;
                    }
                }
                else{
                    
                    $$ = newVar;
                    string eMsg = "Undeclared Variable '"+ _name +"'";
                    errorPrint(eMsg);
                    errorCount++;
                }
                string stPointer = existingVar->getStPointer();
                stPointer += "[" + $3->getStPointer() + "]";
                $$->markTemp(false);
                $$->setStPointer(stPointer);
                $$->setAsmCode($3->getAsmCode());
                rulePrint("Variable", "ID LTHIRD expression RTHIRD");
                logPrint(_name);

        }
        | ID LTHIRD RTHIRD {
                string _name = $1->getName() + "[]";
                SymbolInfo *existingVar = symT.lookup($1->getName()); //find if variable is declared
                string existingVarType = existingVar->getTypeVar();
                //string indexType = $3->getTypeVar();
                SymbolInfo *newVar = new SymbolInfo(_name, "variable");
                
                if(existingVar!=nullptr){
                    if(existingVarType=="int[]"){
                        $$ = newVar;
                        $$->setTypeVar("int");
                    }
                    else if(existingVarType=="float[]"){
                        $$ = newVar;
                        $$->setTypeVar("float");
                    }
                    else if(existingVarType=="char[]"){
                        $$ = newVar;
                        $$->setTypeVar("char");
                    }
                    else{
                        $$ = newVar;
                        string eMsg = "Type mismatch. Variable '" + $1->getName() + "' is not an array";
                        errorPrint(eMsg);
                        errorCount++;
                    }
                }
                else{
                    
                    $$ = newVar;
                    string eMsg = "Undeclared Variable '"+ _name +"'";
                    errorPrint(eMsg);
                    errorCount++;
                }
                rulePrint("Variable", "ID LTHIRD RTHIRD");
                logPrint(_name);
                errorPrint("Invalid Array Index, Array index missing");
                errorCount++;
        }
	    ;
	 
expression : logic_expression {
                    $$ = $1;
                    //cout<<"STPOINTER:"<<$$->getStPointer()<<endl;
                    rulePrint("expression","logic_expression");
                    logPrint($1->getName());

            }
	        | variable ASSIGNOP logic_expression {
                    string _exp = $1->getName() + "=" +$3->getName();
                    $$ = new SymbolInfo(_exp, "expression");
                    if($1->getType()=="func_declaration"||$1->getType()=="func_definition"||$3->getType()=="func_declaration"||$3->getType()=="func_definition"){
                        errorPrint("= operator can not have function declaration/definition as operands");
                        errorCount++;
                        $$->setTypeVar("none");
                    }
                    
                    else if(checkAssignOp($1->getTypeVar(), $3->getTypeVar())==false){
                        //cout<<$1->getTypeVar()<<endl;
                        errorPrint("Type mismatch");
                        errorCount++;
                        $$->setTypeVar($1->getTypeVar());
                    }
                    else{
                        SymbolInfo *syym = symT.lookup($1->getName());
                        if(syym!=nullptr)
                            $$->setTypeVar(syym->getTypeVar());
                    }




                    string asmcodee = $1->getAsmCode() + $3->getAsmCode();
                    if($1->getType()=="array"){
                        string arrayidx = arrayIndex($1->getStPointer());
                        //deleteTemp(arrayidx);
                        asmcodee += "MOV BX, " + arrayidx;
                        asmcodee += "\n";
                        asmcodee += "ADD BX, BX"; //jehetu word type
                        asmcodee += "\n";
                        string newStpointer = getNameWithoutIndex($1->getStPointer());
                        newStpointer += "[BX]";
                        $1->setStPointer(newStpointer);
                    }

                    if($3->getType()=="array"){
                        string arrayidx = arrayIndex($3->getStPointer());
                        deleteTemp(arrayidx);
                        asmcodee += "MOV DI, " + arrayidx;
                        asmcodee += "\n";
                        asmcodee += "ADD DI, DI"; //jehetu word type
                        asmcodee += "\n";
                        string newStpointer = getNameWithoutIndex($3->getStPointer());
                        newStpointer += "[DI]";
                        $3->setStPointer(newStpointer);
                    }

                    //move $3 to $1
                    asmcodee += "MOV AX, " + $3->getStPointer();
                    asmcodee += "\n";
                    asmcodee += "MOV " + $1->getStPointer() + ", AX";
                    asmcodee += "\n";
                    if($3->isTemp()){
                        deleteTemp($3->getStPointer());
                    }

                    $$->setAsmCode(asmcodee);
                    $$->markTemp(false); //jehetu eta ekta permanent var e store hocche
                    $$->setStPointer($1->getStPointer());
                    


                    rulePrint("expression", "variable ASSIGNOP logic_expression");
                    logPrint(_exp);
            
            }
	        ;
			
logic_expression : rel_expression {
                        $$ = $1;
                        //cout<<"STPOINTER:"<<$$->getStPointer()<<endl;
                        rulePrint("logic_expression","rel_expression");
                        logPrint($1->getName());

                }
		        | rel_expression LOGICOP rel_expression {
                        string expType = $1->getTypeVar();
                        string expTypeRight = $3->getTypeVar(); 
                        string _exp = $1->getName() + $2->getName() + $3->getName();
                        //cout<<expType<<endl;
                        //cout<<termType<<endl;

                        SymbolInfo *newExp = new SymbolInfo(_exp, "logic_expression");
                        $$ = newExp;
                        

                        if(expType=="void" || expTypeRight=="void"){
                            errorPrint("Void type operand detected!");
                            errorCount++;
                            $$->setTypeVar("void");
                        }
                        else{
                            $$->setTypeVar("int");
                        }

                        //asm code starts here
                        string newLabel1 = newLabel();
                        string newLabel2 = newLabel();
                        string asmcodee = $1->getAsmCode() + $3->getAsmCode();
                        if($1->getType()=="array"){
                            string arrayidx = arrayIndex($1->getStPointer());
                            deleteTemp(arrayidx);
                            asmcodee += "MOV BX, " + arrayidx;
                            asmcodee += "\n";
                            asmcodee += "ADD BX, BX"; //jehetu word type
                            asmcodee += "\n";
                            string newStpointer = getNameWithoutIndex($1->getStPointer());
                            newStpointer += "[BX]";
                            $1->setStPointer(newStpointer);
                        }

                        if($3->getType()=="array"){
                            string arrayidx = arrayIndex($3->getStPointer());
                            deleteTemp(arrayidx);
                            asmcodee += "MOV DI, " + arrayidx;
                            asmcodee += "\n";
                            asmcodee += "ADD DI, DI"; //jehetu word type
                            asmcodee += "\n";
                            string newStpointer = getNameWithoutIndex($3->getStPointer());
                            newStpointer += "[DI]";
                            $3->setStPointer(newStpointer);
                        }

                        //$1 ar $3 jodi tempVar hishebe thake taile tader use korbo
                        //nahoi new temp var create krte hobe
                        string stpointer1 = $1->getStPointer();
                        string stpointer3 = $3->getStPointer();
                        string mainStPointer;
                        if($1->isTemp()==true)
                        {
                            mainStPointer = stpointer1;
                        }
                        else if($3->isTemp()==true)
                        {
                            mainStPointer = stpointer3;
                        }
                        else
                        {
                            mainStPointer = newTemp();
                        }
                        if($1->isTemp()==true && $3->isTemp()==true)
                        {
                            deleteTemp(stpointer3);
                            //jehetu $1 er temp var takei use korchi, so $3 er temp dorkar nai ar
                        }
                        $$->setStPointer(mainStPointer);

                        string oprtr = $2->getName();
                        string cmp;
                        string labelAssign1;
                        string labelAssign2;

                        if(oprtr=="||")
                        {
                            cmp = "1";
                            labelAssign1 = "1";
                            labelAssign2 = "0";

                        }
                        else if(oprtr=="&&")
                        {
                            cmp = "0";
                            labelAssign1 = "0";
                            labelAssign2 = "1";
                        }
                        asmcodee += "CMP " + stpointer1 + ", " + cmp;
                        asmcodee += "\n";
                        asmcodee += "JE " + newLabel1;
                        asmcodee += "\n";
                        asmcodee += "CMP " + stpointer3 + ", " + cmp;
                        asmcodee += "\n";
                        asmcodee += "JE " + newLabel1;
                        asmcodee += "\n";
                        asmcodee += "MOV " + mainStPointer + ", " + labelAssign2;
                        asmcodee += "\n";
                        asmcodee += "JMP " + newLabel2;
                        asmcodee += "\n";
                        asmcodee += newLabel1 + ":";
                        asmcodee += "\n";
                        asmcodee += "MOV " + mainStPointer + ", " + labelAssign1;
                        asmcodee += "\n";
                        asmcodee += newLabel2 + ":";
                        asmcodee += "\n";

                        $$->setAsmCode(asmcodee);
                        
                        rulePrint("logic_expression", "rel_expression LOGICOP rel_expression");
                        logPrint(_exp);

                }
		        ;
			
rel_expression	: simple_expression {
                        $$ = $1;
                        rulePrint("rel_expression", "simple_expression");
                        logPrint($1->getName());

                }
                | simple_expression RELOP simple_expression	{
                        string expType = $1->getTypeVar();
                        string expTypeRight = $3->getTypeVar(); 
                        string _exp = $1->getName() + $2->getName() + $3->getName();
                        //cout<<expType<<endl;
                        //cout<<termType<<endl;

                        bool arrayExp = isArray(expType);
                        bool arrayExpRight = isArray(expTypeRight);
                        SymbolInfo *newExp = new SymbolInfo(_exp, "rel_expression");
                        $$ = newExp;
                        
                        /*if(expType.size()>=2){
                            if(expType[expType.size()-2]=='[' && expType[expType.size()-1]==']'){
                                arrayExp = true;
                            }
                        }

                        if(expTypeRight.size()>=2){
                            if(expTypeRight[expTypeRight.size()-2]=='[' && expTypeRight[expTypeRight.size()-1]==']'){
                                arrayExpRight = true;
                            }
                        }*/
                        

                        if(expType=="void" || expTypeRight=="void"){
                            errorPrint("Void type operand detected!");
                            errorCount++;
                            
                        }
                        else if(arrayExp && arrayExpRight){
                            $$->setTypeVar("int");
                        }
                        else if(arrayExp){
                            errorPrint("Incompatible Operands");
                            errorCount++;
                        }
                        else if(arrayExpRight){
                            errorPrint("Incompatible Operands");
                            errorCount++;
                        }
                        else{
                            $$->setTypeVar("int");
                        }


                        //asm code starts here
                        string newLabel1 = newLabel();
                        string newLabel2 = newLabel();
                        string asmcodee = $1->getAsmCode() + $3->getAsmCode();
                        if($1->getType()=="array"){
                            string arrayidx = arrayIndex($1->getStPointer());
                            //deleteTemp(arrayidx);
                            asmcodee += "MOV BX, " + arrayidx;
                            asmcodee += "\n";
                            asmcodee += "ADD BX, BX"; //jehetu word type
                            asmcodee += "\n";
                            string newStpointer = getNameWithoutIndex($1->getStPointer());
                            newStpointer += "[BX]";
                            $1->setStPointer(newStpointer);
                        }

                        if($3->getType()=="array"){
                            string arrayidx = arrayIndex($3->getStPointer());
                            //deleteTemp(arrayidx);
                            asmcodee += "MOV DI, " + arrayidx;
                            asmcodee += "\n";
                            asmcodee += "ADD DI, DI"; //jehetu word type
                            asmcodee += "\n";
                            string newStpointer = getNameWithoutIndex($3->getStPointer());
                            newStpointer += "[DI]";
                            $3->setStPointer(newStpointer);
                        }

                        //$1 ar $3 jodi tempVar hishebe thake taile tader use korbo
                        //nahoi new temp var create krte hobe
                        string stpointer1 = $1->getStPointer();
                        string stpointer3 = $3->getStPointer();
                        string mainStPointer;
                        if($1->isTemp()==true)
                        {
                            mainStPointer = stpointer1;
                        }
                        else if($3->isTemp()==true)
                        {
                            mainStPointer = stpointer3;
                        }
                        else
                        {
                            mainStPointer = newTemp();
                        }
                        if($1->isTemp()==true && $3->isTemp()==true)
                        {
                            deleteTemp(stpointer3);
                            //jehetu $1 er temp var takei use korchi, so $3 er temp dorkar nai ar
                        }
                        $$->setStPointer(mainStPointer);
                        //cout<<"mainStPointer"<<mainStPointer<<endl;

                        string jInstruction;
                        string oprtr = $2->getName();
                        if(oprtr=="<")
                            jInstruction = "JL";
                        else if(oprtr==">")
                            jInstruction = "JG";
                        else if(oprtr=="<=")
                            jInstruction = "JLE";
                        else if(oprtr==">=")
                            jInstruction = "JGE";
                        else if(oprtr=="==")
                            jInstruction = "JE";
                        else if(oprtr=="!=")
                            jInstruction = "JNE";
                        
                        asmcodee += "MOV AX, " + stpointer1;
                        asmcodee += "\n";
                        asmcodee += "CMP AX, " + stpointer3;
                        asmcodee += "\n";
                        asmcodee += jInstruction + " " + newLabel1;
                        asmcodee += "\n";
                        asmcodee += "MOV " + mainStPointer + ", 0";
                        asmcodee += "\n";
                        asmcodee += "JMP " + newLabel2;
                        asmcodee += "\n";
                        asmcodee += newLabel1 + ":";
                        asmcodee += "\n";
                        asmcodee += "MOV " + mainStPointer + ", 1";
                        asmcodee += "\n";
                        asmcodee += newLabel2 + ":";
                        asmcodee += "\n";

                        $$->setAsmCode(asmcodee);

                        
                        rulePrint("rel_expression", "simple_expression RELOP simple_expression");
                        logPrint(_exp);
                    
                }
                ;
				
simple_expression : term {
                            $$ = $1;
                            rulePrint("simple_expression", "term");
                            logPrint($1->getName());

                    }
		            | simple_expression ADDOP term {
                            
                            string expType = $1->getTypeVar();
                            string termType = $3->getTypeVar();
                            string _exp = $1->getName() + $2->getName() + $3->getName();
                            //cout<<expType<<endl;
                            //cout<<termType<<endl;

                            bool arrayExp = isArray(expType);
                            bool arrayTerm = isArray(termType);
                            SymbolInfo *newExp = new SymbolInfo(_exp, "simple_expression");
                            $$ = newExp;
                            $$->setAsmCode("");
                            
                            /*if(expType.size()>=2){
                                if(expType[expType.size()-2]=='[' && expType[expType.size()-1]==']'){
                                    arrayExp = true;
                                }
                            }

                            if(termType.size()>=2){
                                if(termType[termType.size()-2]=='[' && termType[termType.size()-1]==']'){
                                    arrayTerm = true;
                                }
                            }*/

                            if(expType=="void" || termType=="void"){
                                errorPrint("Void type operand detected!");
                                errorCount++;
                                
                            }
                            else if(arrayExp && termType=="int"){
                                $$->setTypeVar(expType);
                            }
                            else if(expType=="int" && arrayTerm){
                                $$->setTypeVar(termType);
                            }
                            else if(arrayExp || arrayTerm){
                                errorPrint("Incompatible Operands");
                                errorCount++;
                            }
                            else if(expType=="float" || termType=="float"){
                                $$->setTypeVar("float");
                            }
                            else{
                                $$->setTypeVar("int");
                            }




                            string asmcodee = $1->getAsmCode() + $3->getAsmCode();
                            if($1->getType()=="array"){
                                string arrayidx = arrayIndex($1->getStPointer());
                                deleteTemp(arrayidx);
                                asmcodee += "MOV BX, " + arrayidx;
                                asmcodee += "\n";
                                asmcodee += "ADD BX, BX"; //jehetu word type
                                asmcodee += "\n";
                                string newStpointer = getNameWithoutIndex($1->getStPointer());
                                newStpointer += "[BX]";
                                $1->setStPointer(newStpointer);
                            }

                            if($3->getType()=="array"){
                                string arrayidx = arrayIndex($3->getStPointer());
                                deleteTemp(arrayidx);
                                asmcodee += "MOV DI, " + arrayidx;
                                asmcodee += "\n";
                                asmcodee += "ADD DI, DI"; //jehetu word type
                                asmcodee += "\n";
                                string newStpointer = getNameWithoutIndex($3->getStPointer());
                                newStpointer += "[DI]";
                                $3->setStPointer(newStpointer);
                            }

                            //$1 ar $3 jodi tempVar hishebe thake taile tader use korbo
                            //nahoi new temp var create krte hobe
                            string mainStPointer;
                            if($1->isTemp()==true)
                            {
                                mainStPointer = $1->getStPointer();
                            }
                            else if($3->isTemp()==true)
                            {
                                mainStPointer = $3->getStPointer();
                            }
                            else
                            {
                                mainStPointer = newTemp();
                            }
                            $$->setStPointer(mainStPointer);

                            //addop code
                            asmcodee += "MOV AX, " + $1->getStPointer();
                            asmcodee += "\n";
                            if($2->getName()=="+"){
                                asmcodee += "ADD AX, " + $3->getStPointer();
                            }
                            else if($2->getName()=="-"){
                                asmcodee += "SUB AX, " + $3->getStPointer();
                            }
                            asmcodee += "\n";
                            asmcodee += "MOV " + mainStPointer + ", AX";
                            asmcodee += "\n";


                            
                            $$->setAsmCode(asmcodee);

                            
                            rulePrint("simple_expression", "simple_expression ADDOP term");
                            logPrint(_exp);

                    }
		            ;
					
term :	unary_expression{
                $$ = $1;
                rulePrint("term", "unary_expression");
                logPrint($1->getName());

     }
     |  term MULOP unary_expression{
                
                string expType = $3->getTypeVar(); //unary_expression type
                string termType = $1->getTypeVar();
                string _term = $1->getName() + $2->getName() + $3->getName();
                //cout<<termType<<endl;
                //cout<<expType<<endl;

                bool arrayExp = isArray(expType);
                bool arrayTerm = isArray(termType);
                SymbolInfo *newExp = new SymbolInfo(_term, "term");
                $$ = newExp;
                
                /*if(expType.size()>=2){
                    if(expType[expType.size()-2]=='[' && expType[expType.size()-1]==']'){
                        arrayExp = true;
                    }
                }

                if(termType.size()>=2){
                    if(termType[termType.size()-2]=='[' && termType[termType.size()-1]==']'){
                        arrayTerm = true;
                    }
                }*/
                

                if(termType=="void" || expType=="void"){
                    errorPrint("Void type operand detected!");
                    errorCount++;
                }
                else if(arrayTerm || arrayExp){
                    errorPrint("Incompatible Operands");
                    errorCount++;
                }
                else if((termType!="int" || expType!="int") && $2->getName()=="%"){
                    errorPrint("Modulus operator cannot have non-integer operands");
                    errorCount++;
                    $$->setTypeVar("int");
                }
                else if(($2->getName()=="%") && $3->getName()=="0"){
                    errorPrint("Modulus by Zero");
                    errorCount++;
                    $$->setTypeVar("int");
                }
                else if(termType=="float" || expType=="float"){
                    $$->setTypeVar("float");
                }
                else{
                    $$->setTypeVar("int");
                }




                string asmcodee = $1->getAsmCode() + $3->getAsmCode();
                if($1->getType()=="array"){
                    string arrayidx = arrayIndex($1->getStPointer());
                    deleteTemp(arrayidx);
                    asmcodee += "MOV BX, " + arrayidx;
                    asmcodee += "\n";
                    asmcodee += "ADD BX, BX"; //jehetu word type
                    asmcodee += "\n";
                    string newStpointer = getNameWithoutIndex($1->getStPointer());
                    newStpointer += "[BX]";
                    $1->setStPointer(newStpointer);
                }

                if($3->getType()=="array"){
                    string arrayidx = arrayIndex($3->getStPointer());
                    deleteTemp(arrayidx);
                    asmcodee += "MOV DI, " + arrayidx;
                    asmcodee += "\n";
                    asmcodee += "ADD DI, DI"; //jehetu word type
                    asmcodee += "\n";
                    string newStpointer = getNameWithoutIndex($3->getStPointer());
                    newStpointer += "[DI]";
                    $3->setStPointer(newStpointer);
                }

                //$1 ar $3 jodi tempVar hishebe thake taile tader use korbo
                //nahoi new temp var create krte hobe
                string mainStPointer;
                if($1->isTemp()==true)
                {
                    mainStPointer = $1->getStPointer();
                }
                else if($3->isTemp()==true)
                {
                    mainStPointer = $3->getStPointer();
                }
                else
                {
                    mainStPointer = newTemp();
                }
                if($1->isTemp()==true && $3->isTemp()==true)
                {
                    deleteTemp($3->getStPointer());
                    //jehetu $1 er temp var takei use korchi, so $3 er temp dorkar nai ar
                }
                $$->setStPointer(mainStPointer);

                //addop code
                asmcodee += "MOV AX, " + $1->getStPointer();
                asmcodee += "\n";
                asmcodee += "MOV BX, " + $3->getStPointer();
                asmcodee += "\n";
                if($2->getName()=="*"){
                    asmcodee += "IMUL BX"; //multiplied with AX register
                }
                else{
                    //ax dividend, bx divisor, ax quotient, dx remainder
                    asmcodee += "XOR DX, DX";
                    asmcodee += "\n";
                    asmcodee += "IDIV BX";
                }
                asmcodee += "\n";
                if($2->getName()=="%"){
                    asmcodee += "MOV " + mainStPointer + ", DX";
                }
                else{
                    asmcodee += "MOV " + mainStPointer + ", AX";
                }
                
                asmcodee += "\n";


                
                $$->setAsmCode(asmcodee);


                rulePrint("term", "term MULOP unary_expression");
                logPrint(_term);

     }
     ;

unary_expression : ADDOP unary_expression  {
                    string _exp = $1->getName() + $2->getName();
                    string _expType = $2->getTypeVar();
                    string oprtr = $1->getName();
                    if(_expType=="void"){
                        errorPrint("Void type operand detected!");
                        errorCount++;
                    }
                    if(oprtr == "+")
                    {
                        $$= $2;
                    }
                    else
                    {
                        string asmcodee = $2->getAsmCode();
                        string mainStPointer;
                        if($2->getType()=="array"){
                            string arrayidx = arrayIndex($2->getStPointer());
                            //deleteTemp(arrayidx);
                            asmcodee += "MOV BX, " + arrayidx;
                            asmcodee += "\n";
                            asmcodee += "ADD BX, BX"; //jehetu word type
                            asmcodee += "\n";
                            string newStpointer = getNameWithoutIndex($2->getStPointer());
                            newStpointer += "[BX]";
                            $2->setStPointer(newStpointer);
                        }
                        if($2->isTemp()==true)
                        {
                            mainStPointer = $2->getStPointer();
                        }
                        else
                        {
                            mainStPointer = newTemp();
                        }
                        if($2->isTemp()==true)
                        {
                            asmcodee += "NEG " + mainStPointer;
                            asmcodee += "\n";
                        }
                        else
                        {
                            asmcodee += "MOV AX, " + $2->getStPointer();
                            asmcodee += "\n";
                            asmcodee += "NEG AX";
                            asmcodee += "\n";
                            asmcodee += "MOV " + mainStPointer + ", AX";
                            asmcodee += "\n";
                        }
                        $$ = new SymbolInfo(_exp, "unary_expression");
                        $$->setTypeVar(_expType);
                        $$->setStPointer(mainStPointer);
                        $$->setAsmCode(asmcodee);
                    }
                    

                    rulePrint("unary_expression", "ADDOP unary_expression");
                    logPrint(_exp);

                }
		        | NOT unary_expression {
                    string _exp = "!" + $2->getName();
                    string _expType = $2->getTypeVar();
                    if(_expType=="void"){
                        errorPrint("Void type operand detected!");
                        errorCount++;
                    }
                    string asmcodee = $2->getAsmCode();
                    string mainStPointer;
                    if($2->getType()=="array"){
                        string arrayidx = arrayIndex($2->getStPointer());
                        deleteTemp(arrayidx);
                        asmcodee += "MOV BX, " + arrayidx;
                        asmcodee += "\n";
                        asmcodee += "ADD BX, BX"; //jehetu word type
                        asmcodee += "\n";
                        string newStpointer = getNameWithoutIndex($2->getStPointer());
                        newStpointer += "[BX]";
                        $2->setStPointer(newStpointer);
                    }
                    if($2->isTemp()==true)
                    {
                        mainStPointer = $2->getStPointer();
                    }
                    else
                    {
                        mainStPointer = newTemp();
                    }
                    if($2->isTemp()==true)
                    {
                        asmcodee += "NOT " + mainStPointer;
                        asmcodee += "\n";
                    }
                    else
                    {
                        asmcodee += "MOV AX, " + $2->getStPointer();
                        asmcodee += "\n";
                        asmcodee += "NOT AX";
                        asmcodee += "\n";
                        asmcodee += "MOV " + mainStPointer + ", AX";
                        asmcodee += "\n";
                    }
                    $$ = new SymbolInfo(_exp, "unary_expression");
                    $$->setTypeVar(_expType);
                    $$->setStPointer(mainStPointer);
                    $$->setAsmCode(asmcodee);

                    rulePrint("unary_expression", "NOT unary_expression");
                    logPrint(_exp);

                }
		        | factor {
                        $$ = $1;
                        rulePrint("unary_expression", "factor");
                        logPrint($1->getName());

                }
        		;
	
factor	: variable {
                $$ = $1;
                rulePrint("factor", "variable");
                logPrint($1->getName());

        }
        | ID LPAREN argument_list RPAREN{
                string _factr = $1->getName() + "(" + $3->getName() + ")";
                string _id = $1->getName();
                $$ = new SymbolInfo(_factr, "factor");
                
                //cout<<"factor"<<$$->getTypeVar()<<endl;
                SymbolInfo *declaredFunc = symT.lookup(_id);
                string declaredFunc_st;
                if(declaredFunc!=nullptr){
                    declaredFunc_st = declaredFunc->getFuncSt();
                    $$->setTypeVar(declaredFunc->getTypeVar());
                }

                if(declaredFunc==nullptr){
                    errorPrint("Undeclared Function: " + _id);
                    errorCount++;
                }
                else if(declaredFunc_st!="declaration" && declaredFunc_st!="definition"){ //eta function na
                    errorPrint(_id + " not a function");
                    errorCount++;
                }
                else{
                    vector<string> expectedTypes = declaredFunc->getList1();
                    vector<string> argTypes = $3->getList1();
                    int _expSize = expectedTypes.size();
                    int _argSize = argTypes.size();
                    if(_expSize!=_argSize){
                        errorPrint("Total number of arguments mismatch in function "+ _id);
                        errorCount++;
                    }
                    else{
                        for(int i=0; i<_argSize; i++){
                            //string intt = "int";
                            //string floatt = "float";
                            if(expectedTypes[i]=="int" && argTypes[i]!="int"){
                                string eMsg = to_string(i+1) + "th argument mismatch in function "+_id;
                                //string eMsg = "th argument mismatch in function";
                                errorPrint(eMsg);
                                errorCount++;
                                //cout<<expectedTypes[i]<<" "<<argTypes[i]<<endl;
                            }
                            else if(expectedTypes[i]=="float" && argTypes[i]!="float" && argTypes[i]!="int"){
                                string eMsg = to_string(i+1) + "th argument mismatch in function "+_id;
                                //string eMsg = "th argument mismatch in function";
                                errorPrint(eMsg);
                                errorCount++;
                            }
                        }
                    }
                    
                }

                vector<string> allstpointers = symT.getAllSTPointers();
                for(int i=0; i<tempVarList.size(); i++){
                    if(tempVarList[i].second==true){
                        allstpointers.push_back(tempVarList[i].first);
                    }
                }
                
                string newTempVar = newTemp();
                string asmcodee = $3->getAsmCode();
                //asmcodee += runningProc;
                //asmcodee += $1->getName();
                if($1->getName()==runningProc){
                    //recursion handling in caller side before calling function
                    for(int i=0; i<allstpointers.size(); i++){
                        asmcodee += "PUSH " + allstpointers[i];
                        asmcodee += "\n";
                    }
                }

                asmcodee += "PUSH 0"; //marker for return address
                asmcodee += "\n";

                vector<string> argPointerList = $3->getList2();
                for(int i=0; i<argPointerList.size(); i++){
                    string argPointer = argPointerList[i];
                    //$$->insertToList2(argPointerList[i]);
                    bool ar = isArray(argPointerList[i]);
                    if(ar){
                        string arrayidx = arrayIndex(argPointerList[i]);
                        //deleteTemp(arrayidx);
                        asmcodee += "MOV BX, " + arrayidx;
                        asmcodee += "\n";
                        asmcodee += "ADD BX, BX"; //jehetu word type
                        asmcodee += "\n";
                        string newStpointer = getNameWithoutIndex(argPointerList[i]);
                        newStpointer += "[BX]";
                        //$1->setStPointer(newStpointer);
                        argPointer = newStpointer;
                    }
                    asmcodee += "PUSH " + argPointer;
                    asmcodee += "\n";
                }
                asmcodee += "CALL " + _id;
                asmcodee += "\n";
                asmcodee += "POP " + newTempVar;
                asmcodee += "\n";
                $$->setStPointer(newTempVar);
                if(_id==runningProc){
                    //recursion handling in caller side before calling function
                    for(int i=allstpointers.size()-1; i>=0; i--){
                        asmcodee += "POP " + allstpointers[i];
                        asmcodee += "\n";
                    }
                }

                $$->setAsmCode(asmcodee);

                rulePrint("factor", "ID LPAREN argument_list RPAREN");
                logPrint(_factr);

        }
        | LPAREN expression RPAREN{
                string _factr = "(" + $2->getName() + ")";
                string expType = $2->getTypeVar();
                $$ = new SymbolInfo(_factr, $2->getType());
                $$->setTypeVar(expType);
                $$->setAsmCode($2->getAsmCode());
                $$->setStPointer($2->getStPointer());
                rulePrint("factor", "LPAREN expression RPAREN");
                logPrint(_factr);

        }
        | CONST_INT {
                string _factr = $1->getName();
                $$ = new SymbolInfo(_factr, "factor");
                $$->setTypeVar("int");

                string tempVarName = newTemp();
                string asmcodee = "MOV " + tempVarName + ", " + _factr;
                asmcodee += "\n";

                $$->setAsmCode(asmcodee);
                $$->setStPointer(tempVarName);

                rulePrint("factor", "CONST_INT");
                logPrint(_factr);

        }
        | CONST_FLOAT {
                string _factr = $1->getName();
                $$ = new SymbolInfo(_factr, "factor");
                $$->setTypeVar("float");
                $$->setAsmCode("");
                rulePrint("factor", "CONST_FLOAT");
                logPrint(_factr);

        }
        | variable INCOP {
                string _factr = $1->getName() + "++";
                string varType = $1->getTypeVar();
                string _type = $1->getType();
                if(varType == "void"){
                    errorPrint("Invalid Operand Type for ++ operator");
                    errorCount++;
                }
                string asmcodee = $1->getAsmCode();
                if(_type=="array"){
                    string arrayidx = arrayIndex($1->getStPointer());
                    //deleteTemp(arrayidx);
                    asmcodee += "MOV BX, " + arrayidx;
                    asmcodee += "\n";
                    asmcodee += "ADD BX, BX"; //jehetu word type
                    asmcodee += "\n";
                    string newStpointer = getNameWithoutIndex($1->getStPointer());
                    newStpointer += "[BX]";
                    $1->setStPointer(newStpointer);
                }
                string newStpointer = newTemp();
                asmcodee += "MOV AX, " + $1->getStPointer();
                asmcodee += "\n";
                asmcodee += "MOV " + newStpointer + ", AX";
                asmcodee += "\n";
                asmcodee += "INC " + $1->getStPointer();
                asmcodee += "\n";
                $$ = new SymbolInfo(_factr, "factor");
                $$->setTypeVar(varType);
                $$->setStPointer(newStpointer);
                $$->setAsmCode(asmcodee);
                rulePrint("factor", "variable INCOP");
                logPrint(_factr);

        }
        | variable DECOP {
                string _factr = $1->getName() + "--";
                string varType = $1->getTypeVar();
                string _type = $1->getType();
                if(varType == "void"){
                    errorPrint("Invalid Operand Type for -- operator");
                    errorCount++;
                }
                string asmcodee = $1->getAsmCode();
                if(_type=="array"){
                    string arrayidx = arrayIndex($1->getStPointer());
                    //deleteTemp(arrayidx);
                    asmcodee += "MOV BX, " + arrayidx;
                    asmcodee += "\n";
                    asmcodee += "ADD BX, BX"; //jehetu word type
                    asmcodee += "\n";
                    string newStpointer = getNameWithoutIndex($1->getStPointer());
                    newStpointer += "[BX]";
                    $1->setStPointer(newStpointer);
                }
                string newStpointer = newTemp();
                asmcodee += "MOV AX, " + $1->getStPointer();
                asmcodee += "\n";
                asmcodee += "MOV " + newStpointer + ", AX";
                asmcodee += "\n";
                asmcodee += "DEC " + $1->getStPointer();
                asmcodee += "\n";
                $$ = new SymbolInfo(_factr, "factor");
                $$->setTypeVar(varType);
                $$->setStPointer(newStpointer);
                $$->setAsmCode(asmcodee);
                rulePrint("factor", "variable DECOP");
                logPrint(_factr);

        }
        ;
	
argument_list : arguments {
                    string _argmnts = $1->getName();
                    $$ = new SymbolInfo(_argmnts, "argument_list");
                    vector<string> argTypeList = $1->getList1();
                    for(int i=0; i<argTypeList.size(); i++){
                        $$->insertToList1(argTypeList[i]);
                    }
                    vector<string> argPointerList = $1->getList2();
                    for(int i=0; i<argPointerList.size(); i++){
                        $$->insertToList2(argPointerList[i]);
                    }
                    $$->setAsmCode($1->getAsmCode());
                    //$$->insertToList1($3->getTypeVar());
                    rulePrint("argument_list", "arguments");
                    logPrint(_argmnts);
              }
			  | {
                    $$ = new SymbolInfo("", "argument_list");
                    rulePrint("argument_list", "");
                    //logPrint();

              }
			  ;
	
arguments : arguments COMMA logic_expression {
                string _argmnts = $1->getName() + "," + $3->getName();
                $$ = new SymbolInfo(_argmnts, "arguments");
                vector<string> argTypeList = $1->getList1();
                for(int i=0; i<argTypeList.size(); i++){
                    $$->insertToList1(argTypeList[i]);
                }
                vector<string> argPointerList = $1->getList2();
                for(int i=0; i<argPointerList.size(); i++){
                    $$->insertToList2(argPointerList[i]);
                }
                $$->insertToList1($3->getTypeVar());
                $$->insertToList2($3->getStPointer());
                $$->setAsmCode($1->getAsmCode() + $3->getAsmCode());
                rulePrint("arguments", "arguments COMMA logic_expression");
                logPrint(_argmnts);
          }
	      | logic_expression {
                string _argmnts = $1->getName();
                $$ = new SymbolInfo(_argmnts, "arguments");
                $$->setAsmCode($1->getAsmCode());
                $$->insertToList1($1->getTypeVar());
                $$->insertToList2($1->getStPointer());
                rulePrint("arguments", "logic_expression");
                logPrint(_argmnts);
          }
	      ;



%%

int main(int argc,char *argv[])
{

	if(argc!=2) {
		cout << "Please provide input file name and try again\n";
		return 0;
	}

	FILE *fin=fopen(argv[1],"r");
	if(fin==NULL) {
		cout << "Cannot open specified file\n";
		return 0;
	}

	yyin = fin;
	
	

	yyparse();
	

    string defaultCode = "";
    string finalAsmCode = "";
    string finalOptAsmCode = "";

    defaultCode += ".MODEL SMALL\n\n";
    defaultCode += ".STACK 100h\n\n";
    defaultCode += ".DATA\n\n";

    finalAsmCode += defaultCode;
    finalOptAsmCode += defaultCode;
    //add datasegment here
    for(int i=0; i<tempVarList.size(); i++)
    {
        DS += "\t" + tempVarList[i].first + " DW ?";
        DS += "\n";
    }

    finalAsmCode += DS;
    finalOptAsmCode += DS;

    finalAsmCode += "\n\n";
    finalOptAsmCode += "\n\n";

    finalAsmCode += ".CODE\n\n";
    finalOptAsmCode += ".CODE\n\n";
    //add codesegment here

    string printCode = "";
    printCode += "\n";
    printCode += "PRINTproc PROC";
    printCode += "\n";
    printCode += "PUSH AX";
    printCode += "\n";
    printCode += "PUSH BX";
    printCode += "\n";
    printCode += "PUSH CX";
    printCode += "\n";
    printCode += "PUSH DX";
    printCode += "\n";
    printCode += "PUSH BP";
    printCode += "\n";
    printCode += "MOV BP, SP";
    printCode += "\n";
    printCode += "MOV AX, [BP+12]";
    printCode += "\n";
    printCode += "CMP AX, 0";
    printCode += "\n";
    printCode += "JGE POSITIVE";
    printCode += "\n";
    printCode += "PUSH AX";
    printCode += "\n";
    printCode += "MOV DL, '-'";
    printCode += "\n";
    printCode += "MOV AH, 2";
    printCode += "\n";
    printCode += "INT 21H";
    printCode += "\n";
    printCode += "POP AX";
    printCode += "\n";
    printCode += "NEG AX";
    printCode += "\n";
    printCode += "POSITIVE:";
    printCode += "\n";
    printCode += "MOV CX, 0";
    printCode += "\n";
    printCode += "MOV BX, 10D";
    printCode += "\n";
    printCode += "LOOP1:";
    printCode += "\n";
    printCode += "MOV DX, 0";
    printCode += "\n";
    printCode += "DIV BX";
    printCode += "\n";
    printCode += "PUSH DX";
    printCode += "\n";
    printCode += "INC CX";
    printCode += "\n";
    printCode += "CMP AX, 0";
    printCode += "\n";
    printCode += "JNE LOOP1";
    printCode += "\n";
    printCode += "MOV AH, 2";
    printCode += "\n";
    printCode += "LOOP2:";
    printCode += "\n";
    printCode += "POP DX";
    printCode += "\n";
    printCode += "ADD DL, '0'";
    printCode += "\n";
    printCode += "INT 21H";
    printCode += "\n";
    printCode += "LOOP LOOP2";
    printCode += "\n";
    printCode += "MOV DL, 20H";
    printCode += "\n";
    printCode += "INT 21H";
    printCode += "\n";
    printCode += "POP BP";
    printCode += "\n";
    printCode += "POP DX";
    printCode += "\n";
    printCode += "POP CX";
    printCode += "\n";
    printCode += "POP BX";
    printCode += "\n";
    printCode += "POP AX";
    printCode += "\n";
    printCode += "RET 2";
    printCode += "\n";
    printCode += "PRINTproc ENDP";
    printCode += "\n";



    finalAsmCode += runningAsmCode;
    finalAsmCode += printCode;

    finalOptAsmCode += runningOptAsmCode;
    finalOptAsmCode += printCode;

    //cout<<"running asm code"<<runningAsmCode<<endl;

    finalAsmCode += "END MAIN\n\n";
    finalOptAsmCode += "END MAIN\n\n";

	fclose(yyin);
    symT.printAllScopeTable(logfile);
    fprintf(logfile, "Total Lines: %d\n\n", line_count);
    fprintf(logfile, "Total Errors: %d\n\n", errorCount);
    fprintf(asmFile, "%s", finalAsmCode.c_str());
    fprintf(optAsmFile, "%s", finalOptAsmCode.c_str());
	fclose(logfile);
	fclose(errorfile);
    fclose(asmFile);
    fclose(optAsmFile);
	
	return 0;
}
