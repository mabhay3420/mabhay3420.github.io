---
layout: post
title: Boolean Functions
subtitle: And Why they might matter?
cover-img: https://source.unsplash.com/collection/1695735/1920x1080
thumbnail-img: https://source.unsplash.com/collection/1695735/1920x1080 
tags: [tcs, article]
comments: true
readtime: true
usemathjax: true
---

A friend of mine,[Aman Agrawal](https://aman-agrawal01.github.io/), is working on getting approximate lower bound on the time complexities of a
boolean function. Boolean functions are functions that take a certain no of bits
( equivalently a binary string ) and output a single bit ( 0 or 1).

Putting aside my love for fancy, pure mathematics, i was wondering why in the
world someone would start studying the time complexities of these particulary
type of functions. 

## Programs and Boolean Functions

I realized the following fact while revising my notes of "Theory of
Computation", Every function/program with input and output, which can be
executed in a computer is essentially a General boolean function.
> function/Program :: Binary String -> Binary String

## Functions vs Programs

One more thing, A function and program are essentially equivalent. A program can
be seen as a composition of functions. Though this is not easy to see in C like
languages, but there are pure functional languages like haskell which uses
function application as the basis of computation. Now atleast on a higher level,
we feel that C like languages and haskell ( or for that matter, any language
that is turing complete ) are equivalent. 

## (Simple) Boolean Functions

Okay, So what does (simple) Boolean functions signify? They represent programs
which take a input and output yes (1) or no (0).

Now a lot of problems can be framed in a manner, so as to have a yes or no
output. One example i can think of now is the following?

### Original Program

Input : a list of n positive integers  
Output: Biggest number in the list
### Decision version

Input : a list of n positive integers along with a number k  
Output: Yes if k is larger than all the numbers

### Algorithm

k = 1 in the starting   
Keep incrementing k till you get "YES" as answer.  
Output  : k - 1

## Question-Answering Machine 

Even though a large set of problems can be framed in this manner ( i.e. there is
a decision version of the problem ), can we say that all programs ( that can be
executed in a computer) can be computed ( executed ) in this manner?

Honestly I am not completely sure about it, but what i can remember is that we
are asking something similar to what Alan Turing asks in his paper "[Can
machines Think?](https://academic.oup.com/mind/article/LIX/236/433/986238)".

He questioned about whether we can construct a machine that is intelligent,
atleast indistinguishable from a human being. The machine proposed was a
question answering machine, similar to what we are searching here.

## Formalization

To Formalize our Intution about these type of programs ( that can be executed on
a computer) I will present three (loose) definitions:

### Turing Machine(TM) With Output

Any Computer that reads input from memory, perform some computation and write
output back to memory.

### Computable Function

A function :: String -> String, is said to be computable if $$\exists$$ A "TM
with output" $$M$$ st $$\forall$$ string $$x$$ , M halts with $$f(x)$$ written
on output memory segment.

### Church-Turing Hypothesis

Anything that can be computed can be computed by a Turing Machine.

### Final thoughts

At my current level of understanding, I cannot state anything about whether we
can convert every computable function to its decision version, but a large class
of problem which are of general interest (e.g. Sorting a list) and From my
intution, problems involving finite numbers should be convertible to computing a
Boolean function over the (augmented) input.

Thus getting a lower bound on time complexity of a boolean function is
equivalent to getting a lower bound on solving the problem. There are technical
details which I don't know yet, but the idea that you can prove that "No
algorithm solving this problem will have time complexity better than O(something)"
is Fascinating.
