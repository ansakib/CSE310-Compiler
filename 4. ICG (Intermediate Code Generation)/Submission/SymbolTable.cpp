#include<bits/stdc++.h>
using namespace std;


class SymbolInfo
{
    private:
        string name, type;
        SymbolInfo* nextSymbol;

    public:
        SymbolInfo()
        {
            setName("");
            setType("");
            setNextSymbol(nullptr);
        }


        SymbolInfo(string name, string type)
        {
            setName(name);
            setType(type);
            setNextSymbol(nullptr);
        }


        void setName(string name)
        {
            this->name = name;
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
        int hashidx = 0;

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
            newId = newId + parentId + "." + to_string(nCurrentChild);
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


    bool insertt(string symbolName, string symbolType);
    SymbolInfo* lookup(string symbolName);
    bool deletee(string symbolName);
    void print();
    ~ScopeTable();

};


bool ScopeTable::insertt(string symbolName, string symbolType)
{
    int bucketIdx = hashFunction(symbolName);
    int column = 0;

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

SymbolInfo* ScopeTable::lookup(string symbolName)
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

bool ScopeTable::deletee(string symbolName)
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

void ScopeTable::print()
{
    cout<<"ScopeTable # "<<this->getId()<<endl;
    for(int i=0; i<bucketSize; i++)
    {
        cout<<i<<" --> ";
        SymbolInfo* currentSymbol = hashTable[i];
        while(true)
        {
            if(currentSymbol == nullptr)
            {
                break;
            }
            else
            {
                cout<<"< "<<currentSymbol->getName()<<" : "<<currentSymbol->getType()<<" > ";
                currentSymbol = currentSymbol->getNextSymbol();
            }

        }
        cout<<endl;
    }
}

ScopeTable::~ScopeTable()
{
    for(int i=0; i<bucketSize; i++)
    {
        delete hashTable[i];
    }
}



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


        void printCurrentScopeTable()
        {
            currentScopeTable->print();
        }


        void printAllScopeTable()
        {
            ScopeTable *crnt;
            crnt = currentScopeTable;

            while(crnt != nullptr)
            {
                crnt->print();
                crnt = crnt->getParentScope();
            }
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
