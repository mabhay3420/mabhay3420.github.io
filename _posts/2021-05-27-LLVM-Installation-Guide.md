---
layout: post
title: Getting LLVM from Source
subtitle: Minimize Build time and space usage.
cover-img: https://source.unsplash.com/collection/948143/1920x1080
thumbnail-img: assets/img/pexels-irina-iriser-1379636.jpg
tags: [tech]
comments: true
usemathjax: true
---

LLVM-Project comprises of many low-level utilities, The most important of which is `llvm` core.
LLVM core is a big piece of software and when combined with additional packages which are part of LLVM-project. like clang and lld, The complete build size can reach up to 70-80 GB.

In case you just want to use the command line interface of llvm tools like `clang` , `lld` , you should download pre-built binaries. Source code is needed when you want the bits and pieces of llvm in order to build something new or add something to or modify existing code.

I spent whole day installing it and the result was super slow and 70GB Build. After setting proper option and using
`ninja` I was able to build withing 40 minutes and total build size was 9GB.

I will present here the minimum steps needed to get `llvm-project` source code and then build it efficiently.
## Get the Source Code
This fetches complete source code, You may want to fetch only a particular version, for that refer llvm docs.
{% highlight bash linenos %}
user@user:~$ git clone https://github.com/llvm/ llvm-project.git
user@user:~$ cd llvm-project
{% endhighlight %}
## Setup Build directory and build tool

Build tools automate the compilation of source files. Most popular of these is `make` and  `ninja` build system.
We will need a `Makefile` or `build.ninja` files for specifying compilation rules.

`cmake` can generate these files for build system by using a `CMakefile`, Which are already present in the directory.

Using `ninja` is recommended. Install these tools if not already installed with.
{% highlight bash linenos %}
user@user:~$ sudo apt-get install ninja-build
user@user:~$ sudo apt-get install cmake
{% endhighlight %}

Then generate build.ninja Files using `cmake` with proper flags:

{: .box-note}
**Note:** Flags are case sensitive. Files are generated for Release version with proper flags to make a good substitue of Slow and Big Debug Version. Make Sure they match your needs.

{% highlight bash linenos %}
user@user:~/llvm-project$ mkdir build
user@user:~/llvm-project$ cd build
user@user:~/llvm-project/build$ cmake -G "Ninja" -DLLVM_ENABLE_PROJECTS="clang" -DLLVM_USE_LINKER=gold -CMAKE_BUILD_TYPE=Release -LLVM_ENABLE_ASSERTIONS=ON -LLVM_CCACHE_BUILD=ON ../llvm
{% endhighlight %}

## Build And Run Test

{: .box-note}
**Tips:** These Steps are probably going to take somewhere between $$1$$ to $$1\frac{1}{2}$$ hours, And your system will become slow ( By default `ninja` uses all cores to complete jobs in parallel.) .Plug in your charger And find yourself something else to do.

{% highlight bash linenos %}
user@user:~/llvm-project/build$ ninja
user@user:~/llvm-project/build$ ninja check-clang
{% endhighlight %}

## Update PATH
Add following lines to start using llvm tools
{% highlight bash linenos %}
user@user:~/llvm-project/build$ echo "export PATH="$PATH:~/llvm-project/build/bin"" >> ~/.bashrc
user@user:~/llvm-project/build$ source ~/.bashrc
# Start Using Clang or any of the tools available
user@user:~$ clang++ hello.cpp -o hello.o
{% endhighlight %}



## Complete Bash Script

{: .box-warning}
**Warning:** Before Using the script Make Sure you understand the steps and Change File Paths in the scrept when required.
{% highlight bash linenos %}
#!/bin/bash
# Installing in home directory
cd
git clone https://github.com/llvm/ llvm-project.git
cd llvm-project
sudo apt-get install ninja-build
sudo apt-get install cmake
mkdir build
cd build
cmake -G "Ninja" -DLLVM_ENABLE_PROJECTS="clang" -DLLVM_USE_LINKER=gold -CMAKE_BUILD_TYPE=Release -LLVM_ENABLE_ASSERTIONS=ON -LLVM_CCACHE_BUILD=ON ../llvm
ninja
ninja check-clang
echo "export PATH="$PATH:~/llvm-project/build/bin"" >> ~/.bashrc
source ~/.bashrc
{% endhighlight %}

### Why Use Ninja
`ninja` is a bit faster than `make`, But the main reason for using ninja is its ability to reduce the amount of time it takes to build next time.
Suppose you wrote a new source file using llvm source files and want to build and use the binary. There are two things you can do:
1. Make a seperate CMakeLists.txt file and specify various configuration. ( For e.g. if you include files from llvm folder you need to specify this : include_directories(${LLVM_INCLUDE_DIRS}))

2. Add file to the source in proper place and update CMakeLists.txt file of the source code.

Now because CMake Files of source code are obviously better than ours ( Well tested and with proper flags ) Choosing 2nd options seems logical.

But that required building whole source again.When prompted to build, Both `make` and `ninja` check which files are needed to build again and build only them.Here `ninja` does a better job than `make`. `make` builds some files (other than those changed ) again,I don't know why . Other than that it seems like `make` inspects every file one by one making build time approx 4-5 minutes, While `ninja` takes **<1 min**. 

If you don't change the source code and try to build `ninja` will say "No work to do" while `make` builds and links some ".inc" files.

{: .box-success}
**Success:** LLVM (And other tools in llvm-project) are great piece of software. The design and modularity not only makes various parts reusable, it also makes it easy to understand a particular part of software without worrying too much about the bigger picture. I am currently exploring Optimization part of Compiler (The llvm Core) and excited to learn more along the way.

