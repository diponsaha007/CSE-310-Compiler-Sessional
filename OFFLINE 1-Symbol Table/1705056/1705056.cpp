#include <iostream>
#include <vector>

using namespace std;

class SymbolInfo
{
private:
    string name;
    string type;
public:
    SymbolInfo *prv;
    SymbolInfo *nxt;


    SymbolInfo(const string &name, const string &type) : name(name), type(type)
    {
        prv = NULL;
        nxt = NULL;
    }

    const string &getName() const
    {
        return name;
    }

    void setName(const string &name)
    {
        SymbolInfo::name = name;
    }

    const string &getType() const
    {
        return type;
    }

    void setType(const string &type)
    {
        SymbolInfo::type = type;
    }
    void Print()
    {
        cout << "< " << name << " : " << type << " >";
    }

};

class linked_list
{
public:
    SymbolInfo *head;
    SymbolInfo *tail;
    int Size;

    linked_list()
    {
        head = NULL;
        tail = NULL;
        Size = 0;
    }

    bool insert(const string &key, const string &val, int &pos)
    {
        if (search(key, pos) != NULL)
        {
            pos = -1;
            return false;
        }
        SymbolInfo *tmp = new SymbolInfo(key, val);
        if (Size == 0)
        {
            head = tmp;
            tail = tmp;
        }
        else
        {
            tmp->prv = tail;
            tail->nxt = tmp;
            tail = tmp;
        }
        pos = Size;
        Size++;
        return true;
    }

    SymbolInfo *search(const string &key, int &pos)
    {
        pos = 0;
        SymbolInfo *x = head;
        while (x != NULL)
        {
            if (x->getName() == key)
                return x;
            x = x->nxt;
            pos++;
        }
        pos = -1;
        return NULL;
    }

    bool Delete(const string &key, int &pos)
    {
        SymbolInfo *n = search(key, pos);
        if (n == NULL)
        {
            return false;
        }
        if (n->prv == NULL && n->nxt == NULL)
        {
            head = NULL;
            tail = NULL;
        }
        else if (n->prv == NULL)
        {
            head = n->nxt;
            head->prv = NULL;
        }
        else if (n->nxt == NULL)
        {
            tail = n->prv;
            tail->nxt = NULL;
        }
        else
        {
            n->prv->nxt = n->nxt;
            n->nxt->prv = n->prv;
        }
        Size--;
        delete (n);
    }

    void Print()
    {
        SymbolInfo *x = head;
        while (x != NULL)
        {
            cout<<" ";
            x->Print();
            x = x->nxt;
        }
        cout << "\n";
    }
    ~linked_list()
    {
        while (head!=NULL)
        {
            SymbolInfo *now = head;
            head = head->nxt;
            delete(now);
        }
    }
};

int Hash(string s, int mod)
{
    int ret = 0;
    for (int i = 0; i < s.size(); i++)
    {
        ret += s[i];
        ret %= mod;
    }
    return ret;
}

class ScopeTable
{
private:
    vector<linked_list> v;
    string id;
    ScopeTable *parent;
    int child;
    int cur_id;

    int (*hash)(string, int);

public:
    ScopeTable(int sz, ScopeTable *parent, int (*hash)(string, int)) : parent(parent),
                                                                       hash(hash)
    {
        v.resize(sz);
        child = 0;
        if (parent == NULL)
        {
            cur_id = 1;
        }
        else
        {
            cur_id = parent->child;
            id = parent->id;
        }
        if (!id.empty())
            id += ".";
        id += (cur_id + '0');
    }

    bool Insert(const string &key, const string &val)
    {
        int pos = hash(key, v.size());
        int it;
        bool ret = v[pos].insert(key, val, it);
        if (ret)
        {
            cout << "Inserted in ScopeTable# " << id << " at position " << pos << ", " << it << "\n";
        }
        else
        {
            SymbolInfo *x = v[pos].search(key,it);
            x->Print();
            cout <<" already exists in current ScopeTable\n";
        }
        return ret;
    }

    SymbolInfo *LookUp(const string &key, int &pos, int &it)
    {
        pos = hash(key, v.size());
        return v[pos].search(key, it);
    }

