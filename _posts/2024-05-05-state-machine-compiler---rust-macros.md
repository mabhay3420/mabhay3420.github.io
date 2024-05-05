---
layout: post
title: State Machine Compiler - Rust Macros
subtitle: And Why they might matter?
cover-img: https://source.unsplash.com/featured/1920x1080/
thumbnail-img: https://source.unsplash.com/featured/1920x1080/
tags: []
comments: true
readtime: true
usemathjax: true
---

In the [previous post](../2024-05-03-State-Machine-Compiler-Intro),
we ended up with a rust implementation of state machine simulation.
We also concluded that in order to test different state machine, we
would like a better way, as writing full code involves a lot of
boilerplate.

[Rust Macros](link_here) allow us to generate rust code by
parsing patterns and using them at appropriate places.

Our code can be divided into two parts:

1. Declarations
   a. States
   b. Symbols
   c. Tape machine specification

2. Simulation
   a. Given the tape machine state and tape head content, we
   perform the associated actions and transition to next
   state. We perform this for required number of steps.

Let's take a looks at declarations first.

## Declarations

Following is the declaration of states:

{% highlight rust %}

#[derive(Debug, PartialEq, Eq)]
enum TapeMachineState {
b,
o,
q,
p,
f,
}

{% endhighlight %}

If we had to write the same code for a different state machine,
say with states, a, b, c, d, then we will write:

{% highlight rust %} #[derive(Debug, PartialEq, Eq)]
enum TapeMachineState {
a,
b,
c,
d,
}

{% endhighlight %}

Since only the inner contents of the enum are changing, it would
be great if we could have something like this:

{% highlight rust %}
states(a, b, c, d);

{% endhighlight %}

Rust macros does exactly this, with a little different syntax:

{% highlight rust %}
states!(a, b, c, d);

// Generates the following code:
// #[derive(Debug, PartialEq, Eq)]
// enum TapeMachineState {
// a,
// b,
// c,
// d,
}

{% endhighlight %}

Let me present the macro definition and then i can explain how it works.

{% highlight rust %}

macro_rules! states {
( $( $x: ident),* ) => { #[derive(Debug)]
enum TapeMachineState {
$(
$x,
)\*\*
}
};
}

{% endhighlight %}

Lets break it down:

1. `macro_rules!` is a macro definition. It takes a name and a body.
2. `states!` is the name of the macro.
3. `( $( $x: ident),* )` is the pattern. This is what macro will consume. Lets simplify it:
   a. If remove `$` and `ident` etc., we will end up with
   `(x),*`. This will expand to `x`, `x`, `x` and so on.
   Rust will try to match the pattern with the input, and store the
   matched values in the `$x` variables. `ident` means the values
   should be identifiers. We can ignore it for now.
4. `#[derive(Debug)]` is the body of the macro. It will be output as
   it is.
5. Similarly, `enum TapeMachineState {`
6. Now we end up with:

```
                    $(
                        $x,
                    )*
```

This means for all the values stored in `x`, concatenate them
with `,` and then output them.

7. `}` is the end of the body.

So for our example:

1. `x` will be `a`, `b`, `c`, `d`
2. On expanding the body `$($x),*`, we will get: `a, b, c, d`
3. The whole body will be:
   {% highlight rust %} #[derive(Debug)]
   enum TapeMachineState {
   a, b, c, d
   }
   {% endhighlight %}
   Exactly what we wanted.

Let's look at symbol declarations:

{% highlight rust %}

#[derive(Debug, PartialEq, Eq, Clone)]
enum TapeMachineSymbol {
Symbol0,
Symbol1,
Symbole,
Symbolx,
SymbolX,
}

{% endhighlight %}

We will want a macro like this:

{% highlight rust %}

symbols!(0, 1, e, x, X);

// Generates the following code:
// #[derive(Debug, PartialEq, Eq, Clone)]
// enum TapeMachineSymbol {
// Symbol0,
// Symbol1,
// Symbole,
// Symbolx,
// SymbolX,
// }

{% endhighlight %}

Following similar logic, we can define the macro as:

[Clarify the `B`, `E`, `A` symbols. We dont need them actually.]
{% highlight rust %}
macro_rules! symbols {
( $(($x: ident)),\* ) => { #[derive(Debug)]
enum TapeMachineSymbol {
$(
$x,
)\*\*
B,
E,
A,
}
};
}

{% endhighlight %}

However in our initial implementation, we also wanted support
for printing the symbols.
Here is the code that we used:

{% highlight rust %}
impl TapeMachineSymbol {
fn as_str(&self) -> &'static str {
match self {
TapeMachineSymbol::Symbol0 => "0",
TapeMachineSymbol::Symbol1 => "1",
TapeMachineSymbol::Symbole => "e",
TapeMachineSymbol::Symbolx => "x",
TapeMachineSymbol::SymbolX => "X"
}
}
}

{% endhighlight %}

We would like to generate this as well. That means we will need
to take the value to be printed with each symbol. A macro like
following will do the job:

{% highlight rust %}
symbols!((Zero, "0"), (One, "1"), (X, "x"));

// Generates the following code:
// #[derive(Debug, PartialEq, Eq, Clone)]
// enum TapeMachineSymbol {
// Symbol0,
// Symbol1,
// Symbole,
// Symbolx,
// SymbolX,
// }
// impl TapeMachineSymbol {
// fn as_str(&self) -> &'static str {
// match self {
// TapeMachineSymbol::Symbol0 => "0",
// TapeMachineSymbol::Symbol1 => "1",
// TapeMachineSymbol::Symbole => "e",
// TapeMachineSymbol::Symbolx => "x",
// TapeMachineSymbol::SymbolX => "X"
// }
// }
// }

{% endhighlight %}

Here is the modified macro:

{% highlight rust %}

macro_rules! symbols {
( $(($x: ident, $y: literal)),* ) => { #[derive(Debug)]
enum TapeMachineSymbol {
$(
$x,
)\*\*
B,
E,
A,
}

        impl TapeMachineSymbol {
            fn as_str(&self) -> &'static str {
                match self {
                    $(
                        TapeMachineSymbol::$x => $y,
                    )*
                    TapeMachineSymbol::B => "",
                    TapeMachineSymbol::E => "",
                    TapeMachineSymbol::A => "*",
                }
            }
        }
    };

}

{% endhighlight %}

The only different is following line:

```
( $(($x: ident, $y: literal)),* )

```

This pattern will match the input so that `x` and `y` contain the
symbol name and the value to be printed in pair.

For example, following line will specify the different
values to be printed for different symbols:

```

                    $(
                        TapeMachineSymbol::$x => $y,
                    )*

```

What remains in the declaration is tape machine declaration, i.e.

{% highlight rust %}
struct TapeMachine<'a> {
    state: &'a TapeMachineState,
    result: &'a mut Vec<TapeMachineSymbol>,
    index: usize,
}

impl<'a> TapeMachine<'a> {
    pub fn new(state: &'a TapeMachineState, result: &'a mut Vec<TapeMachineSymbol>) -> Self {
        Self {
            state,
            result,
            index: 0,
        } 
    }

    fn p(&mut self, symbol: TapeMachineSymbol) {
        self.result[self.index] = symbol;
    }

    fn r(&mut self) {
        self.index += 1;
    }

    fn l(&mut self) {
        self.index -= 1;
    }

}

{% endhighlight %}

Notice how this specification doesnt vary with the symbols and
state machine used. We can have a very simple macro like this:

{% highlight rust %}

macro_rules! init_tape {
() => { 
        #[derive(Debug)]
        struct TapeMachine<'a> {
            state: &'a TapeMachineState,
            result: &'a mut Vec<&'a TapeMachineSymbol>,
            index: usize,
        }

        impl<'a> TapeMachine<'a> {
            pub fn new(
                state: &'a TapeMachineState,
                result: &'a mut Vec<&'a TapeMachineSymbol>,
            ) -> TapeMachine<'a> {
                return TapeMachine {
                    state,
                    result,
                    index: 0usize,
                };
            }
        }

        fn p<'a>(c: &'a TapeMachineSymbol, index: usize, vec: &mut [&'a TapeMachineSymbol]) {
            vec[index] = &c;
        }

        fn r(index: &mut usize) {
            *index += 1;
        }

        fn l(index: &mut usize) {
            *index -= 1;
        }
    };

}

