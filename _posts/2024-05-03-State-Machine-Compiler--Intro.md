---
layout: post
title: State Machine Compiler - Intro
subtitle: Computing numbers
cover-img: https://source.unsplash.com/featured/1920x1080/
thumbnail-img: https://source.unsplash.com/featured/1920x1080/
tags: [compiler, toc, computation]
comments: true
readtime: true
usemathjax: true
---

Today the architecture of a computure seems very natural:

1. a memory unit: to store the result of computation (Disk, RAM etc.)
2. a logic unit: which performs computation(CPU, GPU etc.)

This architecture is based on [Von Neuman Model](link_here) of computing, but the
roots trace back to [Turing's Paper](link_here) on what all numbers are computable.

The paper starts with the setup in which a human computer( A human who is computing)
computes a certain number via an algorithm. The human has access to a paper and pencil,
and her own mind. The human is assumed to have finite amount of memory, where one tracks
the current state of computation.

This is then abstracted:

1. A tape divided into squares: this can be used as paper
2. A head: the location on tape which can be read and written. The head can move towards any of the two ends of tape.
3. Internal state logic: The logic of algorithm can be encoded in this device. This will
   control the state transition and the tape head movement

A number is said to be computable if one can construct a state machine that will output
the number on the tape in finite number of steps. [ Why finite?]

Let's take an example. Suppose we want to calculate a number of the form (01)^n, i.e.

```
0101010101...
```

Here is a description of state(tape) machine will:

1. Start with state a.
2. If the state is a, irrespective of content of tape, write 0 on current head and change internal state to b.
3. If the internal state is b and current head reads 0 then move the head to right and write 1 on tape. The internal state doesn't change.
4. If the internal state is b and current head reads 1 then move the head to right and change internal state to a.
5. We are back at step 2.

<details>
<summary>
Here is how this plays out:
</summary>

Step 1:

{% highlight rust linenos %}
Internal state: a
Tape: | | | | | |...
Head: ^
Logic: Write 0 and transition to b
{%endhighlight %}

Step 2:

{% highlight rust linenos %}
Internal state: b
Tape: |0| | | | |...
Head: ^
Logic: Move right and write 1
{%endhighlight %}

Step 3:

{% highlight rust linenos %}
Internal state: b
Tape: |0|1| | | |...
Head: ^
Logic: Move right and transition to a
{%endhighlight %}

Step 4:

{% highlight rust linenos %}
Internal state: a
Tape: |0|1| | | |...
Head: ^
Logic: Write 0 and transition to b
{%endhighlight %}

Step 5:

{% highlight rust linenos %}
Internal state: b
Tape: |0|1|0| | |...
Head: ^
Logic: Move right and write 1
{%endhighlight %}

</details>

You get the idea. Here is more concise way of writing the same logic:

| Current State | Required Current Tape Head Content | Action | Next State |
| a | None | P(0)|b|
|b| 0 | R-P(1)|b|
|b| 1 | R | a|

The paper presents another intereseting sequence that one can calculate by this setup:

```
0 01 011 0111 0111 ...
```

i.e. sequence[clarify sequence vs numbers] of the form: ?? . There is no simple formula
for this sequence unlike the previous one((01)^n). [ why? proof?]

Here is the table for that:

| Current State | Tape Head Content | Action | Next State |
| b | _(any) | P(e)-R-P(e)-R-P(0)-R-R-P(0)-L-L | o |
| o | 1 | R-P(x)-L-L-L | o |
| o | 0 | X | q |
| q | 0 or 1 | R-R | q |
| q | X(empty) | P(1)-L | p |
| p | x | P(X)-R | q |
| p | e | R | f |
| p | X(empty) | L-L | p |
| f | _(any) | R-R | f |
| f | X(empty) | P(0)-L-L | o |

Now verifying the output of such a big table by hand is going to be cumbersome.
How about we implementing a program to simulate this? The logic is simple: Depending on current state and current head content perform actions and change state. Keep repeating this for required number of steps and print the tape content in the end.

I implemented this logic in rust, since i've been trying to learn it recently:

<details>

<summary>
Full Code
</summary>

{% highlight rust linenos %}

use std::fmt;
use std::io;

// Internal states
#[derive(Debug, PartialEq, Eq)]
enum TapeMachineState {
    b,
    o,
    q,
    p,
    f,
}

// Allowed symbols
#[derive(Debug, PartialEq, Eq, Clone)]
enum TapeMachineSymbol {
    Symbol0,
    Symbol1,
    Symbole,
    Symbolx,
    SymbolX,
}

// For printing purposes
impl TapeMachineSymbol {
    fn as_str(&self) -> &'static str {
        match self {
            TapeMachineSymbol::Symbol0 => "0",
            TapeMachineSymbol::Symbol1 => "1",
            TapeMachineSymbol::Symbole => "e",
            TapeMachineSymbol::Symbolx => "x",
            TapeMachineSymbol::SymbolX => "X",
        }
    }
}

// Internal State + Tape + Head
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

    // Allowed Actions

    // Print
    fn p(&mut self, symbol: TapeMachineSymbol) {
        self.result[self.index] = symbol;
    }

    // Move right
    fn r(&mut self) {
        self.index += 1;
    }

    // Move left
    fn l(&mut self) {
        self.index -= 1;
    }
}

