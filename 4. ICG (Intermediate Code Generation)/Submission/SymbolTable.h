#include<bits/stdc++.h>
using namespace std;


class SymbolInfo
{
    private:
        string name, type;
        string typeVar, funcSt; /*typeVar = kon type er ID, funcSt = function er declaration/definition statement specity korar jonno*/
        

        vector<string> list1;
        /**
         * @brief
         * list1 used for:
         * 1. function er khetre parameter er type_specifier rakhar jonno
         * 2. var_declaration list er khetre var_name rakhar jonno
         * 3. argument list rakhar jonno
         *
         */
        vector<string> list2;
        /**
         * @brief
         * list2 used for:
         * 1. function er khetre parameter er id(name) rakhar jonno
         * 2. var_declaration list er khetre --
         *      a. array hole "[]" eta rakhbe
         *      b. otherwise "" eta(empty string) rakhbe
         */
        string asmCode; //to store asm code
        string stPointer; //to store symbol table pointer
        SymbolInfo* nextSymbol;
        bool temp; //to store if it is a temporary variable

    public:
        SymbolInfo()
        {
            setName("");
            setType("");
            setNextSymbol(nullptr);
            setFuncSt("");
            setTypeVar("none");
            setAsmCode("");
            setStPointer("");
            markTemp(true);
        }


        SymbolInfo(string name, string type)
        {
            setName(name);
            setType(type);
            setNextSymbol(nullptr);
            setFuncSt("");
            setTypeVar("none");
            setAsmCode("");
            setStPointer("");
            markTemp(true);
        }

        SymbolInfo(string name, string type, string typeVar)
        {
            setName(name);
            setType(type);
            setNextSymbol(nullptr);
            setFuncSt("");
            //typeVar.resize(typeVar.size()+100);
            //typeVar.reserve(typeVar.size());
            setTypeVar(typeVar);
            setAsmCode("");
            setStPointer("");
            markTemp(true);
            
        }


        void setName(string name)
        {
            this->name = name;
        }

        void setTypeVar(string typeVarr)
        {
            
            //typeVar.resize(typeVar.size()-100);
            //string s(typeVar.begin(), typeVar.end());
            //cout<<typeVar<<typeVar.size()<<endl;

            //typeVarr.resize(typeVarr.size()+53);
            this->typeVar = typeVarr;
            //this->typeVar.resize(this->typeVar.size()-53);
            //cout<<this->typeVar<<this->typeVar.size()<<endl;

            //this->typeVar = typeVar;
            
        }

        string getName()
        {
            return name;
        }

        void setType(string type)
        {
            this->type = type;
        }


        string getType()
        {
            return type;
        }


        void setNextSymbol(SymbolInfo* nextSymbol)
        {
            this->nextSymbol = nextSymbol;
        }


        SymbolInfo* getNextSymbol()
        {
            return nextSymbol;
        }


        void printSymbol()
        {
            cout<<"< "<<name<<" : "<<type<<" > "<<endl;
        }

        void insertToList1(string data)
        {
            list1.push_back(data);
        }

        void insertToList2(string data)
        {
            list2.push_back(data);
        }

        const vector<string>& getList1()
        {
                return list1;
        }

        const vector<string>& getList2()
        {
                return list2;
        }

        

        string getTypeVar()
        {
            return typeVar;
        }

        void setFuncSt(string funcSt)
        {
            this->funcSt = funcSt;
        }

        string getFuncSt()
        {
            return funcSt;
        }

        void setAsmCode(string asmCode)
        {
            this->asmCode = asmCode;
        }
        string getAsmCode()
        {
            return asmCode;
        }
        void setStPointer(string stPointer)
        {
            this->stPointer = stPointer;
        }
        string getStPointer()
        {
            return stPointer;
        }
        void markTemp(bool temp)
        {
            this->temp = temp;
        }
        bool isTemp()
        {
            return temp;
        }


};


class ScopeTable
{
private:
    SymbolInfo** hashTable;
    ScopeTable* parentScope;
    int bucketSize, nChildScope;
    string id;