    bool Delete(const string &key)
    {
        int pos = hash(key, v.size());
        int it;
        bool ret = v[pos].Delete(key, it);
        if (ret)
        {
            cout << "Found in ScopeTable# " << id << " at position " << pos << ", " << it << "\n";
            cout << "Deleted Entry " << pos << ", " << it << " from current ScopeTable\n";
        }
        else
        {
            cout << key << " not found in ScopeTable# " << id << "\n";
        }
        return ret;
    }

    void Print()
    {
        cout << "ScopeTable # " << id << "\n";
        for (int i = 0; i < v.size(); i++)
        {
            cout << i << " -->";
            v[i].Print();
        }
        cout << "\n";
    }

    int getChild() const
    {
        return child;
    }

    void setChild(int child)
    {
        ScopeTable::child = child;
    }

    ScopeTable *getParent() const
    {
        return parent;
    }

    const string &getId() const
    {
        return id;
    }
};

class SymbolTable
{
private:
    ScopeTable *scopeTable;
    int bucket_size;
public:
    SymbolTable(int bucketSize) : bucket_size(bucketSize)
    {
        scopeTable = new ScopeTable(bucket_size, NULL, Hash);
    }

    void enter_scope()
    {
        scopeTable->setChild(scopeTable->getChild() + 1);
        ScopeTable *tmp = new ScopeTable(bucket_size, scopeTable, Hash);
        scopeTable = tmp;
        cout << "New ScopeTable with id " << scopeTable->getId() << " created\n";
    }

    void exit_scope()
    {
        cout << "ScopeTable with id " << scopeTable->getId() << " removed\n";
        ScopeTable *tmp = scopeTable->getParent();
        delete(scopeTable);
        scopeTable = tmp;
    }

    bool insert_symbol(const string& name, const string& type)
    {
        return scopeTable->Insert(name, type);
    }

    bool remove_symbol(const string& name)
    {
        return scopeTable->Delete(name);
    }

    SymbolInfo *LookUp(const string& name)
    {
        ScopeTable *tmp = scopeTable;
        while (tmp != NULL)
        {
            int pos, it;
            SymbolInfo *x = tmp->LookUp(name, pos, it);
            if (x != NULL)
            {
                cout << "Found in ScopeTable# " << tmp->getId() << " at position " << pos << ", " << it << "\n";
                return x;
            }
            tmp = tmp->getParent();
        }
        cout << "Not found\n";
        return NULL;
    }

    void PrintCurrentScope()
    {
        scopeTable->Print();
        cout << "\n";
    }

    void PrintAllScope()
    {
        ScopeTable *tmp = scopeTable;
        while (tmp != NULL)
        {
            tmp->Print();
            tmp = tmp->getParent();
        }
        cout << "\n";
    }
    ~SymbolTable()
    {
        while (scopeTable!=NULL)
        {
            ScopeTable *now = scopeTable;
            scopeTable = scopeTable->getParent();
            delete(now);
        }
    }
};

int main()
{
    freopen("input.txt", "r", stdin);
    freopen("output.txt", "w", stdout);
    int bucket_size;
    cin >> bucket_size;
    SymbolTable symbolTable(bucket_size);
    string s;
    while (cin >> s)
    {
        if (s == "I")
        {
            string name, type;
            cin >> name >> type;
            cout<<"\n"<<s<<" "<<name<<" "<<type<<"\n\n";
            symbolTable.insert_symbol(name, type);
        }
        else if (s == "L")
        {
            string name;
            cin >> name;
            cout<<"\n"<<s<<" "<<name<<"\n\n";
            symbolTable.LookUp(name);
        }
        else if (s == "D")
        {
            string name;
            cin >> name;
            cout<<"\n"<<s<<" "<<name<<"\n\n";
            symbolTable.remove_symbol(name);
        }
        else if (s == "P")
        {
            string tmp;
            cin >> tmp;
            cout<<"\n"<<s<<" "<<tmp<<"\n\n";
            if (tmp == "A")
            {
                symbolTable.PrintAllScope();
            }
            else if (tmp == "C")
            {
                symbolTable.PrintCurrentScope();
            }
        }
        else if (s == "S")
        {
            cout<<"\n"<<s<<"\n\n";
            symbolTable.enter_scope();
        }
        else if (s == "E")
        {
            cout<<"\n"<<s<<"\n\n";
            symbolTable.exit_scope();
        }
    }
    return 0;
}
