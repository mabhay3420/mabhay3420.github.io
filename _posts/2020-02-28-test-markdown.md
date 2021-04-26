---
layout: post
title: Sample blog post
subtitle: Each post also has a subtitle
gh-repo: daattali/beautiful-jekyll
gh-badge: [star, fork, follow]
tags: [test]
comments: true
---

This is a demo post to show you how to write blog posts with markdown.  I strongly encourage you to [take 5 minutes to learn how to write in markdown](https://markdowntutorial.com/) - it'll teach you how to transform regular text into bold/italics/headings/tables/etc.

**Here is some bold text**

## Here is a secondary heading

Here's a useless table:

| Number | Next number | Previous number |
| :------ |:--- | :--- |
| Five | Six | Four |
| Ten | Eleven | Nine |
| Seven | Eight | Six |
| Two | Three | One |


How about a yummy crepe?

![Crepe](https://s3-media3.fl.yelpcdn.com/bphoto/cQ1Yoa75m2yUFFbY2xwuqw/348s.jpg)

It can also be centered!

![Crepe](https://s3-media3.fl.yelpcdn.com/bphoto/cQ1Yoa75m2yUFFbY2xwuqw/348s.jpg){: .mx-auto.d-block :}

Here's a code chunk:

~~~
var foo = function(x) {
  return(x + 5);
}
foo(3)
~~~

And here is the same code with syntax highlighting:


{% highlight cpp linenos %}


#include <bits/stdc++.h>
using namespace std;
using namespace std::chrono;

/*-------------------------------------*---------------------------------------*/

#define ll long long
#define F(i, m, n) for (ll i = m; i < n; i++)
#define Fr(j, n, m) for (ll j = n; j >= m; j--)
#define vll vector<ll>
#define pll pair<ll, ll>
#define ff first
#define ss second
#define vpll vector<pll>
#define tlll tuple<ll, ll, ll>

/*-------------------------------------*---------------------------------------*/

#define godspeed                      \
    ios_base::sync_with_stdio(false); \
    cin.tie(NULL);                    \
    cout.tie(NULL)
#define deb(x) cout << #x << "=" << x << endl
#define cout_array(a)     \
    cout << #a << "=";    \
    for (auto x : a)      \
    {                     \
        cout << x << " "; \
    }                     \
    cout << endl

/*-------------------------------------*---------------------------------------*/
/**
 * Calcultes greatest Common divison using Euclid's division Lemma
 * 
 * @param   a,b Input numbers whose gcd is to be calculated
 * @returns GCD of a and b
 */
ll gcd(ll a, ll b)
{
    return (b ? gcd(b, a % b) : a);
}
const ll MAX_PRIME = 1e9 + 7;
const ll INF = 1e18 + 1;
const pll EXTREMA = make_pair(INF, -INF);
/**
 * Calculates (x^y)%z Using Binary Exponentiation . Similar to pow(x,y,z) function of python
 * 
 * @param   x,y Input numbers
 * @param   z if not specified default to 1e18
 * @returns pow(x,y) modulo z
 */
ll fast_pow(ll x, ll y, ll z = INF)
{
    if (y == 0)
        return 1 % z;
    else if (y == 1)
        return x % z;
    if (y % 2 == 0)
    {
        ll res = fast_pow(x, y / 2, z);
        return (res * res) % z;
    }
    else
    {
        ll res = fast_pow(x, y / 2, z);
        ll temp = (res * res) % z;
        return ((x % z) * temp) % z;
    }
}

/*-------------------------------------*---------------------------------------*/

/**
 * @author Abhay Mishra
 * @date   Apr 16 2021
 */
/*-------------------------------------*---------------------------------------*/
int main()
{
#ifndef ONLINE_JUDGE
    freopen("input.txt", "r", stdin);
    freopen("output.txt", "w", stdout);
    auto start = high_resolution_clock::now();
#endif
    godspeed;
    ll t;
    cin >> t;
    while (t--)
    {
        ll n;
        cin>>n;
        vll a(n);
        vll b(n,0);
        F(i,0,n){
            cin>>a[i];
            if(i==0){
                b[i] = a[i];
            }
            else{
                b[i] = b[i-1] ^ a[i];
            }
        }

        if(n==2){
            if(a[0]==a[1]){
                cout<<"YES"<<endl;
            }
            else cout<<"NO"<<endl;
            continue;
        }
        // cout_array(b);
        // 2 partition 
        bool flag1 = 0;
        for(ll i = 0;i<=n-2;i++){
            if(b[i]== (b[n-1]^b[i])){
                flag1 = 1;
                // deb(i);
                // deb(b[i]);
                break;
            }
        }
        // 3 partition
        bool flag2 = 0;
        ll val;
        for(ll i=0;i<=n-3;i++){
            if(flag2)break;
            val = b[i];
            for(ll j = i+1;j<=n-2;j++){
                if(((b[j]^b[i])==val) && ((b[n-1]^b[j])==val)){
                    flag2 =1;
                    // deb(val);
                    // deb(i);
                    // deb(j);
                    break;
                }
            }
        }

    
                              
{% endhighlight %}

And here is the same code yet again but with line numbers:

{% highlight python linenos %}
import random
f = open("input.txt", "w")
t = 1000
f.write(str(t)+"\n")
for i in range(t):
    n = random.randint(1,100)
    k = random.randint(1,50)
    f.write(str(n) + " ")
    f.write(str(k) + "\n")
    for j in range(n):
        a = random.randint(1,10000000)
        f.write(str(a)+ " ")
    f.write("\n")
f.close()
}
                              
{% endhighlight %}

## Boxes
You can add notification, warning and error boxes like this:

### Notification

{: .box-note}
**Note:** This is a notification box.

### Warning

{: .box-warning}
**Warning:** This is a warning box.

### Error

{: .box-error}
**Error:** This is an error box.