fn main() {
    println!("Enter the number of steps:");
    let mut steps_input = String::new();
    io::stdin().read_line(&mut steps_input).unwrap();
    let steps: usize = steps_input.trim().parse().unwrap();

    println!("Enter the total tape length:");
    let mut tape_length_input = String::new();
    io::stdin().read_line(&mut tape_length_input).unwrap();
    let max_len: usize = tape_length_input.trim().parse().unwrap();

    // Initialise tape machine
    let mut result = vec![TapeMachineSymbol::SymbolX; max_len];
    let mut tape_machine = TapeMachine::new(&TapeMachineState::b, &mut result);

    // Simulate for required number of steps
    for i in 0..steps {
        println!(
            "Step: {} State: {:?} Symbol: {:?}",
            i,
            tape_machine.state,
            tape_machine.result[tape_machine.index]
        );

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
            (
                TapeMachineState::q,
                TapeMachineSymbol::Symbol0 | TapeMachineSymbol::Symbol1,
            ) => {
                tape_machine.r();
                tape_machine.r();
                tape_machine.state = &TapeMachineState::q;
                println!("Final State: {:?}", TapeMachineState::q);
            }
            (TapeMachineState::q, TapeMachineSymbol::SymbolX) => {
                tape_machine.p(TapeMachineSymbol::Symbol1);
                tape_machine.l();
                tape_machine.state = &TapeMachineState::p;
                println!("Final State: {:?}", TapeMachineState::p);
            }
            (TapeMachineState::p, TapeMachineSymbol::Symbolx) => {
                tape_machine.p(TapeMachineSymbol::SymbolX);
                tape_machine.r();
                tape_machine.state = &TapeMachineState::q;
                println!("Final State: {:?}", TapeMachineState::q);
            }
            (TapeMachineState::p, TapeMachineSymbol::Symbole) => {
                tape_machine.r();
                tape_machine.state = &TapeMachineState::f;
                println!("Final State: {:?}", TapeMachineState::f);
            }
            (TapeMachineState::p, TapeMachineSymbol::SymbolX) => {
                tape_machine.l();
                tape_machine.l();
                tape_machine.state = &TapeMachineState::p;
                println!("Final State: {:?}", TapeMachineState::p);
            }
            (TapeMachineState::f, TapeMachineSymbol::SymbolX) => {
                tape_machine.p(TapeMachineSymbol::Symbol0);
                tape_machine.l();
                tape_machine.l();
                tape_machine.state = &TapeMachineState::o;
                println!("Final State: {:?}", TapeMachineState::o);
            }
            (TapeMachineState::b, _) => {
                tape_machine.p(TapeMachineSymbol::Symbole);
                tape_machine.r();
                tape_machine.p(TapeMachineSymbol::Symbole);
                tape_machine.r();
                tape_machine.p(TapeMachineSymbol::Symbol0);
                tape_machine.r();
                tape_machine.r();
                tape_machine.p(TapeMachineSymbol::Symbol0);
                tape_machine.l();
                tape_machine.l();
                tape_machine.state = &TapeMachineState::o;
                println!("Final State: {:?}", TapeMachineState::o);
            }
            (TapeMachineState::f, _) => {
                tape_machine.r();
                tape_machine.r();
                tape_machine.state = &TapeMachineState::f;
                println!("Final State: {:?}", TapeMachineState::f);
            }
            (_, _) => {
                println!(
                    "State: {:?} Index: {:?} Symbol: {:?}",
                    tape_machine.state,
                    tape_machine.index,
                    tape_machine.result[tape_machine.index]
                );
                let binary_result: String = tape_machine
                    .result
                    .iter()
                    .map(|x| x.as_str())
                    .collect();
                println!("{}", binary_result);
                panic!("Invalid state reached");
            }
        }
    }

    let binary_result: String = tape_machine.result.iter().map(|x| x.as_str()).collect();
    println!("{}", binary_result);
    let clean_result: String = tape_machine
        .result
        .iter()
        .filter(|&x| x != &TapeMachineSymbol::SymbolX)
        .map(|x| x.as_str())
        .collect();
    println!("=========\n");
    println!("{}", clean_result);
}
{% endhighlight %}

</details>

The crux of implementation is this loop:

{% highlight rust linenos %}

    for i in 0..steps {
        println!("Step: {} State: {:?} Symbol: {:?}",
            i, tape_machine.state, tape_machine.result[tape_machine.index]);

        // Depending on the current state and current tape head content
        match (tape_machine.state, &tape_machine.result[tape_machine.index]) {
            (TapeMachineState::o, TapeMachineSymbol::Symbol1) => {
                // Perform actions
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
            ...

{% endhighlight %}

If you run the above code, for 1 000 steps and tape length set to 10 000, then you will get following cleaned up content( after removing empty spaces)

```
e0010110111011110111110111111011111110111111110111111111
```

If we ignore the first `e` , we are actually on track to get this sequence.

<details>
<summary> Instructions to run the code</summary>

{% highlight bash %}
Assuming the code is saved in state_machine.rs

1. rustc state_machine.rs
2. ./state_machine
3. Enter the number of steps and tape length.
   As a rule of thumb, Tape length >= 10 \* Number of steps, but this obviously depends on the logic.

{% endhighlight %}

</details>

This is interesting. However, what if we want to test another state machine, i.e. one
with different states and rules. We will have to rewrite the code again, which is
a time taking process. The table description is pretty succinct. Can we generate
simulation code with minimal description of state machine?

[Rust Macros](link_here) can generate code by matching patterns. Can we use them to
generate the code for us? We do it in the next post.
