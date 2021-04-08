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

- Clone from beautiful-jekyll : Derived From [Here](https://stackoverflow.com/questions/6613166/how-to-duplicate-a-git-repository-without-forking)
{%highlight bash linenos %}
$ mkdir foo; cd foo
#move to a scratch dir

$ git clone --bare git@github.com:daattali/beautiful-jekyll.git
#make a bare clone of this amazing template

$ cd beautiful-jekyll
$ git push --mirror git@github.com:exampleuser/exampleuser.github.io.git
#push to the github page source

$ cd ../
$ rm -rf beautiful-jekyll
#remove temporary directory

$ git clone git@github.com:exampleuser/exampleuser.github.io.git
#Assuming Github Page setup already done
{%endhighlight%}

- Adding your content : Please refer to the [home page](https://github.com/daattali/beautiful-jekyll)

- Deploying site locally : This is a must step for smooth content creation. I will present the minimum steps needed. Please refer to [this](https://docs.github.com/en/pages/setting-up-a-github-pages-site-with-jekyll/testing-your-github-pages-site-locally-with-jekyll) and [this](https://jekyllrb.com/docs/installation/)

{: .box-warning}
**Warning:** The commands presented here have been tested on Ubuntu 20.04 and were run on bash terminal. In case your system is very different (Ubuntu older versions should work fine) and you are not familiar with commands please refer to the source given above.

{%highlight bash linenos %}
$ sudo apt-get install ruby-full build-essential zlib1g-dev
#install ruby and other required packages

$ echo '# Install Ruby Gems to ~/gems' >> ~/.bashrc
$ echo 'export GEM_HOME="$HOME/gems"' >> ~/.bashrc
$ echo 'export PATH="$HOME/gems/bin:$PATH"' >> ~/.bashrc
$ source ~/.bashrc
#These steps setup the gem(RubyGems Packages) installation directory
#your user account and update the environment variables.

$ gem install jekyll bundler
#install jekyll and bundler : will take some time
{%endhighlight%}

- Build the site : The page will be automatically update whenever you change some file except configuration files. In the later case you need to repeat only last step again.

{%highlight bash linenos %}
$ cd exampleuser.github.io
#move to the source folder(depends on where you cloned the repo)

$ bundle install
#setup gem files

$ bundle exec jekyll serve
#Ctrl+click on the local host server : You are all set
#Run this command if you changed some configration file
{%endhighlight%}

- That completes the process. Please refer to the jekyll docs and beautiful-jekyll homepage to learn about front matter, directory structure and different
customization options available.

**Thanks**