    int hashFunction(string symbolName)
    {
        unsigned int hashidx = 0;

        for(int i=0; i<symbolName.size(); i++)
        {
            hashidx = symbolName[i] + (hashidx << 6) + (hashidx << 16) - hashidx;
        }


        return (hashidx % bucketSize);

    }

public:
    ScopeTable(int bucketSize, ScopeTable* parentScope=nullptr)
    {

        this->bucketSize = bucketSize;
        this->parentScope = parentScope;
        nChildScope = 0;
        id = "";

        hashTable = new SymbolInfo*[bucketSize];
        for(int i=0; i<bucketSize; i++)
        {
            hashTable[i] = nullptr;
        }

        ///setting id of newScope table

        this->setId(makeId());


        //int nCurrChild = getnChildScope() + 1;
        //parentScope->setnChildScope(nCurrChild);

    }


    void setId(string id)
    {
        this->id = id;
    }


    string getId()
    {
        return this->id;
    }


    string makeId()
    {
        string newId = "";
        if(parentScope == nullptr)
        {
            newId = newId + "1";
        }
        else
        {
            int nCurrentChild = parentScope->getnChildScope() + 1;
            string parentId = "";
            parentId = parentScope->getId();
            newId = newId + parentId + "_" + to_string(nCurrentChild);
            parentScope->setnChildScope(nCurrentChild);
        }
        return newId;
    }


    void setParentScope(ScopeTable* parentScope)
    {
        this->parentScope = parentScope;
    }


    ScopeTable* getParentScope()
    {
        return parentScope;
    }


    void setnChildScope(int nChildScope)
    {

        this->nChildScope = nChildScope;
        //cout<<"a"<<endl;
    }


    int getnChildScope()
    {
        return nChildScope;
    }


    




    bool insertt(string symbolName, string symbolType)
    {
        cout<<"here"<<endl;
        int bucketIdx = hashFunction(symbolName);
        int column = 0;

        if(bucketIdx<0) bucketIdx = -bucketIdx;

        SymbolInfo* currentSymbol = hashTable[bucketIdx];
        SymbolInfo* preSymbol = nullptr;

        while(true)
        {
            if(currentSymbol == nullptr)
            {
                break;
            }
            else if(symbolName == currentSymbol->getName())
            {
                //cout<<"< "<<symbolName<<", "<<symbolType<<" > already exists in current scopetable"<<endl;
                return false;
            }

            column++;
            preSymbol = currentSymbol;
            currentSymbol = currentSymbol->getNextSymbol();

        }

        SymbolInfo *newSymbol = new SymbolInfo(symbolName, symbolType);

        if(preSymbol != nullptr)
        {
            preSymbol->setNextSymbol(newSymbol); ///chaining
        }
        else
        {
            hashTable[bucketIdx] = newSymbol; ///1st bucket entry
        }
        //cout<<"Inserted in scopetable# "<< getId()<< " at position "<<bucketIdx<<", "<<column<<endl;
        return true;
    }

    SymbolInfo* lookup(string symbolName)
    {
        int bucketIdx = hashFunction(symbolName);
        int column = 0;
        SymbolInfo* currentSymbol;
        currentSymbol = hashTable[bucketIdx];

        while(true)
        {
            if(currentSymbol == nullptr)
            {
                //cout<<"Finding "<<symbolName;
                return nullptr;
            }
            else if(currentSymbol->getName()==symbolName)
            {
                //cout<<"Found in scopetable# "<<getId()<<" at position "<<bucketIdx<<", "<<column<<endl;
                return currentSymbol;
            }

            else
            {
                column++;
                currentSymbol = currentSymbol->getNextSymbol();
            }
        }
    }

