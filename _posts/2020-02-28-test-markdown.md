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


{% highlight cpp lineos %}


int main()
{
    freopen("input.txt", "r", stdin);
    freopen("output.txt", "w", stdout);
    // auto start = high_resolution_clock::now();
    godspeed;
        ll t;
        cin>>t;
    while (t--)
    {
        long long n;
        cin>>n;
        vector<long long> a(n);
        for(int i = 0;i<n;i++){
            cin>>a[i];
        }
        cout<<a[n-1]<<endl;
    }

    // auto stop = high_resolution_clock::now();
    // auto duration = duration_cast<milliseconds>(stop-start);
    // cout<<"Total Time taken to execute the program is :"<<duration.count()<<" ms"<<endl;
    return 0;
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
