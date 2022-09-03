%{

#include<bits/stdc++.h>
#include "SymbolTable.h"

#define YYSTYPE SymbolInfo*

using namespace std;

SymbolTable symT(30);
FILE *errorfile = fopen("error.txt", "w");
FILE *logfile = fopen("log.txt", "w");
bool ErrFunc = false;

int yyparse(void);
int yylex(void);

extern int line_count;
extern int errorCount;
extern FILE* yyin;

vector< pair<string,string> > paramsList;

void yyerror(string s)
{
	//write your code
    //cout<<s<<endl;
	fprintf(logfile, "Error at line no %d : %s \n\n", line_count, s.c_str());
    fprintf(errorfile, "Error at line no %d : %s \n\n", line_count, s.c_str());
    errorCount++;

}

bool checkAssignOp(string type1, string type2){
    bool arrayType1 = false;
    bool arrayType2 = false;
    if(type1.size()>=2){
        if(type1[type1.size()-2]=='[' && type1[type1.size()-1]==']'){
            arrayType1 = true;
        }
    }
    if(type2.size()>=2){
        if(type2[type2.size()-2]=='[' && type2[type2.size()-1]==']'){
            arrayType2 = true;
        }
    }

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


%}


%error-verbose

%token IF ELSE FOR WHILE DO BREAK INT CHAR FLOAT DOUBLE VOID RETURN SWITCH CASE DEFAULT CONTINUE
%token CONST_INT CONST_FLOAT CONST_CHAR ADDOP MULOP INCOP DECOP RELOP ASSIGNOP LOGICOP NOT LPAREN 
%token RPAREN LCURL RCURL LTHIRD RTHIRD COMMA SEMICOLON ID PRINTLN

%nonassoc LOWER_THAN_ELSE 
%nonassoc ELSE


%%

start : program {
                $$ = $1;
                $$->setType("start");
                rulePrint("start", "program");
        }

program : program unit {

                string tempName = $1->getName() + $2->getName();
                $$ = new SymbolInfo(tempName, "unit");
                rulePrint("program", "program unit");
                logPrint(tempName);

        }
	    | unit{
                $$ = $1;
                $$->setType("program");
                rulePrint("program", "unit");
                logPrint($$->getName());
        }
	    ;
 
unit : var_declaration {
                $$ = $1;
                $$->setType("unit");
                string _unitST = $1->getName() + "\n"; //to add a new line after every unit
                $$->setName(_unitST);
                rulePrint("unit", "var_declaration");
                logPrint($$->getName());

     }
     | func_declaration{
                $$ = $1;
                $$->setType("unit");
                string _unitST = $1->getName() + "\n"; //to add a new line after every unit
                $$->setName(_unitST);
                rulePrint("unit", "func_declaration");
                logPrint($$->getName());

     }
     | func_definition{
                $$ = $1;
                $$->setType("unit");
                string _unitST = $1->getName() + "\n"; //to add a new line after every unit
                $$->setName(_unitST);
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
                                    //cout<<symbol->getTypeVar()<<" "<<symbol->getName()<<endl;
                                    
                                }


                                $$ = new SymbolInfo(_def, "func_definition_st");

                }
                compound_statement {
                                string _name = $6->getName() + $7->getName();
                                $$ = new SymbolInfo(_name, "func_definition");
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


                                $$ = new SymbolInfo(_def, "func_definition_st");

                }
                compound_statement {
                                string _name = $5->getName() + $6->getName();
                                $$ = new SymbolInfo(_name, "func_definition");
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
                        string compSt = "{\n" + $3->getName() + "\n}";
                        $$ = new SymbolInfo(compSt, "compound_statement");
                        rulePrint("compound_statement", "LCURL statements RCURL");
                        logPrint(compSt);
                        symT.printAllScopeTable(logfile);
                        symT.exitScope();

                    }
                    | LCURL scopeController RCURL{
                        string compSt = "{}";
                        $$ = new SymbolInfo(compSt, "compound_statement");
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
                symT.enterScope();
                for(int i=0; i<paramsList.size(); i++){
                    string _varType = paramsList[i].first;
                    string _name = paramsList[i].second;
                    SymbolInfo *symbol = new SymbolInfo(_name, "ID");
                    symbol->setTypeVar(_varType);
                    if(symT.insertt(symbol)==false){
                        errorPrint("Multiple Declaration of "+ _name);
                        errorCount++;
                    }
                }
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
                            symbol->setTypeVar(varType+list2[i]);
                            

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
                    rulePrint("var_declaration", "type_specifier declaration_list SEMICOLON");
                    logPrint(st);

                }
 		        ;
 		 