    bool deletee(string symbolName)
    {
        int bucketIdx = hashFunction(symbolName);
        int column = 0;

        SymbolInfo* currentSymbol = hashTable[bucketIdx];
        SymbolInfo* preSymbol = nullptr;

        while(true)
        {
            if(currentSymbol == nullptr)
            {
                //cout<<symbolName<<"Not found"<<endl;
                return false;
            }
            else if(symbolName == currentSymbol->getName())
            {

                if(preSymbol != nullptr)
                {
                    SymbolInfo* nextSymbol = currentSymbol->getNextSymbol();
                    preSymbol->setNextSymbol(nextSymbol);

                }
                else
                {
                    //cout<<"deleting"<<symbolName;
                    SymbolInfo* nextSymbol = currentSymbol->getNextSymbol();
                    hashTable[bucketIdx] = nextSymbol;
                }
                delete currentSymbol;
                //cout<<"Deleted entry "<<bucketIdx<<", "<<column<<" from current scopetable# "<<getId()<<endl;
                return true;
            }
            else
            {
                column++;
                preSymbol = currentSymbol;
                currentSymbol = currentSymbol->getNextSymbol();
            }
        }
    }

    void print(FILE *logfile)
    {
        //cout<<"ScopeTable # "<<this->getId()<<endl;
        fprintf(logfile, "ScopeTable # %s", this->getId().c_str());
        fprintf(logfile, "\n");

        for(int i=0; i<bucketSize; i++)
        {
            //cout<<i<<" --> ";
            SymbolInfo* currentSymbol = hashTable[i];
            if(currentSymbol == nullptr){
                continue;
            }
            fprintf(logfile, "%d -->", i);

            while(true)
            {
                if(currentSymbol == nullptr)
                {
                    break;
                }
                //else if(currentSymbol->getName()==""){currentSymbol = currentSymbol->getNextSymbol();}
                else
                {
                    //cout<<"< "<<currentSymbol->getName()<<" : "<<currentSymbol->getType()<<" > ";
                    fprintf(logfile, "< %s : %s >",currentSymbol->getName().c_str(), currentSymbol->getType().c_str());
                    currentSymbol = currentSymbol->getNextSymbol();
                }

            }
            //cout<<endl;
            fprintf(logfile, "\n");
        }
    }

    ~ScopeTable()
    {
        for(int i=0; i<bucketSize; i++)
        {
            delete hashTable[i];
        }
    }


    bool insertt(SymbolInfo *symbol)
    {

        string symbolName = symbol->getName();


        int bucketIdx = hashFunction(symbolName);
        int column = 0;

        if(bucketIdx<0) bucketIdx = -bucketIdx;

        SymbolInfo* currentSymbol = new SymbolInfo();
        SymbolInfo* preSymbol = new SymbolInfo();

        currentSymbol = hashTable[bucketIdx];
        preSymbol = nullptr;

        while(true)
        {
            if(currentSymbol == nullptr)
            {
                break;
            }
            else if(symbolName == currentSymbol->getName())
            {
                //cout<<"< "<<symbolName<<", "<<symbolType<<" > already exists in current scopetable"<<endl;
                return false;
            }

            column++;
            preSymbol = currentSymbol;
            currentSymbol = currentSymbol->getNextSymbol();

        }

        //SymbolInfo *newSymbol = symbol;

        if(preSymbol != nullptr)
        {
            preSymbol->setNextSymbol(symbol); ///chaining
        }
        else
        {
            hashTable[bucketIdx] = symbol; ///1st bucket entry
        }
        //cout<<"Inserted in scopetable# "<< getId()<< " at position "<<bucketIdx<<", "<<column<<endl;
        //cout<<"Insert "<<symbol->getName()<<symbol->getType()<<endl;
        return true;
    }


    //get all stPointers in the current scope table
    vector<string> getSTPointers()
    {
        vector<string> stPointers;
        for(int i=0; i<bucketSize; i++)
        {
            SymbolInfo* currentSymbol = hashTable[i];
            while (currentSymbol!=nullptr)
            {
                 stPointers.push_back(currentSymbol->getStPointer());
                 currentSymbol = currentSymbol->getNextSymbol();
            }
            
        }
        return stPointers;
    }
};

class SymbolTable
{
    private:
        int bucketSize;
        ScopeTable* currentScopeTable;

