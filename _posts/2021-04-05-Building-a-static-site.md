---
layout: post
title: How I build a simple static site
subtitle: Use beautiful-jekyll template
cover-img: https://source.unsplash.com/collection/2513270/1920x1080
thumbnail-img: assets/img/pexels-negative-space-160107.jpg
gh-repo: mabhay3420/mabhay3420.github.io
gh-badge: [follow]
tags: [Web Developement,Experiments]
comments: true
readtime: true
---

This is my first post and a test post. 
I will try some different things so bear with me if they get not-so-interesting.
I will go step by step on how the whole process was completed. I am on Ubuntu 20.04.Using bash terminal.

## Steps for generating simple static site

{: .box-note}
**Note:** Make sure git is installed on your system.

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
#These steps setup the gem(RubyGems Packages) installation directory in your home directory and update the PATH variable.

$ gem install jekyll bundler
#install jekyll and bundler : will take some time
{%endhighlight%}

{: .box-error}
**Error:** In case you get any error try updating your system using "sudo apt-get update" and then repeat the same steps. Otherwise StackOverflow is your friend.

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

{: .box-success}
**Success:** We have made a simple Static website. Jekyll Templates gives you the flexibility to just focus on content ( Which you write In Markdown ) and other things are taken care of, Ideal for Personal Blogs and Sites.

**Thanks**