type_specifier	: INT{
                    SymbolInfo *newSymbol = new SymbolInfo("int", "type_spec");
                    $$ = newSymbol;
                    rulePrint("type_specifier", "INT");
                    logPrint($$->getName());

                }
 		        | FLOAT{
                    SymbolInfo *newSymbol = new SymbolInfo("float", "type_spec");
                    $$ = newSymbol;
                    rulePrint("type_specifier", "FLOAT");
                    logPrint($$->getName());

                }
 		        | VOID{
                    SymbolInfo *newSymbol = new SymbolInfo("void", "type_spec");
                    $$ = newSymbol;
                    rulePrint("type_specifier", "VOID");
                    logPrint($$->getName());

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
                    $1->insertToList2("[]"); //mark as array
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
                    rulePrint("declaration_list", "ID");
                    logPrint($$->getName());

                }
 		        | ID LTHIRD CONST_INT RTHIRD{
                    string new_id = $1->getName() + "[" + $3->getName() + "]";
                    SymbolInfo *newSymbol = new SymbolInfo(new_id, "declaration_list");
                    $$ = newSymbol;
                    $$->insertToList1($1->getName()); //started a new declaration_list
                    $$->insertToList2("[]");
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
                    rulePrint("declaration_list", "ID LTHIRD RTHIRD");
                    //logPrint($$->getName());
                    errorPrint("Undefined Array Size");
                    errorCount++;
                }
 		        ;
 		  
statements : statement {
                    string _st = $1->getName();
                    $$ = new SymbolInfo(_st, "statements");
                    rulePrint("statements","statement");
                    logPrint(_st);

           }
    	   | statements statement {
                    string _st = $1->getName() + "\n" + $2->getName();
                    $$ = new SymbolInfo(_st, "statements");
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
                rulePrint("statement", "var_declaration");
                logPrint(_stmt);

        }
        | expression_statement{
                string _stmt = $1->getName();
                $$ = new SymbolInfo(_stmt, "statement");
                rulePrint("statement", "expression_statement");
                logPrint(_stmt);

        }
        | compound_statement{
                string _stmt = $1->getName();
                $$ = new SymbolInfo(_stmt, "statement");
                rulePrint("statement", "compound_statement");
                logPrint(_stmt);

        }
        | FOR LPAREN expression_statement expression_statement expression RPAREN statement{
                string _stmt = "for(" + $3->getName() + " " + $4->getName() + " " +$5->getName() + ") " + $7->getName();
                $$ = new SymbolInfo(_stmt, "statement");
                rulePrint("statement", "FOR LPAREN expression_statement expression_statement expression RPAREN statement");
                logPrint(_stmt);

        }
        | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE{
                string _stmt = "if(" + $3->getName() + ") " + $5->getName();
                $$ = new SymbolInfo(_stmt, "statement");
                rulePrint("statement", "IF LPAREN expression RPAREN statement");
                logPrint(_stmt);

        }
        | IF LPAREN expression RPAREN statement ELSE statement{

                string _stmt = "if(" + $3->getName() + ") " + $5->getName() + "else " + $7->getName();
                $$ = new SymbolInfo(_stmt, "statement");
                rulePrint("statement", "IF LPAREN expression RPAREN statement ELSE statement");
                logPrint(_stmt);
        }
        | WHILE LPAREN expression RPAREN statement{
                string _stmt = "while(" + $3->getName() + ") " + $5->getName();
                $$ = new SymbolInfo(_stmt, "statement");
                rulePrint("statement", "WHILE LPAREN expression RPAREN statement");
                logPrint(_stmt);

        }
        | PRINTLN LPAREN ID RPAREN SEMICOLON{
                SymbolInfo *retSymbol = symT.lookup($3->getName());
                if(retSymbol==nullptr){
                    errorPrint("Undeclared Variable: " + $3->getName());
                    errorCount++;
                }
                string _stmt = "printf(" + $3->getName() + ");";
                $$ = new SymbolInfo(_stmt, "statement");
                rulePrint("statement", "PRINTLN LPAREN ID RPAREN SEMICOLON");
                logPrint(_stmt);

        }
        | RETURN expression SEMICOLON{
                string _st = "return " + $2->getName() + ";";
                $$ = new SymbolInfo(_st, "statement");
                rulePrint("statement", "RETURN expression SEMICOLON");
                logPrint(_st);

        }
        ;
	  
expression_statement : SEMICOLON{
                            $$ = new SymbolInfo(";", "expression_statement");
                            rulePrint("expression_statement", "SEMICOLON");
                            logPrint(";");

                    }
			        | expression SEMICOLON {
                            string _st = $1->getName() + ";";
                            $$ = new SymbolInfo(_st, "expression_statement");
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
                    SymbolInfo *errorVar = new SymbolInfo(_name, "variable");
                    $$ = errorVar;
                    //$$->setTypeVar("none");
                    string eMsg = "Undeclared Variable '"+ _name +"'";
                    errorPrint(eMsg);
                    errorCount++;
                    //cout<<errorVar->getTypeVar()<<endl;
                }
                rulePrint("Variable", "ID");
                logPrint(_name);

        }		
	    | ID LTHIRD expression RTHIRD {
                string _name = $1->getName() + "[" + $3->getName() + "]";
                SymbolInfo *existingVar = symT.lookup($1->getName()); //find if variable is declared
                string existingVarType = existingVar->getTypeVar();
                string indexType = $3->getTypeVar();
                SymbolInfo *newVar = new SymbolInfo(_name, "variable");
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
                    rulePrint("expression", "variable ASSIGNOP logic_expression");
                    logPrint(_exp);
            
            }
	        ;
			