    public:
        SymbolTable(int bucketSize)
        {
            this->bucketSize = bucketSize;

            currentScopeTable = new ScopeTable(bucketSize);
            //cout<<"2"<<endl;
        }


        void enterScope()
        {
            ScopeTable* newScopeTable;
            newScopeTable = new ScopeTable(bucketSize, currentScopeTable);

            newScopeTable->setParentScope(currentScopeTable);
            currentScopeTable = newScopeTable;

            //cout<<"New scopeTable with ID "<<newScopeTable->getId()<<" created"<<endl;
        }


        void exitScope()
        {
            ScopeTable *topTable = currentScopeTable;
            currentScopeTable = topTable->getParentScope();
            //cout<<"Scopetable with ID "<<topTable->getId()<<" removed"<<endl;
            delete topTable;
        }


        bool insertt(string symbolName, string symbolType)
        {
            return currentScopeTable->insertt(symbolName, symbolType);

        }


        bool removee(string symbolName)
        {
            return currentScopeTable->deletee(symbolName);
        }


        SymbolInfo* lookup(string symbolName)
        {
            ScopeTable* crnt = currentScopeTable;
            SymbolInfo* lookupRes = crnt->lookup(symbolName);

            if(lookupRes != nullptr)
            {
                return lookupRes;
            }
            else
            {

                while(crnt->getParentScope()!=nullptr)
                {
                    //cout<<"z";
                    crnt = crnt->getParentScope();
                    lookupRes = crnt->lookup(symbolName);
                    if(lookupRes!=nullptr)
                    {
                        return lookupRes;
                    }
                }
            }
            //cout<<"Not Found"<<endl;
            return nullptr;

        }


        void printCurrentScopeTable(FILE *logfile)
        {
            currentScopeTable->print(logfile);
        }


        void printAllScopeTable(FILE *logfile)
        {
            ScopeTable *crnt;
            crnt = currentScopeTable;

            while(crnt != nullptr)
            {
                crnt->print(logfile);
                crnt = crnt->getParentScope();
            }
        }


        bool insertt(SymbolInfo *symbol)
        {
            return currentScopeTable->insertt(symbol);

        }

        vector<string> getAllSTPointers()
        {
            vector<string> stpointers;
            vector<string> scpTpointers;
            ScopeTable *crnt = currentScopeTable;
            while (crnt->getId()!= "1")
            {
                scpTpointers = crnt->getSTPointers();
                for(int i=0; i<scpTpointers.size(); i++)
                {
                    stpointers.push_back(scpTpointers[i]);
                }
                crnt = crnt->getParentScope();
            }
            return stpointers;

        }

        string getCrntScpTableID()
        {
            return currentScopeTable->getId();
        }


};





/*int main()
{

    freopen("input.txt", "r", stdin);
    freopen("output.txt", "w", stdout);

    int bucketSize;
    string symbolName, symbolType;

    cin>>bucketSize;


    SymbolTable symboltable(bucketSize);

    string option;

    while(cin>>option)
    {
        if(option == "I")
        {
            cin>>symbolName;
            cin>>symbolType;
            cout<<option<<" "<<symbolName<<" "<<symbolType<<endl;
            symboltable.insertt(symbolName, symbolType);
        }
        else if(option == "L")
        {
            cin>>symbolName;
            cout<<option<<" "<<symbolName<<endl;
            //cout<<"Finding "<<symbolName;
            symboltable.lookup(symbolName);
        }
        else if(option == "D")
        {
            cin>>symbolName;
            cout<<option<<" "<<symbolName<<endl;
            symboltable.removee(symbolName);
        }
        else if(option == "S")
        {
            cout<<option<<endl;
            symboltable.enterScope();
        }
        else if(option == "E")
        {
            cout<<option<<endl;
            symboltable.exitScope();
        }
        else if(option == "P")
        {
            string printOption;
            cin>>printOption;

            cout<<option<<" "<<printOption<<endl;

            if(printOption == "A")
            {
                symboltable.printAllScopeTable();
            }
            else if(printOption == "C")
            {
                symboltable.printCurrentScopeTable();
            }
        }
    }

}*/
