#include <iostream>
#include <vector>
#include <fstream>
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
    void Print(ofstream &logout)
    {
        logout << "< " << name << " : " << type << " >";
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

    void Print(ofstream &logout)
    {
        SymbolInfo *x = head;
        while (x != NULL)
        {
            logout << " ";
            x->Print(logout);
            x = x->nxt;
        }
        logout << "\n";
    }
    ~linked_list()
    {
        while (head != NULL)
        {
            SymbolInfo *now = head;
            head = head->nxt;
            delete (now);
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

    bool Insert(const string &key, const string &val , ofstream &logout)
    {
        int pos = hash(key, v.size());
        int it;
        bool ret = v[pos].insert(key, val, it);
        if (ret)
        {
            //logout << "Inserted in ScopeTable# " << id << " at position " << pos << ", " << it << "\n";
        }
        else
        {
            logout << key << " already exists in ScopeTable# " << id << "\n";
        }
        return ret;
    }

    SymbolInfo *LookUp(const string &key, int &pos, int &it , ofstream &logout)
    {
        pos = hash(key, v.size());
        return v[pos].search(key, it);
    }

    bool Delete(const string &key,ofstream &logout)
    {
        int pos = hash(key, v.size());
        int it;
        bool ret = v[pos].Delete(key, it);
        if (ret)
        {
            logout << "Found in ScopeTable# " << id << " at position " << pos << ", " << it << "\n";
            logout << "Deleted Entry " << pos << ", " << it << " from current ScopeTable\n";
        }
        else
        {
            logout << key << " doesn't exists in ScopeTable# " << id << "\n";
        }
        return ret;
    }

    void Print(ofstream &logout)
    {
        logout << "ScopeTable # " << id << "\n";
        for (int i = 0; i < v.size(); i++)
        {
            if (v[i].Size == 0)
            {
                continue;
            }
            logout << i << " -->";
            v[i].Print(logout);
        }
        logout << "\n";
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

    void enter_scope(ofstream &logout)
    {
        scopeTable->setChild(scopeTable->getChild() + 1);
        ScopeTable *tmp = new ScopeTable(bucket_size, scopeTable, Hash);
        scopeTable = tmp;
        //logout << "New ScopeTable with id " << scopeTable->getId() << " created\n";
    }

    void exit_scope(ofstream &logout)
    {
        //logout << "ScopeTable with id " << scopeTable->getId() << " removed\n";
        ScopeTable *tmp = scopeTable->getParent();
        delete (scopeTable);
        scopeTable = tmp;
    }

    bool insert_symbol(const string name, const string type , ofstream &logout)
    {
        return scopeTable->Insert(name, type,logout);
    }

    bool remove_symbol(const string name , ofstream &logout)
    {
        return scopeTable->Delete(name,logout);
    }

    SymbolInfo *LookUp(const string name , ofstream &logout)
    {
        ScopeTable *tmp = scopeTable;
        while (tmp != NULL)
        {
            int pos, it;
            SymbolInfo *x = tmp->LookUp(name, pos, it,logout);
            if (x != NULL)
            {
                logout << "Found in ScopeTable# " << tmp->getId() << " at position " << pos << ", " << it << "\n";
                return x;
            }
            tmp = tmp->getParent();
        }
        logout << "Not found\n";
        return NULL;
    }

    void PrintCurrentScope(ofstream &logout)
    {
        scopeTable->Print(logout);
        logout << "\n";
    }

    void PrintAllScope(ofstream &logout)
    {
        ScopeTable *tmp = scopeTable;
        while (tmp != NULL)
        {
            tmp->Print(logout);
            tmp = tmp->getParent();
        }
        logout << "\n";
    }
    ~SymbolTable()
    {
        while (scopeTable != NULL)
        {
            ScopeTable *now = scopeTable;
            scopeTable = scopeTable->getParent();
            delete (now);
        }
    }
};