{% endhighlight %}

Invoking the macro will simply generate the code for the
tape machine implementation:

{% highlight rust %}

init_tape!();

{% endhighlight %}

To summarize, If we have following tape machine:

1. States: a, b, c, d
2. Symbols: 0, 1, 2, 3, 4

We can generate the declarations using the following code:

{% highlight rust %}

states!(a, b, c, d);
symbols!((Zero, "0"), (One, "1"), (Two, "2"), (Three, "3"), (Four, "4"));
init_tape!();

{% endhighlight %}

Let's move on to the simulation part.

## Simulation

Here is the crux of the simulation:

{% highlight rust %}
for i in 0..steps {
println!("Step: {} State: {:?} Symbol: {:?}",
i, tape_machine.state, tape_machine.result[tape_machine.index]);

        match (tape_machine.state, &tape_machine.result[tape_machine.index]) {
            (TapeMachineState::o, TapeMachineSymbol::Symbol1) => {
                tape_machine.r();
                tape_machine.p(TapeMachineSymbol::Symbolx);
                tape_machine.l();
                tape_machine.l();
                tape_machine.l();
                tape_machine.state = &TapeMachineState::o;
                println!("Final State: {:?}", TapeMachineState::o);
            }
            (TapeMachineState::o, TapeMachineSymbol::Symbol0) => {
                // X means do nothing
                tape_machine.state = &TapeMachineState::q;
                println!("Final State: {:?}", TapeMachineState::q);
            }

{% endhighlight %}

Let's break down the structure:

1. `for i in 0..steps` is the loop that will run for required
2. `println!` is the print statement
3. Match statement is simply conditioning on the current state and
   the current symbol.
4. We perform the actions depending on the current state and symbol.
5. We update the state and print the final state.
6. We loop again.

If we can generate the code for one branch like this:

{% highlight rust %}
(TapeMachineState::o, TapeMachineSymbol::Symbol1) => {
tape_machine.r();
tape_machine.p(TapeMachineSymbol::Symbolx);
tape_machine.l();
tape_machine.l();
tape_machine.l();
tape_machine.state = &TapeMachineState::o;
println!("Final State: {:?}", TapeMachineState::o);
}
{% endhighlight %}

then we can just do `$(code generation logic for one rule)*` in our
macro.

Let's focus on a single rule for now. Here are the things we need:

1. The state
2. The symbol
3. The actions in order. If its a print statement then value to be
   printed is the symbol.
4. The next state

I propose the following macro:

{% highlight rust %}

handle_rule!([O], [1], [R, P(x), L, L, L], [O]);
// [state], [symbol], [actions], [next state]

{% endhighlight %}

Here is how this will look like in actual implementation:

```
([$state: ident], [$($condition: ident)|+], [$($action: expr),*], [$final_state: ident])

```

Let's break it down:

1. States: `[$state: ident]`
2. Symbols: `[$($condition: ident)|+]` : One or more coditions
3. Actions: `[$($action: expr),*]` : One or more actions
4. Final state: `[$final_state: ident]`

All of them comma separated.

Now because there are going to be multiple rules, we will just do
`$(rule)*` to match all the rules.

i.e.

```
$([$state: ident], [$($condition: ident)|+], [$($action: expr),*], [$final_state: ident])*

```

However there is a slight problem with this. There is no way to know
when a rule ends and when another rule starts. [ Clarify why we can't just use `;` ].

Let's settle on specifying multiple rules like this:

{% highlight rust %}

{[O], [1], [R, P(x), L, L, L], [O]},
{[O], [0], [R], [q]}
...

{% endhighlight %}

i.e. each rule is wrapped up in curly braces, separated by comma.

So our new macro will be something like this:

```
$({ handle_rule },*)
```

Here is how it will look like in actual implementation:

```
$({ [$state: ident], [$($condition: ident)|+], [$($action: expr),*], [$final_state: ident] } ),*

// Break it down like this:
// handle_rule = [$state: ident], [$($condition: ident)|+], [$($action: expr),*], [$final_state: ident]
// Full rule = $({ handle_rule }),*


```

Since the patterns are hard to read, visualize what the pattern
will allow us to do: It will parse the input and give us a list of rules. Each rule will have its state, symbol, actions and next state
stored in the corresponding variables.

Now the only different with the macros is that you cannot access the
list content by index. You will have to specify another pattern
which takes the elements of the list one by one and generates the
output sequence.

So to summarise:

```rust
Raw text -> Pattern to Match -> Parsed Sequence -> Patter to generate -> Generated code
```

We can also work with lists of lists, with same restriction: No indexing, only output pattern. [ Clarify how index can be passed, but again with complications]

With this in mind, let me present the final macro:

{% highlight rust %}
macro*rules! transition_rules {
($tape_machine: ident, $steps: ident, $({ [$state: ident], [$($condition: ident)|+], [$($action: expr),*], [$final_state: ident] } ),* )=> {
for i in 0..$steps {
            println!(
                "Step: {} State: {:?} Symbol: {:?}",i,
                $tape_machine.state, $tape_machine.result[$tape*machine.index]
);
match($tape_machine.state, $tape_machine.result[$tape_machine.index]) {
$(
                    (TapeMachineState::$state,
$(
                            process_action!($condition)
) | _
) => {
$(
$action;
)_
$tape_machine.state = &TapeMachineState::$final_state;
println!("Final State: {:?}", TapeMachineState::$final_state);
}
)\*
(*, **) => {
println!(
"{:?} {:?}",
$tape_machine.state, $tape_machine.result[$tape_machine.index]
);
panic!("Invalid state reached");
}
}
}
};
}

{% endhighlight %}

Notice the two levels of repeatation:

```
$( // First level repations starts
                    (TapeMachineState::$state,
$(
                            process_action!($condition)
) | _ // Second level repeation 1
) => {
$(
$action;
)_ // Second level repeation 2
$tape_machine.state = &TapeMachineState::$final_state;
println!("Final State: {:?}", TapeMachineState::$final_state);
}
)\* // First level repations ends

```

1. First level repeatations are corresponding to different rules.
2. Second level repeation 1 is for a particular rule, writing
   multiple coditions. e.g. `Symbol1 | Symbol0`. Notice that we
   have used `|` to separate the conditions and used another macro
   `process_action!` to process the actions. This macro is defined
   below:

{% highlight rust %}
macro*rules! process_action {
// If the rule states that for any symbol, the action
// has to be performed then we will use `*`as per
// rust syntax.
(A) => {

- };
  // Otherwise simply use the symbol
  ($action: ident) => {
        TapeMachineSymbol::$action
  };
  }
  {% endhighlight %}
  In summary all this trouble just to use`**` inside the match statement.

3. Second level repeation 2 is for a particular rule, writing
   multiple actions.e.g. `R, P(x), L, L, L` will translate to `R, P(x), L, L, L`.

But that's not what we wanted, right? We wanted something like this:

{% highlight rust %}
tape_machine.r();
tape_machine.p(TapeMachineSymbol::Symbolx);
tape_machine.l();
tape_machine.l();
tape_machine.l();
{% endhighlight %}

How about we define few more macros:

{% highlight rust %}
R!()
P!(x)
L!()
L!()
L!()

{% endhighlight %}

These macros can be defined as follows:

{% highlight rust %}

macro_rules! P {
($tape_machine: ident, $symbol: ident) => {
        p(
            &TapeMachineSymbol::$symbol,
$tape_machine.index,
$tape_machine.result,
)
};
}

macro_rules! R {
($tape_machine: ident) => {
r(&mut $tape_machine.index)
};
}

macro_rules! L {
($tape_machine: ident) => {
l(&mut $tape_machine.index)
};
}
{% endhighlight %}

These macros will perform following actions:

{% highlight rust %}
P!(tape_machine, Symbolx); -> p(&TapeMachineSymbol::Symbolx, tape_machine.index, tape_machine.result);
L!(tape_machine); -> l(&mut tape_machine.index);
R!(tape_machine); -> r(&mut tape_machine.index);

{% endhighlight %}

Where these functions have been defined in the declaration section.

A sidenote:
We need to pass `tape_machine` and `steps` in the `transition_rules!` macros. Why? Because we cannot just use
arbitrary variables in macros. Macros can use the variables that are
defined inside the body or the ones that are expicitly passed
to the macro. [Read more about this][link_here]

Alright, now we have all the macros defined, let's look at the final
program:

{% highlight rust %}
// Import the macros we defined
// TODO - Modify the code structure so that macros
// are defined in a separate file and can be imported
states!(B, O, Q, P, F);
symbols!((Zero, "0"), (One, "1"), (X, "x"));
init_tape!();

// To test: rustc +nightly -Zunpretty=expanded src/main.rs

fn main() {
let max_len = 1000;
let steps = 100;
let mut result: Vec<&TapeMachineSymbol> = vec![&TapeMachineSymbol::B; max_len];
let mut tape_machine = TapeMachine::new(&TapeMachineState::B, &mut result);
transition_rules!(
tape_machine,
steps,
{ [B], [A], [P!(tape_machine, E), R!(tape_machine), P!(tape_machine, E), R!(tape_machine), P!(tape_machine, Zero), R!(tape_machine), R!(tape_machine), P!(tape_machine, Zero), L!(tape_machine), L!(tape_machine)], [O] },
{ [O], [One], [R!(tape_machine), P!(tape_machine, X), L!(tape_machine), L!(tape_machine), L!(tape_machine)], [O] },
{ [O], [Zero], [], [Q] },
{ [Q], [Zero | One], [R!(tape_machine), R!(tape_machine)], [Q] },
{ [Q], [B], [P!(tape_machine, One), L!(tape_machine)], [P] },
{ [P], [X], [E!(tape_machine), R!(tape_machine)], [Q] },
{ [P], [E], [R!(tape_machine)], [F] },
{ [P], [B], [L!(tape_machine), L!(tape_machine)], [P] },
{ [F], [B], [P!(tape_machine, Zero), L!(tape_machine), L!(tape_machine)], [O] },
{ [F], [A], [R!(tape_machine), R!(tape_machine)], [F] }
);
let binary_result = tape_machine
.result
.iter()
.map(|x| x.as_str())
.collect::<String>();

    // 0010110111011110111110111111011111110111111110111111111
    println!("{}", binary_result);

}

{% endhighlight %}

Isn't this pretty concise? For a different state machine:

|Current State|Required Current Tape Head Content|Action|Next State|
|a|None|P(0)|b|
|b|0|R-P(1)|b|
|b|1|R|a|

The program will be:

{% highlight rust %}

// Copy paste or import the macros we defined
states!(a, b);
symbols!((Zero, "0"), (One, "1"), (X, "x"));
init_tape!();

// Copy paste or import the transition macros
// [ Need some work, since they cannot be out of oredr]

fn main() {
let max_len = 1000;
let steps = 100;
let mut result: Vec<&TapeMachineSymbol> = vec![&TapeMachineSymbol::B; max_len];
// A is the initial state
let mut tape_machine = TapeMachine::new(&TapeMachineState::A, &mut result);
transition_rules!(
tape_machine,
steps,
{[A], [A], [P!(tape_machine, Zero)],[B]},
{[B], [Zero], [R!(tape_machine), P!(tape_machine, One)], [B]},
{[B], [One], [R!(tape_machine)], [A]}
);

    let binary_result = tape_machine
        .result
        .iter()
        .map(|x| x.as_str())
        .collect::<String>();

    // 010101..
    println!("{}", binary_result);

}

{% endhighlight %}

Well, now we are in a much better state. Insted of having to
write the same code for a different state machine, we can
just specify the states, symbols and rules and we are done.

We are done for practical purposes, however the syntax is a little
bit verbose.
Can we specify the states, symbols and rules in a more concise way?
How about this:

```
STATES: [b], o, q, p, f

SYMBOLS: 0, 1, e, x

TRANSITIONS:
b, *, P(e)-R-P(e)-R-P(0)-R-R-P(0)-L-L, o
o, 1, R-P(x)-L-L-L, o
o, 0, X, q
q, 0 | 1, R-R, q
q, X, P(1)-L, p
p, x, P(X)-R, q
p, e, R, f
p, X, L-L, p
f, *, R-R, f
f, X, P(0)-L-L, o

```

This is the most concise we will every get(may replacing L-L-L with 3L, but ignore that for now).

Can we parse this and generate the code from scratch?
That is the topic of the next post.
