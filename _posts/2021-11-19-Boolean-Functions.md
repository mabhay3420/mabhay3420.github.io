---
layout: post
title: Boolean Functions
subtitle: And Why they might matter?
cover-img: https://source.unsplash.com/collection/8877554/1920x1080
thumbnail-img: https://source.unsplash.com/collection/88775549/1920x1080 
tags: [tcs, article]
comments: true
readtime: true
usemathjax: true
---

A friend of mine is working on getting lower bound on the time complexities of a
boolean function. Boolean functions are functions that take a certain no of bits
( equivalently a binary string ) and output a single bit ( 0 or 1).

Putting aside my love for fancy, pure mathematics, i was wondering why in the world
someone would start studying the time complexities of these particulary type of 
functions. 

I realized the following fact while revising my notes of "Theory of Computation",
Every function/program with input and output, which can be executed in a computer is essentially a General boolean function.
> function/Program :: Binary String -> Binary String

One more thing, A function and program are essentially equivalent. A program can be
seen as a composition of functions. Though this is not easy to see in C like languages,
but there are pure functional languages like haskell which uses function application
as the basis of computation. Now atleast on a higher level, we feel that C like languages
and haskell ( or for that matter, any language that is turing complete ) are equivalent. 

Okay, So what does (simple) Boolean functions signify? They represent programs which take
a input and output yes (1) or no (0).

Now a lot of problems can be framed in a manner, so as to have a yes or no output. One example
i can think of now is the following?
```
Original Program:
	Input : a list of n positive integers
	Output: Biggest number in the list
Decision version:
        Input : a list of n positive integers along with a number k
	Output: Yes if k is larger than all the numbers
Algorithm: k = 1 in the starting 
           and Keep incrementing k till you get "YES" as answer.
Biggest number : k - 1
```

Even though a large set of problems can be framed in this manner ( i.e. there is a decision
version of the problem ), can we say that all programs ( that can be executed in a computer)
can be computed ( executed ) in this manner?

Honestly I am not completely sure about it, but what i can remember is that we are asking something similar to 
what Alan Turing asks in his paper "[Can machines Think?](https://academic.oup.com/mind/article/LIX/236/433/986238)".

He questioned about whether we can construct a machine that
is intelligent, atleast indistinguishable from a human
being. The machine proposed was a question answering
machine, similar to what we are searching here.