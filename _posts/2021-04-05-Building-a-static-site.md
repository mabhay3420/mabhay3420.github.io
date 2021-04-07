---
layout: post
title: How I build a simple static site
subtitle: Use beautiful-jekyll template
cover-img: assets/img/pexels-markus-spiske-1089438.jpg
thumbnail-img: assets/img/pexels-markus-spiske-1089438.jpg
tags: [books, test]
gh-repo: mabhay3420/mabhay3420.github.io
gh-badge: [star, fork, follow]
tags: [Web Developement,Experiments]
comments: true
readtime: true
---

I was trying to make a portfolio cum blogging website from Sep 2020. I was completely new to field of web developement so it took me a bit of time to go through HTML and CSS in order to make a decent looking website.

Yet Anyone who is begineer in the field knows its a bit complicated to develop a good looking website and then as it grows you want to automate things.

I got busy with my online semester and the "Static Sites" were forgotten for some time. Recently I was getting frustated with current "Infinitely stretched Lockdown for University students" So i decided to work on it again.

I had seen a few websites based on jekyll templates.I tried to develop one with "Hugo" but because it involved a bit of "GO" templating, I decided to find some other option.

In the end I stumbled across this amazing jekyll theme "beautiful-jekyll" and it works like charm.

This is my first post and a test post. I will try some different things so bear with me if they get not-so-interesting.

I will go step by step on how the whole process was completed. I am on Ubuntu 20.04.Using bash terminal.

## Steps for generating simple static site

1. Clone from beautiful-jekyll : Derived From [Here](https://stackoverflow.com/questions/6613166/how-to-duplicate-a-git-repository-without-forking)
{%highlight bash linenos %}
$ mkdir foo; cd foo
# move to a scratch dir

$ git clone --bare git@github.com:daattali/beautiful-jekyll.git
# make a bare clone of this amazing template

$ cd beautiful-jekyll
$ git push --mirror git@github.com:exampleuser/exampleuser.github.io.git
# push to the github page source

$ cd ../
$ rm -rf beautiful-jekyll
# remove temporary directory

{%endhighlight%}
