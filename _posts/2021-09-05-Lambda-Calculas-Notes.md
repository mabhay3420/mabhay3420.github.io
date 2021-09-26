---
layout: post
title: Lambda Calculas 
subtitle: Principle of Programming languages 
cover-img: https://source.unsplash.com/collection/16292248/1920x1080
thumbnail-img: assets/img/pexels-christian-heitz-842711.jpg
tags: [notes]
comments: true
---
## Untyped Lambda Calculas

### Syntax

         t :=   x   variable
                |λx.t  Abstraction
                |t t  Application

### Reducing the no of parenthesis

        λx.t1 t2 t3 == λx.(t1 t2 t3)
        t1 t2 t3 == (t1 t2) t3 : Associate to the left
        λx y z.t == λx.(λy.(λz.t))

### Free and Bound Variables

        Occurence of x inside a term "λx.N" // important
                λx - binder
                N - scope of the binder
                A variable occurence that is not bound is free
                FV(M) : The set of free variables of M.
                e.g. M = (λx.x y)(λy. y z) : x is a bound variable
                FV(M) = {y,z}
                some constrains are set on the value

                --
                whatever the function get value explicity it gets bounded
                Free variables in some sense similar to global

### α-renaming

        Name of bound variable has no meaning
        Renaming does not changed the meaning
        λx.x x y == λu.u u y
        λu.u u y ≠ λx.x x w (cannot rename free variables)


### Substitution

        M[x:=N]: Substitute all free occurence of x in M by N
        Issues:
                1. Replace free variables only
                 x(λx y.x)[x:=N] = N(λx y.x) ≠ N(λxy.N)
                2. No unintended name captures
                 M = λx.y x
                 N ≡ λz.x z
                 Then M[y := N] is λx.(λz.xz)x
                 ⇒ a free variable x becomes bound

        Solution: α renaming
        M[y:=N] = (λx'.y x')[y := N] = λx'.N x'
           = λx'.(λz.x z)x'

### β-Reduction

        Applying abstraction:
        λx.t1 t2 ⇒ t1[x:= t2] // replace only free variables
                // notice we are substituting
                // in t1 and not in whole λx.t1 t2
        Caution
                1. Free variables should not be captured
                 (λxλy.x)(λx.y) → β reduction → λy.(λx.y)
                  // wrong because y gets bounded
                 // first α renaming
                 (λuλv.u)(λx.y) → β reduction → λv.(λx.y)
                 FV = {y}

### Execution Semantics

        β-reduction gives the execution model of program
        β-redex : (λx.M)N
        one-step β-reduction: M[x:= N]
         (λz.z z)(λw.w) = (λw1.w1)(λw2.w2) 
                 = (λw2.w2)
         (λx.y)((λz.z z)(λw.w)) → β-reduction → y
        A term which does not have a β-redexes, are said to be
             normal form
        M → β-reduction → M' where M' is in normal form we say
           M evaluates to M' 


## Simply Typed Lamda calculas

### Simple types over Bools

    T :=        - Types
        Bool    - Boolean type
        T → T   - Function type

    type constructor → is right associative:
        T1 → T2 → T3 ≡ T1 → ( T2 → T3)
    This is compatible with application order:
        t1 t2 t3 ≡ ((t1 t2) t3)
        e.g.
            (λx.x λy.y λz.z) will take
            x as argument first then returns a function
            which takes y as arguments returns
            a value of type z
            { Improve a little bit}

        e.g.
            Bool → Bool : NOT
            Bool → Bool → Bool : AND, OR 
            (Bool → Bool) → Bool:
                A function which takes another
                function and returns a bool

                The input function itself takes a 
                bool input and produces another bool
                input

                NOT: λx.x false true
                λx:Bool → Bool.x true

### The Abstract Syntax

    t :=    x           - Variable
    |   λx.T.t          - Abstraction
    |   t t         - Application
    |   true            - constant true
    |   false           - constant false
    |   if t then t else t  - conditional

### The set of Values

    v :=            - values
        λx: T.t     - Abstraction Value
      | true        - value true
      | false       - value false

### Evaluation

    t1 → t1' ⇒ t1 t2 → t1' t2   [ E-APP1 ]
    t2 → t2' ⇒ v t2 → v t2'     [ E-APP2 ]
        [ i.e. first reduce t1 to its normal
        form and then start reducing t2]
    (λx:T.t1)v2 → [x → v2]t1    [ E APPABS]
        [ Use β-reduction ]

### The Typing Relation

    A typing context or Type Environment, Γ,
        : A sequence of variables with their types

    e.g. Γ [ x:Bool, y:Bool → Bool, z: T → Bool]

    Adding a new entry: Γ,x: T
        ▶ The name x is assumed to be distinct from
        any existing name in Γ
            : Rename if needed
            : Note that types are always associated
             with bound variables

    ▶ Γ,x: T1  ⊢ t2: T2 ⇒ Γ ⊢ λx: T1.t2: T1 → T2 [ T-ABS]
    ▶ x: T ∈ Γ ⇒ Γ ⊢ x: T   [ T-VAR]
        [ this is like a base case]
    ▶ Γ ⊢ t1 : T1 → T2  Γ ⊢ t2 : T1 
            ⇒ Γ ⊢ t1 t2 : T2    [ T-APP ]

### The inversion of the typing relation

    ▶ if Γ ⊢ x: R, then x:R ∈ Γ
        No other way to infer the definition
    ▶ if Γ ⊢ λx:T1.t2: R, then R = T1 → R2 for some R2 with
        Γ,x: T1 ⊢ t2 : R2
    ▶ if Γ ⊢ t1 t2: R, then ∃ T1 s.t. Γ ⊢ t1 : T1 → R and Γ ⊢ t2 : T1  
    ▶ Γ ⊢ true : R, then R = Bool
    ▶ Γ ⊢ false: R then R: Bool
    ▶ Γ ⊢ if t1 then t2 else t3: R then
        ▶ Γ ⊢ t1 : Bool
        ▶ Γ t2 : R
        ▶ Γ t3 : R


These notes were prepared in the starting of CS350(POPL).
One fine morning I planned to take notes using `vim` while watching
lectures ( Because i thought it was cool). Everything was fine until
Greek letters started appearing. One option was to use latex but that
seemed overkill, so i decided to stick with text format. Vim has
something called `digraphs` for inserting unicode symbols. In order to
insert a symbols, you use `Ctrl-K` + `symbol code`. Symbol codes were
very intutive e.g. for λ : "Ctrl-K" + "l*".
But because for inserting a single symbol you need 4 keystrokes i had to
do some hack over this. As always created new key mappings, in particular:

        " Shortcut for digraphs insertion in text files
        digraphs tl 8866
        " ⊢ symbol 
        inoremap <leader>tl <C-k>tl
        " \in : ∈
        inoremap <leader>in <C-k>(-
        " Capital gamma: Γ
        inoremap <leader>Gm <C-k>G*
        " small lambda : λ
        inoremap <leader>ld <C-k>l*

So what you see below took atleast 6 hours.(Including 2-3 hours of google search
and exploring different vim customizations and plugins)