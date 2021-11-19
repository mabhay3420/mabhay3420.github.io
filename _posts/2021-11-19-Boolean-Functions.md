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

A boolean function is a function which takes a binary string as its input
and outputs a single bit, 0 or 1.
Mathematically,

$$ f : {\sum}^{*} \rightarrow \sum $$

$$ \sum = \{0, 1\} $$

The star(*) operation simply denotes that one can concat elements from B
as many times as one wants.

A friend of mine is working on getting lower bound on the time complexities of a
boolean function.  Loosely speaking, one want to deduce the minimum time taken by 
the computation that f performs. 

These functions seemed interesting to me because it seemed that almost
all problems can be formulated as decision problem, i.e. a problem which gives 
an answer of type "yes" or "no" to each question asked.

This guess was not something original. I have read some part of Alan turing's famous
paper "Can machines think?". The construction of machine which can reason on
its own essentially works by answering questions in the form of yes and no.

Now the relation between a general problem and this type of question-answering machine
was not clear to me immediately, But when i came across the following statement in
my Theory of Computation lecture notes something clicked to me:

>Languages === Boolean Functions