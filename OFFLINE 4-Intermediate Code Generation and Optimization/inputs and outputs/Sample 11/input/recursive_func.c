int f(int a){
    if(a<=1)
    {
        return a;
    }
    return f(a-1) + f(a-2);
}

int g(int a)
{
    if(a==0)
    {
        return 1;
    }
    int x;
    x= a*g(a-1);
    return x;
}

int main(){
    int i;
    int b;
    int c[5];
    for(i=0;i<5;i++)
    {
        c[i] = f(i);
    }
    for(i=0;i<5;i++)
    {
        b = c[i];
        println(b);
    }
    for(i=0;i<5;i++)
    {
        b = g(i);
        println(b);
    }
    return 0;
}