logic_expression : rel_expression {
                        $$ = $1;
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

                        bool arrayExp = false;
                        bool arrayExpRight = false;
                        SymbolInfo *newExp = new SymbolInfo(_exp, "rel_expression");
                        $$ = newExp;
                        
                        if(expType.size()>=2){
                            if(expType[expType.size()-2]=='[' && expType[expType.size()-1]==']'){
                                arrayExp = true;
                            }
                        }

                        if(expTypeRight.size()>=2){
                            if(expTypeRight[expTypeRight.size()-2]=='[' && expTypeRight[expTypeRight.size()-1]==']'){
                                arrayExpRight = true;
                            }
                        }
                        

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

                            bool arrayExp = false;
                            bool arrayTerm = false;
                            SymbolInfo *newExp = new SymbolInfo(_exp, "simple_expression");
                            $$ = newExp;
                            
                            if(expType.size()>=2){
                                if(expType[expType.size()-2]=='[' && expType[expType.size()-1]==']'){
                                    arrayExp = true;
                                }
                            }

                            if(termType.size()>=2){
                                if(termType[termType.size()-2]=='[' && termType[termType.size()-1]==']'){
                                    arrayTerm = true;
                                }
                            }

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

                bool arrayExp = false;
                bool arrayTerm = false;
                SymbolInfo *newExp = new SymbolInfo(_term, "term");
                $$ = newExp;
                
                if(expType.size()>=2){
                    if(expType[expType.size()-2]=='[' && expType[expType.size()-1]==']'){
                        arrayExp = true;
                    }
                }

                if(termType.size()>=2){
                    if(termType[termType.size()-2]=='[' && termType[termType.size()-1]==']'){
                        arrayTerm = true;
                    }
                }
                

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

                rulePrint("term", "term MULOP unary_expression");
                logPrint(_term);

     }
     ;

unary_expression : ADDOP unary_expression  {
                    string _exp = $1->getName() + $2->getName();
                    string _expType = $2->getTypeVar();
                    if(_expType=="void"){
                        errorPrint("Void type operand detected!");
                        errorCount++;
                    }
                    $$ = new SymbolInfo(_exp, "unary_expression");
                    $$->setTypeVar(_expType);

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
                    $$ = new SymbolInfo(_exp, "unary_expression");
                    $$->setTypeVar(_expType);

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

                rulePrint("factor", "ID LPAREN argument_list RPAREN");
                logPrint(_factr);

        }
        | LPAREN expression RPAREN{
                string _factr = "(" + $2->getName() + ")";
                string expType = $2->getTypeVar();
                $$ = new SymbolInfo(_factr, "factor");
                $$->setTypeVar(expType);
                rulePrint("factor", "LPAREN expression RPAREN");
                logPrint(_factr);

        }
        | CONST_INT {
                string _factr = $1->getName();
                $$ = new SymbolInfo(_factr, "factor");
                $$->setTypeVar("int");
                rulePrint("factor", "CONST_INT");
                logPrint(_factr);

        }
        | CONST_FLOAT {
                string _factr = $1->getName();
                $$ = new SymbolInfo(_factr, "factor");
                $$->setTypeVar("float");
                rulePrint("factor", "CONST_FLOAT");
                logPrint(_factr);

        }
        | variable INCOP {
                string _factr = $1->getName() + "++";
                string varType = $1->getTypeVar();
                if(varType == "void"){
                    errorPrint("Invalid Operand Type for ++ operator");
                    errorCount++;
                }
                $$ = new SymbolInfo(_factr, "factor");
                $$->setTypeVar(varType);
                rulePrint("factor", "variable INCOP");
                logPrint(_factr);

        }
        | variable DECOP {
                string _factr = $1->getName() + "--";
                string varType = $1->getTypeVar();
                if(varType == "void"){
                    errorPrint("Invalid Operand Type for -- operator");
                    errorCount++;
                }
                $$ = new SymbolInfo(_factr, "factor");
                $$->setTypeVar(varType);
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
                $$->insertToList1($3->getTypeVar());
                rulePrint("arguments", "arguments COMMA logic_expression");
                logPrint(_argmnts);
          }
	      | logic_expression {
                string _argmnts = $1->getName();
                $$ = new SymbolInfo(_argmnts, "arguments");
                $$->insertToList1($1->getTypeVar());
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
	
	fclose(yyin);
    symT.printAllScopeTable(logfile);
    fprintf(logfile, "Total Lines: %d\n\n", line_count);
    fprintf(logfile, "Total Errors: %d\n\n", errorCount);
	fclose(logfile);
	fclose(errorfile);
	
	return 0;
}
