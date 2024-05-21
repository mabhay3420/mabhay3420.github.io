---
layout: post
title: State Machine Compiler - A Small Language
subtitle: Generating Rust code from minimal specification
cover-img: https://source.unsplash.com/featured/1920x1080/
thumbnail-img: https://source.unsplash.com/featured/1920x1080/
tags: []
comments: true
readtime: true
usemathjax: true
---

In this series of posts, we In this series of posts, we will create a very simple language that can
be used to specify a state machine. Then we will write a compiler that will
translate the description to a code that can simulate this state machine.

Here is theHere is the agenda:\
[Part 1](../2024-05-03-State-Machine-Compiler-Intro): What is a state machine? A (Rust) program to simulate state machine.\
[Part 2](../2024-05-05-state-machine-compiler-rust-macros): Writing (Rust) macros to reduce repetition\
[Part 3](../2024-05-07-state-machine-compiler-a-small-language): A small language and convert a description into a high level language(Rust) implementation\
Proposed Part 4: Translating the description into a lower level
assembly like language(LLVM IR)
sembly like language(LLVM IR)

This is part 3.


## Language
In the [previous post](../2024-05-05-state-machine-compiler-rust-macros), we decided to work
with a much concise specification of the state machine.

Here is a specification for the state machine which
will generate the sequence `001011011101111011111..`

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

Since this particular state machine is a little
complex, we will be using a much simple state machine
example, one that generates the sequence `010101..`:

```
STATES: [a], b

SYMBOLS: 0, 1

TRANSITIONS:
a, a, P(0), b
b, 0, R, a
b, 1, R, a
```

So the expectation is that we will be able to generate
the rust code for the above state machine:

{% highlight rust %}
use std::fmt;
use std::io;

// State declarations
#[derive(Debug, PartialEq, Eq)]
enum TapeMachineState {
    a,
    b,
}

// Symbol declarations, with `X` indicating a empty
// tape block
#[derive(Debug, PartialEq, Eq, Clone)]
enum TapeMachineSymbol {
    Symbol0,
    Symbol1,
    SymbolX,
}

// For printing the symbols
impl TapeMachineSymbol {
    fn as_str(&self) -> &'static str {
        match self {
            TapeMachineSymbol::Symbol0 => "0",
            TapeMachineSymbol::Symbol1 => "1",
            TapeMachineSymbol::SymbolX => "X",
        }
    }
}

// Tape machine constituents
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


    // Print
    fn p(&mut self, symbol: TapeMachineSymbol) {
        self.result[self.index] = symbol;
    }

    // Move the head to the right
    fn r(&mut self) {
        self.index += 1;
    }
    // Move the head to the left
    fn l(&mut self) {
        self.index -= 1;
    }
}

fn main() {

    // Take the number of steps and the length of the
    // tape as input
    println!("Enter the number of steps:");
    let mut steps_input = String::new();
    io::stdin().read_line(&mut steps_input).unwrap();
    let steps: usize = steps_input.trim().parse().unwrap();

    println!("Enter the total tape length:");
    let mut tape_length_input = String::new();
    io::stdin().read_line(&mut tape_length_input).unwrap();
    let max_len: usize = tape_length_input.trim().parse().unwrap();


    // Initialize the tape machine
    let mut result = vec![TapeMachineSymbol::SymbolX; max_len];
    let mut tape_machine = TapeMachine::new(&TapeMachineState::a, &mut result);

    // Run the simulation for the required number of
    // steps
    for i in 0..steps {
        println!(
            "Step: {} State: {:?} Symbol: {:?}",
            i, tape_machine.state, tape_machine.result[tape_machine.index]
        );

        // Actual simulation logic
        match (tape_machine.state, &tape_machine.result[tape_machine.index]) {
            (TapeMachineState::b, TapeMachineSymbol::Symbol0) => {
                tape_machine.r();
                tape_machine.p(TapeMachineSymbol::Symbol1);
                tape_machine.state = &TapeMachineState::b;
                println!("Final State: {:?}", TapeMachineState::b);
            }
            (TapeMachineState::b, TapeMachineSymbol::Symbol1) => {
                tape_machine.r();
                tape_machine.p(TapeMachineSymbol::Symbol0);
                tape_machine.state = &TapeMachineState::a;
                println!("Final State: {:?}", TapeMachineState::a);
            }
            (TapeMachineState::a, _) => {
                tape_machine.p(TapeMachineSymbol::Symbol0);
                tape_machine.state = &TapeMachineState::b;
                println!("Final State: {:?}", TapeMachineState::b);
            }
            (_, _) => {
                println!(
                    "State: {:?} Index: {:?} Symbol: {:?}",
                    tape_machine.state, tape_machine.index, tape_machine.result[tape_machine.index]
                );
                let binary_result: String =
                    tape_machine.result.iter().map(|x| x.as_str()).collect();
                println!("{}", binary_result);
                panic!("Invalid state reached");
            }
        }
    }


    // Print the tape content
    let binary_result: String = tape_machine.result.iter().map(|x| x.as_str()).collect();
    println!("{}", binary_result);

    // Print without the empty tape blocks
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

In order to generate this code directly from the
specification, we will need to parse the specification
into a data structure.

Here are few natural data structure to represent the
specification:

{% highlight rust %}

// A Trnasition condition can be either `*`
// or `A | B | C | ...`
pub enum Condition {
    OR(Vec<String>),
    Star,
}

// A transition step can be either `R`, `L`,
// `X`(erase the content) or `P(x)` ( print x to
// the current head)
#[derive(Debug, PartialEq, Clone)]
pub enum TransitionStep {
    R,
    L,
    X,
    P(String), // A function call
}


// A transition
#[derive(Debug, PartialEq, Clone)]
pub struct Transition {
    pub initial_state: String,
    pub condition: Condition,
    pub steps: Vec<TransitionStep>,
    pub final_state: String,
}


#[derive(Debug, PartialEq, Clone)]
pub struct ParseTree {
    pub states: Vec<String>,
    pub initial_state: String,
    pub symbols: Vec<String>,
    pub transitions: Vec<Transition>,
}

{% endhighlight %}

Once we have parsed the specification, generating
the rust code is just a matter of substituting the
right values in the template.

Parsing a text is typically broken into two steps:

1. Lexing: Breaking the text into tokens
2. Parsing: Grouping tokens into recognizable
structures

We will be following [this tutorial][link_here] closely.

## Lexing

A token is a value with a type. In our case,
we can expect the following types of tokens:

{% highlight rust %}

#[derive(Debug, PartialEq, Clone, Copy)]
pub enum TokenType {
    // Special
    EOF = -1,
    NEWLINE = 0,

    // Keywords
    STATES = 201,
    SYMBOLS = 202,
    TRANSITIONS = 203,
    // Contextual Keywords
    R = 104,
    L = 105,
    X = 106,
    P = 107,

    // Identifiers : Alphanumerics
    IDENT = 7,

    // Operators
    OR = 8,
    LeftBracket = 9,
    RightBracket = 10,
    COMMA = 11,
    DASH = 12,
    LeftParen = 13,
    RightParen = 14,
    STAR = 15,
    COLON = 16,
}

{% endhighlight %}

Lexer will simply go over the text separated by
whitespaces and return a token or thrown an error
in case of an invalid value.

As the [tutorial][link_here] suggests, let's first
outline the interfaces of the lexer:

{% highlight rust %}
#[derive(Debug, PartialEq, Clone)]
pub struct Token {
    pub text: String,
    pub kind: TokenType,
}

#[derive(Debug, PartialEq, Clone)]
pub struct Lexer {
    source: Vec<char>, // The full source code
    pub cur_char: char, // The current character
    cur_pos: usize, // The current position in
                    // the source
    }

impl Lexer {

    // Initialize the lexer
    pub fn new(source: &str) -> Self {}

    // Get the current character
    pub fn cur_char(&self) -> char {}

    // Move to the next character
    pub fn next_char(&mut self) {}

    // Peek at the next character, does not move
    pub fn peek(&self) -> char {}

    // Abort the lexer with an error message
    pub fn abort(&self, message: &str) {}

    // Skip whitespaces
    fn skip_whitespace(&mut self) {}

    // Skip comments
    fn skip_comment(&mut self) {}

    // Get the next token
    pub fn get_token(&mut self) -> Option<Token> {

        // Skip whitespaces
        // Skip comments

        // Match the operators first

        // If the current character is alphanumeric
        // then the following word can be an identifier
        // or a keyword

        // construct the whole word and check if it is
        // a keyword or an identifier


        // Throw an error if the current character if
        // not a valid token
    }
}

{% endhighlight %}

I've outlined the interfaces, since the implementation
is straightforward, we will not be going through it,
line by line.

<details>
<summary>Full Lexer Code</summary>

{% highlight rust %}
use log::{error, info};
use std::str::FromStr;

#[derive(Debug, PartialEq, Clone, Copy)]
pub enum TokenType {
    // Special
    EOF = -1,
    NEWLINE = 0,

    // Keywords
    STATES = 201,
    SYMBOLS = 202,
    TRANSITIONS = 203,
    // Contextual Keywords
    R = 104,
    L = 105,
    X = 106,
    P = 107,

    // Identifiers : Alphanumerics
    IDENT = 7,

    // Operators
    OR = 8,
    LeftBracket = 9,
    RightBracket = 10,
    COMMA = 11,
    DASH = 12,
    LeftParen = 13,
    RightParen = 14,
    STAR = 15,
    COLON = 16,
}

impl FromStr for TokenType {
    type Err = String;
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "EOF" => Ok(TokenType::EOF),
            "NEWLINE" => Ok(TokenType::NEWLINE),
            "STATES" => Ok(TokenType::STATES),
            "SYMBOLS" => Ok(TokenType::SYMBOLS),
            "TRANSITIONS" => Ok(TokenType::TRANSITIONS),
            "R" => Ok(TokenType::R),
            "L" => Ok(TokenType::L),
            "P" => Ok(TokenType::P),
            "X" => Ok(TokenType::X),
            "IDENT" => Ok(TokenType::IDENT),
            "OR" => Ok(TokenType::OR),
            "LEFT_BRACKET" => Ok(TokenType::LeftBracket),
            "RIGHT_BRACKET" => Ok(TokenType::RightBracket),
            "COMMA" => Ok(TokenType::COMMA),
            "DASH" => Ok(TokenType::DASH),
            "LEFT_PAREN" => Ok(TokenType::LeftParen),
            "RIGHT_PAREN" => Ok(TokenType::RightParen),
            "STAR" => Ok(TokenType::STAR),
            "COLON" => Ok(TokenType::COLON),
            _ => Err(format!("Unknown token type: {}", s)),
        }
    }
}

#[derive(Debug, PartialEq, Clone)]
pub struct Token {
    pub text: String,
    pub kind: TokenType,
}

impl Token {
    fn check_if_keyword(token_text: &str) -> Option<TokenType> {
        let token_type = TokenType::from_str(token_text);
        match token_type {
            Ok(t) => {
                if t as i32 > 100 {
                    Some(t)
                } else {
                    None
                }
            }
            Err(_s) => None,
        }
    }
}

#[derive(Debug, PartialEq, Clone)]
pub struct Lexer {
    source: Vec<char>,
    pub cur_char: char,
    cur_pos: usize,
}

impl Lexer {
    pub fn new(source: &str) -> Self {
        info!("Initializing Lexer");
        let mut source_chars = source.chars().collect::<Vec<_>>();
        source_chars.push('\n');

        let cur_char = if source_chars.len() > 1 {
            source_chars[0]
        } else {
            '\n'
        };

        Lexer {
            source: source_chars,
            cur_char,
            cur_pos: 0,
        }
    }

    pub fn cur_char(&self) -> char {
        self.source[self.cur_pos]
    }

    pub fn next_char(&mut self) {
        self.cur_pos += 1;
        if self.cur_pos >= self.source.len() {
            self.cur_char = '\0'; // EOF
        } else {
            self.cur_char = self.source[self.cur_pos];
        }
    }

    pub fn peek(&self) -> char {
        if self.cur_pos + 1 >= self.source.len() {
            '\0' // EOF
        } else {
            self.source[self.cur_pos + 1]
        }
    }

    pub fn abort(&self, message: &str) {
        error!("Lexical Error: {}", message);
        panic!("Lexical Error: {}", message);
    }

    fn skip_whitespace(&mut self) {
        while self.cur_char == ' ' || self.cur_char == '\t' || self.cur_char == '\r' {
            self.next_char();
        }
    }

    fn skip_comment(&mut self) {
        if self.cur_char == '#' {
            while self.cur_char != '\n' {
                self.next_char();
            }
        }
    }

    pub fn get_token(&mut self) -> Option<Token> {
        self.skip_whitespace();
        self.skip_comment();

        let token = match self.cur_char {
            '\n' => Some(Token {
                text: self.cur_char.to_string(),
                kind: TokenType::NEWLINE,
            }),
            '|' => Some(Token {
                text: self.cur_char.to_string(),
                kind: TokenType::OR,
            }),
            '[' => Some(Token {
                text: self.cur_char.to_string(),
                kind: TokenType::LeftBracket,
            }),
            ']' => Some(Token {
                text: self.cur_char.to_string(),
                kind: TokenType::RightBracket,
            }),
            ',' => Some(Token {
                text: self.cur_char.to_string(),
                kind: TokenType::COMMA,
            }),
            '-' => Some(Token {
                text: self.cur_char.to_string(),
                kind: TokenType::DASH,
            }),
            '(' => Some(Token {
                text: self.cur_char.to_string(),
                kind: TokenType::LeftParen,
            }),
            ')' => Some(Token {
                text: self.cur_char.to_string(),
                kind: TokenType::RightParen,
            }),
            '*' => Some(Token {
                text: self.cur_char.to_string(),
                kind: TokenType::STAR,
            }),
            ':' => Some(Token {
                text: self.cur_char.to_string(),
                kind: TokenType::COLON,
            }),
            '\0' => Some(Token {
                text: self.cur_char.to_string(),
                kind: TokenType::EOF,
            }),
            _ if self.cur_char.is_alphanumeric() => {
                let start_pos = self.cur_pos;
                while self.peek().is_alphanumeric() {
                    self.next_char();
                }
                let tok_text: String = self.source[start_pos..=self.cur_pos].iter().collect();
                match Token::check_if_keyword(&tok_text) {
                    Some(keyword) => Some(Token {
                        text: tok_text,
                        kind: keyword,
                    }),
                    None => Some(Token {
                        text: tok_text,
                        kind: TokenType::IDENT,
                    }),
                }
            }
            _ => {
                self.abort(&format!("Unknown token: {}", self.cur_char));
                None
            }
        };

        self.next_char();
        token
    }
}

{% endhighlight %}

</details>


To test the lexer, take a look at the following code:

<details>
<summary>A Sample Lexer Test Code</summary>

{% highlight rust %}
fn test_keywords_and_identifiers() {
    let code = "
        STATES: [A], B, C1
        SYMBOLS: [0 , 1, X, R]
        TRANSITIONS: [A, 0 | 1, L-R-P(X), B], [B, * , L , C1]
    ";
    let expected = vec![
        Token {
            text: "\n".to_string(),
            kind: TokenType::NEWLINE,
        },
        Token {
            text: "STATES".to_string(),
            kind: TokenType::STATES,
        },
        Token {
            text: ":".to_string(),
            kind: TokenType::COLON,
        },
        Token {
            text: "[".to_string(),
            kind: TokenType::LeftBracket,
        },
        Token {
            text: "A".to_string(),
            kind: TokenType::IDENT,
        },
        Token {
            text: "]".to_string(),
            kind: TokenType::RightBracket,
        },
        Token {
            text: ",".to_string(),
            kind: TokenType::COMMA,
        },
        Token {
            text: "B".to_string(),
            kind: TokenType::IDENT,
        },
        Token {
            text: ",".to_string(),
            kind: TokenType::COMMA,
        },
        Token {
            text: "C1".to_string(),
            kind: TokenType::IDENT,
        },
        Token {
            text: "\n".to_string(),
            kind: TokenType::NEWLINE,
        },
        Token {
            text: "SYMBOLS".to_string(),
            kind: TokenType::SYMBOLS,
        },
        Token {
            text: ":".to_string(),
            kind: TokenType::COLON,
        },
        Token {
            text: "[".to_string(),
            kind: TokenType::LeftBracket,
        },
        Token {
            text: "0".to_string(),
            kind: TokenType::IDENT,
        },
        Token {
            text: ",".to_string(),
            kind: TokenType::COMMA,
        },
        Token {
            text: "1".to_string(),
            kind: TokenType::IDENT,
        },
        Token {
            text: ",".to_string(),
            kind: TokenType::COMMA,
        },
        Token {
            text: "X".to_string(),
            kind: TokenType::X,
        },
        Token {
            text: ",".to_string(),
            kind: TokenType::COMMA,
        },
        Token {
            text: "R".to_string(),
            kind: TokenType::R,
        },
        Token {
            text: "]".to_string(),
            kind: TokenType::RightBracket,
        },
        Token {
            text: "\n".to_string(),
            kind: TokenType::NEWLINE,
        },
        Token {
            text: "TRANSITIONS".to_string(),
            kind: TokenType::TRANSITIONS,
        },
        Token {
            text: ":".to_string(),
            kind: TokenType::COLON,
        },
        Token {
            text: "[".to_string(),
            kind: TokenType::LeftBracket,
        },
        Token {
            text: "A".to_string(),
            kind: TokenType::IDENT,
        },
        Token {
            text: ",".to_string(),
            kind: TokenType::COMMA,
        },
        Token {
            text: "0".to_string(),
            kind: TokenType::IDENT,
        },
        Token {
            text: "|".to_string(),
            kind: TokenType::OR,
        },
        Token {
            text: "1".to_string(),
            kind: TokenType::IDENT,
        },
        Token {
            text: ",".to_string(),
            kind: TokenType::COMMA,
        },
        Token {
            text: "L".to_string(),
            kind: TokenType::L,
        },
        Token {
            text: "-".to_string(),
            kind: TokenType::DASH,
        },
        Token {
            text: "R".to_string(),
            kind: TokenType::R,
        },
        Token {
            text: "-".to_string(),
            kind: TokenType::DASH,
        },
        Token {
            text: "P".to_string(),
            kind: TokenType::P,
        },
        Token {
            text: "(".to_string(),
            kind: TokenType::LeftParen,
        },
        Token {
            text: "X".to_string(),
            kind: TokenType::X,
        },
        Token {
            text: ")".to_string(),
            kind: TokenType::RightParen,
        },
        Token {
            text: ",".to_string(),
            kind: TokenType::COMMA,
        },
        Token {
            text: "B".to_string(),
            kind: TokenType::IDENT,
        },
        Token {
            text: "]".to_string(),
            kind: TokenType::RightBracket,
        },
        Token {
            text: ",".to_string(),
            kind: TokenType::COMMA,
        },
        Token {
            text: "[".to_string(),
            kind: TokenType::LeftBracket,
        },
        Token {
            text: "B".to_string(),
            kind: TokenType::IDENT,
        },
        Token {
            text: ",".to_string(),
            kind: TokenType::COMMA,
        },
        Token {
            text: "*".to_string(),
            kind: TokenType::STAR,
        },
        Token {
            text: ",".to_string(),
            kind: TokenType::COMMA,
        },
        Token {
            text: "L".to_string(),
            kind: TokenType::L,
        },
        Token {
            text: ",".to_string(),
            kind: TokenType::COMMA,
        },
        Token {
            text: "C1".to_string(),
            kind: TokenType::IDENT,
        },
        Token {
            text: "]".to_string(),
            kind: TokenType::RightBracket,
        },
        Token {
            text: "\n".to_string(),
            kind: TokenType::NEWLINE,
        },
        Token {
            text: "\n".to_string(),
            kind: TokenType::NEWLINE,
        },
    ];
    let mut lexer = Lexer::new(code);
    let mut result = Vec::new();
    while let Some(token) = lexer.get_token() {
        if token.kind == TokenType::EOF {
            break;
        }
        result.push(token);
    }
    assert_eq!(result, expected);
}

{% endhighlight %}

</details>

To move on to the next step, we will need to
make sense of these series of tokens.

## Parsing

In order to parse we will follow this general approach:

1. Take a look at the current token
2. Based on the context, decide whether we expect
   it to be a certain type of token:
    a. The token type is required:
        i. Is this token present? Consume it and
        update the parse tree.
        ii. Otherwise, throw an error.
    b. Is this token type optional?
       i. Try to consume it.
       ii. If its not present, then move on.


How do we know which tokens type we expect at any
place?
A Grammer of our language will
help:

{% highlight rust %}
// A program is a series of declarations
PROGRAM= STATES_DECLARATION SYMBOLS_DECLARATION TRANSITIONS_DECLARATION

// A declaration of states is comma separated list of
// identifiers
STATES_DECLARATION: STATES ':' [STATES_IDENTIFIERS ','] '[' STATE_IDENTIFIERS ']'   [STATES_IDENTIFIERS] NEWLINE
STATE_IDENTIFIERS: STATE_IDENTIFIER (',' STATE_IDENTIFIER)*

// A declaration of symbols is comma separated list of
// identifiers
SYMBOLS_DECLARATION: SYMBOLS ':' '[' SYMBOL_IDENTIFIERS ']' NEWLINE
SYMBOL_IDENTIFIERS: SYMBOL_IDENTIFIER (',' SYMBOL_IDENTIFIER)*

// A declaration of transitions is comma separated
// list of transition declarations
TRANSITIONS_DECLARATION: TRANSITIONS ':' (NEWLINE TRANSITION_DECLARATION)*


// A transition declaration
TRANSITION_DECLARATION: INITIAL_STATE_IDENTIFIER ',' TRANSITION_CONDITIONS ',' TRANSITION_STEPS, FINAL_STATE_IDENTIFIER
TRANSITION_CONDITIONS: STAR | SYMBOL_IDENTIFIER ( '|' SYMBOL_IDENTIFIER )*
TRANSITION_STEPS: None | TRANSITION_STEP ('-' TRANSITION_STEP)*
TRANSITION_STEP: R | L | P '(' SYMBOL_IDENTIFIER ')'

STATE_IDENTIFIER: IDENTIFIER
SYMBOL_IDENTIFIER: IDENTIFIER

{% endhighlight %}

The above grammer, recursively defines what a valid
program is. It starts with a `PROGRAM` which is a
series of declarations and then goes on to define
what different declarations are.

This grammer says that we expect `SYMBOLS_DECLARATION` to come after `STATES_DECLARATION`.

In our parsing logic, at any stage, we will be
expecting a series of tokens as specified by the
grammer.
For example the top level logic will be following:

{% highlight rust %}
    // Parse the entire program:
    // NEWLINE? states_declaration symbols_declaration transitions_declaration NEWLINE? EOF
    pub fn program(&mut self) {
        // Consume newlines
        while self.try_consume(TokenType::NEWLINE, None::<fn(&Token)>) {}
        // Parse the states declaration
        self.states_declaration();

        // Parse the symbols declaration
        self.symbols_declaration();

        // Parse the transitions declaration
        self.transitions_declaration();

        // Consume newlines
        while self.try_consume(TokenType::NEWLINE, None::<fn(&Token)>) {}

        // Expect the end of the file
        self.consume(TokenType::EOF, None::<fn(&Token)>);
        debug!("PROGRAM");
    }

{% endhighlight %}

The `states_declaration` will be defined as follows:

{% highlight rust %}
    // Parse a states declaration: STATES ':' state_identifier_list NEWLINE
    fn states_declaration(&mut self) {
        self.consume(TokenType::STATES, None::<fn(&Token)>);
        self.consume(TokenType::COLON, None::<fn(&Token)>);
        self.state_identifier_list();
        self.consume(TokenType::NEWLINE, None::<fn(&Token)>);
        debug!("STATES_DECLARATION");
    }

{% endhighlight %}

Let's focus on the `consume` function:

{% highlight rust %}
    // Consume the current token if it matches the expected token type
    // If not, abort with an error message
    // Execute the optional action if provided
    fn consume<F>(&mut self, expected: TokenType, action: Option<F>)
{% endhighlight %}

There is another variant of `consume` which is `try_consume`:

{% highlight rust %}
    // Try to consume the current token if it matches the expected token type
    // If successful, print the token type and text (if available) and execute the optional action
    // Return true if the token was consumed, false otherwise
    fn try_consume<F>(&mut self, kind: TokenType, action: Option<F>) -> bool

{% endhighlight %}

Let's look at what an `action` might look like, in case we happen to be
matching a initial state identifier:

{% highlight rust %}
    // Parse an initial state identifier: [IDENT]
    fn initial_state_identifier(&mut self) {
        self.consume(TokenType::LeftBracket, None::<fn(&Token)>);
        let mut initial_state = String::new();
        self.consume(
            TokenType::IDENT,

            // action: Push the text of the token to the initial state
            Some(|token: &Token| {
                initial_state.push_str(&token.text);
            }),
        );
        if self.tree.initial_state.is_empty() {

            // Action result: Set the initial state and
            // push the state to the states list
            self.tree.initial_state = initial_state.clone();
            self.tree.states.push(initial_state);
        } else {
            self.abort("Initial state already defined.");
        }
        self.consume(TokenType::RightBracket, None::<fn(&Token)>);
        debug!("INITIAL_STATE_IDENTIFIER");
    }

{% endhighlight %}

An example where we are using `try_consume`:

{% highlight rust %}
    fn transition_steps(&mut self) {
        self.transition_step();
        // There might or might not be a dash, if there is a dash
        // then we expect another transition step
        while self.try_consume(TokenType::DASH, None::<fn(&Token)>) {
            self.transition_step();
        }
        debug!("TRANSITION_STEPS");
    }
{% endhighlight %}

To summarise, let's right down the interfaces of parser:

{% highlight rust %}
impl Parser {
    pub fn new(lexer: Lexer) -> Self {
        // Initialize the Parser
    }

    // Check if the current token matches the expected token type
    fn check_token(&self, kind: TokenType) -> bool;

    // Check if the next token has the expected token type
    fn check_peek(&self, kind: TokenType) -> bool;

    // Advance to the next token
    fn next_token(&mut self);

    // Abort the parsing process with an error message
    fn abort(&self, message: &str);

    // Try to consume the current token if it matches the expected token type
    // If successful, print the token type and text (if available) and execute the optional action
    // Return true if the token was consumed, false otherwise
    fn try_consume<F>(&mut self, kind: TokenType, action: Option<F>) -> bool
    where
        F: FnMut(&Token);

    // Consume the current token if it matches the expected token type
    // If not, abort with an error message
    // Execute the optional action if provided
    fn consume<F>(&mut self, expected: TokenType, action: Option<F>)
    where
        F: FnMut(&Token);

    // Parse an initial state identifier: [IDENT]
    fn initial_state_identifier(&mut self);

    // Parse a list of state identifiers: IDENT (',' IDENT)*
    fn state_identifier_list(&mut self);

    // Parse a states declaration: STATES ':' state_identifier_list NEWLINE
    fn states_declaration(&mut self);

    // Parse a list of symbol identifiers: IDENT (',' IDENT)*
    fn symbol_identifiers(&mut self);

    // Parse a symbols declaration: SYMBOLS ':' symbol_identifiers NEWLINE
    fn symbols_declaration(&mut self);

    // Parse a transition step: R | L | P '(' IDENT ')' | X
    fn transition_step(&mut self);

    fn transition_steps(&mut self);

    // Parse a list of transition conditions: IDENT ('|' IDENT)*
    fn transition_condition_list(&mut self);

    // Parse transition conditions: '*' | transition_condition_list
    fn transition_conditions(&mut self);

    // Parse a transition declaration:
    // IDENT ',' transition_conditions ',' transition_steps ',' IDENT
    fn transition_declaration(&mut self);

    // Parse transitions declarations:
    // TRANSITIONS ':' (NEWLINE transition_declaration)*
    fn transitions_declaration(&mut self);

    // Parse the entire program:
    // NEWLINE? states_declaration symbols_declaration transitions_declaration NEWLINE? EOF
    pub fn program(&mut self);
}

{% endhighlight %}

Each of the functions, trying to parse a certain rule, when successful, will
update the `ParseTree` with the parsed data, otherwise throw an error.

<details>
<summary>Full Parser Code</summary>

{% highlight rust %}
use crate::lexer::{Lexer, Token, TokenType};
use log::{debug, error, info};

#[derive(Debug, PartialEq, Clone)]
pub enum Condition {
    OR(Vec<String>),
    Star,
}

#[derive(Debug, PartialEq, Clone)]
pub enum TransitionStep {
    R,
    L,
    X,
    P(String), // A function call
}

trait FromTokenAndValue {
    fn from_token_and_value(token: &Token, value: Option<String>) -> Self;
}

impl FromTokenAndValue for TransitionStep {
    fn from_token_and_value(token: &Token, value: Option<String>) -> Self {
        match token.kind {
            TokenType::R => TransitionStep::R,
            TokenType::L => TransitionStep::L,
            TokenType::X => TransitionStep::X,
            TokenType::P => TransitionStep::P(value.unwrap()),
            _ => panic!("Invalid token type for TransitionStep"),
        }
    }
}

#[derive(Debug, PartialEq, Clone)]
pub struct Transition {
    pub initial_state: String,
    pub condition: Condition,
    pub steps: Vec<TransitionStep>,
    pub final_state: String,
}

impl Transition {
    pub fn new() -> Self {
        Transition {
            initial_state: String::new(),
            condition: Condition::OR(Vec::new()),
            steps: Vec::new(),
            final_state: String::new(),
        }
    }
}

#[derive(Debug, PartialEq, Clone)]
pub struct ParseTree {
    pub states: Vec<String>,
    pub initial_state: String,
    pub symbols: Vec<String>,
    pub transitions: Vec<Transition>,
}


#[derive(Debug, PartialEq, Clone)]
pub struct Parser {
    lexer: Lexer,
    cur_token: Token,
    peek_token: Token,
    pub tree: ParseTree,
}

impl Parser {
    pub fn new(lexer: Lexer) -> Self {
        info!("Initializing Parser");
        let mut parser = Parser {
            lexer,
            cur_token: Token {
                text: "\0".to_string(),
                kind: TokenType::EOF,
            },
            peek_token: Token {
                text: "\0".to_string(),
                kind: TokenType::EOF,
            },
            tree: ParseTree {
                states: Vec::new(),
                initial_state: "".to_string(),
                symbols: Vec::new(),
                transitions: Vec::new(),
            },
        };
        parser.next_token(); // Initialize peek_token
        parser.next_token(); // Initialize cur_token
        parser
    }

    // Check if the current token matches the expected token type
    fn check_token(&self, kind: TokenType) -> bool {
        self.cur_token.kind == kind
    }

    // Check if the next token has the expected token type
    fn check_peek(&self, kind: TokenType) -> bool {
        self.peek_token.kind == kind
    }

    // Advance to the next token
    fn next_token(&mut self) {
        self.cur_token = self.peek_token.clone();
        self.peek_token = self.lexer.get_token().unwrap_or(Token {
            text: "\0".to_string(),
            kind: TokenType::EOF,
        });

        // If both current and peek token are newline, skip the newline
        if self.check_token(TokenType::NEWLINE) && self.check_peek(TokenType::NEWLINE) {
            self.next_token();
        }
    }

    // Abort the parsing process with an error message
    fn abort(&self, message: &str) {
        error!("Parsing error: {}", message);
        panic!("Parsing error: {}", message);
    }

    // Try to consume the current token if it matches the expected token type
    // If successful, print the token type and text (if available) and execute the optional action
    // Return true if the token was consumed, false otherwise
    fn try_consume<F>(&mut self, kind: TokenType, action: Option<F>) -> bool
    where
        F: FnMut(&Token),
    {
        if self.check_token(kind) {
            match kind {
                TokenType::IDENT => debug!("{:?}: {}", kind, self.cur_token.text),
                _ => debug!("{:?}", kind),
            }

            if let Some(mut action) = action {
                action(&self.cur_token);
            }

            self.next_token();
            true
        } else {
            false
        }
    }

    // Consume the current token if it matches the expected token type
    // If not, abort with an error message
    // Execute the optional action if provided
    fn consume<F>(&mut self, expected: TokenType, action: Option<F>)
    where
        F: FnMut(&Token),
    {
        if !self.try_consume(expected, action) {
            self.abort(&format!(
                "Expected {:?}, got {:?}",
                expected, self.cur_token.kind
            ));
        }
    }

    // Parse an initial state identifier: [IDENT]
    fn initial_state_identifier(&mut self) {
        self.consume(TokenType::LeftBracket, None::<fn(&Token)>);
        let mut initial_state = String::new();
        self.consume(
            TokenType::IDENT,
            Some(|token: &Token| {
                initial_state.push_str(&token.text);
            }),
        );
        if self.tree.initial_state.is_empty() {
            self.tree.initial_state = initial_state.clone();
            self.tree.states.push(initial_state);
        } else {
            self.abort("Initial state already defined.");
        }
        self.consume(TokenType::RightBracket, None::<fn(&Token)>);
        debug!("INITIAL_STATE_IDENTIFIER");
    }

    // Parse a list of state identifiers: IDENT (',' IDENT)*
    fn state_identifier_list(&mut self) {
        let mut state_identifiers = Vec::new();

        // Consume all tokens
        while self.check_token(TokenType::IDENT) || self.check_token(TokenType::LeftBracket) {
            if self.check_token(TokenType::LeftBracket) {
                self.initial_state_identifier();
            } else if !self.try_consume(
                TokenType::IDENT,
                Some(|token: &Token| {
                    state_identifiers.push(token.text.clone());
                }),
            ) {
                break;
            }
            if !self.try_consume(TokenType::COMMA, None::<fn(&Token)>) {
                debug!("STATE_IDENTIFIER_LIST");
                break;
            }
        }

        if self.tree.initial_state.is_empty() {
            self.abort("Initial state not defined.");
        }

        // If state identifiers have duplicates, abort with an error message
        state_identifiers.iter().for_each(|state_identifier| {
            if self.tree.states.contains(state_identifier) {
                self.abort(&format!("State {} already defined.", state_identifier));
            } else {
                self.tree.states.push(state_identifier.clone());
            }
        });
    }

    // Parse a states declaration: STATES ':' state_identifier_list NEWLINE
    fn states_declaration(&mut self) {
        self.consume(TokenType::STATES, None::<fn(&Token)>);
        self.consume(TokenType::COLON, None::<fn(&Token)>);
        self.state_identifier_list();
        self.consume(TokenType::NEWLINE, None::<fn(&Token)>);
        debug!("STATES_DECLARATION");
    }

    // Parse a list of symbol identifiers: IDENT (',' IDENT)*
    fn symbol_identifiers(&mut self) {
        let mut symbol_identifiers = Vec::new();

        self.consume(
            TokenType::IDENT,
            Some(|token: &Token| {
                symbol_identifiers.push(token.text.clone());
            }),
        );

        while self.try_consume(TokenType::COMMA, None::<fn(&Token)>) {
            self.consume(
                TokenType::IDENT,
                Some(|token: &Token| {
                    symbol_identifiers.push(token.text.clone());
                }),
            );
        }
        symbol_identifiers.iter().for_each(|symbol_identifier| {
            if self.tree.symbols.contains(symbol_identifier) {
                self.abort(&format!("Symbol {} already defined.", symbol_identifier));
            } else {
                self.tree.symbols.push(symbol_identifier.clone());
            }
        });

        // X is a special symbol
        self.tree.symbols.push("X".to_string());
        debug!("SYMBOL_IDENTIFIERS");
    }

    // Parse a symbols declaration: SYMBOLS ':' symbol_identifiers NEWLINE
    fn symbols_declaration(&mut self) {
        self.consume(TokenType::SYMBOLS, None::<fn(&Token)>);
        self.consume(TokenType::COLON, None::<fn(&Token)>);
        self.symbol_identifiers();
        self.consume(TokenType::NEWLINE, None::<fn(&Token)>);
        debug!("SYMBOLS_DECLARATION");
    }

    // Parse a transition step: R | L | P '(' IDENT ')' | X
    fn transition_step(&mut self) {
        // By default, do nothing
        let mut step: TransitionStep = TransitionStep::X;
        if self.try_consume(
            TokenType::R,
            Some(|token: &Token| {
                step = FromTokenAndValue::from_token_and_value(&token.clone(), None);
            }),
        ) {
        } else if self.try_consume(
            TokenType::L,
            Some(|token: &Token| {
                step = FromTokenAndValue::from_token_and_value(&token.clone(), None);
            }),
        ) {
        } else if self.try_consume(
            TokenType::X,
            Some(|token: &Token| {
                step = FromTokenAndValue::from_token_and_value(&token.clone(), None);
            }),
        ) {
        } else if self.try_consume(TokenType::P, None::<fn(&Token)>) {
            self.consume(TokenType::LeftParen, None::<fn(&Token)>);
            let mut print_string = String::new();
            // Either X or a symbol identifier
            if self.try_consume(
                TokenType::X,
                Some(|token: &Token| {
                    print_string.push_str(&token.text);
                }),
            ) {
            } else {
                self.consume(
                    TokenType::IDENT,
                    Some(|step: &Token| {
                        print_string.push_str(&step.text);
                    }),
                )
            };

            if !self.tree.symbols.contains(&print_string) {
                self.abort(&format!(
                    "Symbol {} not defined, So cannot be printed.",
                    print_string
                ));
            }
            step = FromTokenAndValue::from_token_and_value(
                &Token {
                    text: "P".to_string(),
                    kind: TokenType::P,
                },
                Some(print_string),
            );

            self.consume(TokenType::RightParen, None::<fn(&Token)>);
        } else {
            self.abort(&format!(
                "Expected {:?} or {:?} or {:?} or {:?} as an action step, got {:?}: {:?}",
                TokenType::R,
                TokenType::L,
                TokenType::P,
                TokenType::X,
                self.cur_token.kind,
                self.cur_token.text
            ));
        }
        self.tree.transitions.last_mut().unwrap().steps.push(step);
    }

    fn transition_steps(&mut self) {
        self.transition_step();
        while self.try_consume(TokenType::DASH, None::<fn(&Token)>) {
            self.transition_step();
        }
        debug!("TRANSITION_STEPS");
    }

    // Parse a list of transition conditions: IDENT ('|' IDENT)*
    fn transition_condition_list(&mut self) {
        let mut conditions: Vec<String> = Vec::new();

        // Consume X as well
        if self.try_consume(
            TokenType::X,
            Some(|token: &Token| {
                conditions.push(token.text.clone());
            }),
        ) {
        } else {
            self.consume(
                TokenType::IDENT,
                Some(|token: &Token| {
                    conditions.push(token.text.clone());
                }),
            );
        }

        while self.try_consume(TokenType::OR, None::<fn(&Token)>) {
            // Consume X as well
            if self.try_consume(
                TokenType::X,
                Some(|token: &Token| {
                    conditions.push(token.text.clone());
                }),
            ) {
            } else {
                self.consume(
                    TokenType::IDENT,
                    Some(|token: &Token| {
                        conditions.push(token.text.clone());
                    }),
                );
            }
        }
        self.tree.transitions.last_mut().unwrap().condition = Condition::OR(conditions);
        debug!("TRANSITION_CONDITION_LIST");
    }

    // Parse transition conditions: '*' | transition_condition_list
    fn transition_conditions(&mut self) {
        let mut star_condition = false;
        if !self.try_consume(
            TokenType::STAR,
            Some(|_token: &Token| {
                star_condition = true;
            }),
        ) {
            self.transition_condition_list();
        }

        // Override all other conditions with the star condition
        if star_condition {
            self.tree.transitions.last_mut().unwrap().condition = Condition::Star;
        }
        debug!("TRANSITION_CONDITIONS");
    }

    // Parse a transition declaration:
    // IDENT ',' transition_conditions ',' transition_steps ',' IDENT
    fn transition_declaration(&mut self) {
        // Initialize a new transition
        self.tree.transitions.push(Transition::new());

        // Initial state
        let mut initial_state = String::new();
        self.consume(
            TokenType::IDENT,
            Some(|token: &Token| {
                initial_state.push_str(&token.text);
            }),
        );
        self.tree.transitions.last_mut().unwrap().initial_state = initial_state;

        debug!("INITIAL_STATE_IDENTIFIER");
        self.consume(TokenType::COMMA, None::<fn(&Token)>);

        // Conditions
        self.transition_conditions();
        self.consume(TokenType::COMMA, None::<fn(&Token)>);

        // Actions
        self.transition_steps();
        self.consume(TokenType::COMMA, None::<fn(&Token)>);

        // Final state
        let mut final_state = String::new();
        self.consume(
            TokenType::IDENT,
            Some(|token: &Token| {
                final_state.push_str(&token.text);
            }),
        );
        self.tree.transitions.last_mut().unwrap().final_state = final_state;
        debug!("FINAL_STATE_IDENTIFIER");
        debug!("TRANSITION_DECLARATION");
    }

    // Parse transitions declarations:
    // TRANSITIONS ':' (NEWLINE transition_declaration)*
    fn transitions_declaration(&mut self) {
        self.consume(TokenType::TRANSITIONS, None::<fn(&Token)>);
        self.consume(TokenType::COLON, None::<fn(&Token)>);

        while self.try_consume(TokenType::NEWLINE, None::<fn(&Token)>) {
            if self.check_token(TokenType::EOF) {
                break;
            }
            self.transition_declaration();
        }
        debug!("TRANSITION_DECLARATIONS");
    }

    // Parse the entire program:
    // NEWLINE? states_declaration symbols_declaration transitions_declaration NEWLINE? EOF
    pub fn program(&mut self) {
        // Consume newlines
        while self.try_consume(TokenType::NEWLINE, None::<fn(&Token)>) {}
        self.states_declaration();
        self.symbols_declaration();
        self.transitions_declaration();
        // Consume newlines
        while self.try_consume(TokenType::NEWLINE, None::<fn(&Token)>) {}
        self.consume(TokenType::EOF, None::<fn(&Token)>);
        debug!("PROGRAM");
    }
}

{% endhighlight %}

</details>

## Generating Rust code

Once we have parsed the specification, generating the rust code is just a matter of substituting the right values in the template.

Let's take a look at the template:

{% highlight rust %}
use std::fmt;
use std::io;

#[derive(Debug, PartialEq, Eq)]
enum TapeMachineState {
    // FILL IN THE STATES FROM THE PARSE TREE
}

#[derive(Debug, PartialEq, Eq, Clone)]
enum TapeMachineSymbol {
    // FILL IN THE SYMBOLS FROM THE PARSE TREE
}

impl TapeMachineSymbol {
    fn as_str(&self) -> &'static str {
        match self {
            // FILL IN THE MATCH ARMS FOR EACH SYMBOL
        }
    }
}

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

fn main() {
    println!("Enter the number of steps:");
    let mut steps_input = String::new();
    io::stdin().read_line(&mut steps_input).unwrap();
    let steps: usize = steps_input.trim().parse().unwrap();

    println!("Enter the total tape length:");
    let mut tape_length_input = String::new();
    io::stdin().read_line(&mut tape_length_input).unwrap();
    let max_len: usize = tape_length_input.trim().parse().unwrap();

    let mut result = vec![TapeMachineSymbol::SymbolX; max_len];
    let mut tape_machine = TapeMachine::new(&TapeMachineState::/* FILL IN THE INITIAL STATE */, &mut result);

    for i in 0..steps {
        println!("Step: {} State: {:?} Symbol: {:?}",
            i, tape_machine.state, tape_machine.result[tape_machine.index]);

        match (tape_machine.state, &tape_machine.result[tape_machine.index]) {
            // FILL IN THE MATCH ARMS FOR EACH TRANSITION
            (_, _) => {
                println!("State: {:?} Index: {:?} Symbol: {:?}", tape_machine.state, tape_machine.index, tape_machine.result[tape_machine.index]);
                let binary_result: String = tape_machine.result.iter().map(|x| x.as_str()).collect();
                println!("{}", binary_result);
                panic!("Invalid state reached");
            }
        }
    }

    let binary_result: String = tape_machine.result.iter().map(|x| x.as_str()).collect();
    println!("{}", binary_result);
    let clean_result: String = tape_machine.result.iter().filter(|&x| x != &TapeMachineSymbol::SymbolX).map(|x| x.as_str()).collect();
    println!("=========\n");
    println!("{}", clean_result);
}

{% endhighlight %}

The code to do this is pretty straightforward, take a look below:

<details>
<summary>Full Rust Code Generator</summary>

{% highlight rust %}

impl ParseTree {
    pub fn to_rust_code(&self) -> String {
        let mut code = String::new();

        // Generate the TapeMachineState enum
        code.push_str(
            "use std::fmt;\nuse std::io;\n\n#[derive(Debug, PartialEq, Eq)]\nenum TapeMachineState {\n",
        );
        for state in &self.states {
            code.push_str(&format!("    {},\n", state));
        }
        code.push_str("}\n\n");

        // Generate the TapeMachineSymbol enum
        code.push_str("#[derive(Debug, PartialEq, Eq, Clone)]\nenum TapeMachineSymbol {\n");
        for symbol in &self.symbols {
            code.push_str(&format!("    Symbol{},\n", symbol));
        }
        code.push_str("}\n\n");

        // Generate the TapeMachineSymbol implementation
        code.push_str("impl TapeMachineSymbol {\n");
        code.push_str("    fn as_str(&self) -> &'static str {\n");
        code.push_str("        match self {\n");
        code.push_str(
            &self
                .symbols
                .iter()
                .map(|symbol| {
                    format!(
                        "            TapeMachineSymbol::Symbol{} => \"{}\"",
                        symbol, symbol
                    )
                })
                .collect::<Vec<String>>()
                .join(",\n"),
        );
        code.push_str("\n        }\n");
        code.push_str("    }\n");
        code.push_str("}\n\n");

        // Generate the TapeMachine struct
        code.push_str("struct TapeMachine<'a> {\n    state: &'a TapeMachineState,\n    result: &'a mut Vec<TapeMachineSymbol>,\n    index: usize,\n}\n\n");

        // Generate the TapeMachine implementation
        code.push_str("impl<'a> TapeMachine<'a> {\n");
        code.push_str("    pub fn new(state: &'a TapeMachineState, result: &'a mut Vec<TapeMachineSymbol>) -> Self {\n");
        code.push_str("        Self {\n");
        code.push_str("            state,\n");
        code.push_str("            result,\n");
        code.push_str("            index: 0,\n");
        code.push_str("        }\n");
        code.push_str("    }\n\n");

        code.push_str("    fn p(&mut self, symbol: TapeMachineSymbol) {\n");
        code.push_str("        self.result[self.index] = symbol;\n");
        code.push_str("    }\n\n");

        code.push_str("    fn r(&mut self) {\n");
        code.push_str("        self.index += 1;\n");
        code.push_str("    }\n\n");

        code.push_str("    fn l(&mut self) {\n");
        code.push_str("        self.index -= 1;\n");
        code.push_str("    }\n");

        code.push_str("}\n\n");

        // Generate the main function
        code.push_str("fn main() {\n");
        code.push_str("    println!(\"Enter the number of steps:\");\n");
        code.push_str("    let mut steps_input = String::new();\n");
        code.push_str("    io::stdin().read_line(&mut steps_input).unwrap();\n");
        code.push_str("    let steps: usize = steps_input.trim().parse().unwrap();\n\n");

        code.push_str("    println!(\"Enter the total tape length:\");\n");
        code.push_str("    let mut tape_length_input = String::new();\n");
        code.push_str("    io::stdin().read_line(&mut tape_length_input).unwrap();\n");
        code.push_str("    let max_len: usize = tape_length_input.trim().parse().unwrap();\n\n");
        code.push_str("    let mut result = vec![TapeMachineSymbol::SymbolX; max_len];\n");
        code.push_str(&format!(
            "    let mut tape_machine = TapeMachine::new(&TapeMachineState::{}, &mut result);\n\n",
            self.initial_state
        ));

        code.push_str("    for i in 0..steps {\n");
        code.push_str("        println!(\"Step: {} State: {:?} Symbol: {:?}\",\n");
        code.push_str(
            "            i, tape_machine.state, tape_machine.result[tape_machine.index]);\n\n",
        );

        code.push_str(
            "        match (tape_machine.state, &tape_machine.result[tape_machine.index]) {\n",
        );

        // Sort transitions so that the ones with star condition are executed last
        // This is to ensure compatibility with switch statements
        let mut sorted_transitions = self.transitions.clone();
        sorted_transitions.sort_by(|a, b| {
            if a.condition == Condition::Star {
                std::cmp::Ordering::Greater
            } else if b.condition == Condition::Star {
                std::cmp::Ordering::Less
            } else {
                std::cmp::Ordering::Equal
            }
        });
        for transition in sorted_transitions {
            let condition = match &transition.condition {
                Condition::OR(symbols) => {
                    let mut condition_str = String::new();
                    for (i, symbol) in symbols.iter().enumerate() {
                        condition_str.push_str(&format!("TapeMachineSymbol::Symbol{}", symbol));
                        if i < symbols.len() - 1 {
                            condition_str.push_str(" | ");
                        }
                    }
                    condition_str
                }
                Condition::Star => "_".to_string(),
            };

            code.push_str(&format!(
                "            (TapeMachineState::{}, {}) => ",
                transition.initial_state, condition
            ));
            code.push_str("{\n");

            for step in &transition.steps {
                match step {
                    TransitionStep::R => code.push_str("                tape_machine.r();\n"),
                    TransitionStep::L => code.push_str("                tape_machine.l();\n"),
                    TransitionStep::X => {
                        code.push_str("                // X means do nothing\n");
                    }
                    TransitionStep::P(symbol) => {
                        code.push_str(&format!(
                            "                tape_machine.p(TapeMachineSymbol::Symbol{});\n",
                            symbol
                        ));
                    }
                }
            }

            code.push_str(&format!(
                "                tape_machine.state = &TapeMachineState::{};\n",
                transition.final_state
            ));
            code.push_str(&format!(
                "                println!(\"Final State: {{:?}}\", TapeMachineState::{});\n",
                transition.final_state
            ));
            code.push_str("            }\n");
        }

        code.push_str("            (_, _) => {\n");
        code.push_str("                println!(\"State: {:?} Index: {:?} Symbol: {:?}\", tape_machine.state, tape_machine.index, tape_machine.result[tape_machine.index]);\n");
        code.push_str("                let binary_result: String = tape_machine.result.iter().map(|x| x.as_str()).collect();\n");
        code.push_str("                println!(\"{}\", binary_result);\n");
        code.push_str("                panic!(\"Invalid state reached\");\n");
        code.push_str("            }\n");
        code.push_str("        }\n");
        code.push_str("    }\n\n");

        code.push_str("    let binary_result: String = tape_machine.result.iter().map(|x| x.as_str()).collect();\n");
        code.push_str("    println!(\"{}\", binary_result);\n");
        code.push_str("    let clean_result: String = tape_machine.result.iter().filter( |&x| x != &TapeMachineSymbol::SymbolX).map(|x| x.as_str()).collect();\n");
        code.push_str("    println!(\"=========\\n\");\n");
        code.push_str("    println!(\"{}\", clean_result);\n");
        code.push_str("}\n");

        code
    }
}

{% endhighlight %}

</details>

This completes our implementation end to end. Take a look at the full code, for
few extra bells and whistles, like generating the dot file for the state machine
etc.

<details>
<summary>Full Rust Code</summary>

{% highlight rust linenos %}
use crate::lexer::{Lexer, Token, TokenType};
use log::{debug, error, info};

#[derive(Debug, PartialEq, Clone)]
pub enum Condition {
    OR(Vec<String>),
    Star,
}

#[derive(Debug, PartialEq, Clone)]
pub enum TransitionStep {
    R,
    L,
    X,
    P(String), // A function call
}

trait FromTokenAndValue {
    fn from_token_and_value(token: &Token, value: Option<String>) -> Self;
}

impl FromTokenAndValue for TransitionStep {
    fn from_token_and_value(token: &Token, value: Option<String>) -> Self {
        match token.kind {
            TokenType::R => TransitionStep::R,
            TokenType::L => TransitionStep::L,
            TokenType::X => TransitionStep::X,
            TokenType::P => TransitionStep::P(value.unwrap()),
            _ => panic!("Invalid token type for TransitionStep"),
        }
    }
}

#[derive(Debug, PartialEq, Clone)]
pub struct Transition {
    pub initial_state: String,
    pub condition: Condition,
    pub steps: Vec<TransitionStep>,
    pub final_state: String,
}

impl Transition {
    pub fn new() -> Self {
        Transition {
            initial_state: String::new(),
            condition: Condition::OR(Vec::new()),
            steps: Vec::new(),
            final_state: String::new(),
        }
    }
}

#[derive(Debug, PartialEq, Clone)]
pub struct ParseTree {
    pub states: Vec<String>,
    pub initial_state: String,
    pub symbols: Vec<String>,
    pub transitions: Vec<Transition>,
}

impl ParseTree {
    pub fn to_rust_code(&self) -> String {
        let mut code = String::new();

        // Generate the TapeMachineState enum
        code.push_str(
            "use std::fmt;\nuse std::io;\n\n#[derive(Debug, PartialEq, Eq)]\nenum TapeMachineState {\n",
        );
        for state in &self.states {
            code.push_str(&format!("    {},\n", state));
        }
        code.push_str("}\n\n");

        // Generate the TapeMachineSymbol enum
        code.push_str("#[derive(Debug, PartialEq, Eq, Clone)]\nenum TapeMachineSymbol {\n");
        for symbol in &self.symbols {
            code.push_str(&format!("    Symbol{},\n", symbol));
        }
        code.push_str("}\n\n");

        // Generate the TapeMachineSymbol implementation
        code.push_str("impl TapeMachineSymbol {\n");
        code.push_str("    fn as_str(&self) -> &'static str {\n");
        code.push_str("        match self {\n");
        code.push_str(
            &self
                .symbols
                .iter()
                .map(|symbol| {
                    format!(
                        "            TapeMachineSymbol::Symbol{} => \"{}\"",
                        symbol, symbol
                    )
                })
                .collect::<Vec<String>>()
                .join(",\n"),
        );
        code.push_str("\n        }\n");
        code.push_str("    }\n");
        code.push_str("}\n\n");

        // Generate the TapeMachine struct
        code.push_str("struct TapeMachine<'a> {\n    state: &'a TapeMachineState,\n    result: &'a mut Vec<TapeMachineSymbol>,\n    index: usize,\n}\n\n");

        // Generate the TapeMachine implementation
        code.push_str("impl<'a> TapeMachine<'a> {\n");
        code.push_str("    pub fn new(state: &'a TapeMachineState, result: &'a mut Vec<TapeMachineSymbol>) -> Self {\n");
        code.push_str("        Self {\n");
        code.push_str("            state,\n");
        code.push_str("            result,\n");
        code.push_str("            index: 0,\n");
        code.push_str("        }\n");
        code.push_str("    }\n\n");

        code.push_str("    fn p(&mut self, symbol: TapeMachineSymbol) {\n");
        code.push_str("        self.result[self.index] = symbol;\n");
        code.push_str("    }\n\n");

        code.push_str("    fn r(&mut self) {\n");
        code.push_str("        self.index += 1;\n");
        code.push_str("    }\n\n");

        code.push_str("    fn l(&mut self) {\n");
        code.push_str("        self.index -= 1;\n");
        code.push_str("    }\n");

        code.push_str("}\n\n");

        // Generate the main function
        code.push_str("fn main() {\n");
        code.push_str("    println!(\"Enter the number of steps:\");\n");
        code.push_str("    let mut steps_input = String::new();\n");
        code.push_str("    io::stdin().read_line(&mut steps_input).unwrap();\n");
        code.push_str("    let steps: usize = steps_input.trim().parse().unwrap();\n\n");

        code.push_str("    println!(\"Enter the total tape length:\");\n");
        code.push_str("    let mut tape_length_input = String::new();\n");
        code.push_str("    io::stdin().read_line(&mut tape_length_input).unwrap();\n");
        code.push_str("    let max_len: usize = tape_length_input.trim().parse().unwrap();\n\n");
        code.push_str("    let mut result = vec![TapeMachineSymbol::SymbolX; max_len];\n");
        code.push_str(&format!(
            "    let mut tape_machine = TapeMachine::new(&TapeMachineState::{}, &mut result);\n\n",
            self.initial_state
        ));

        code.push_str("    for i in 0..steps {\n");
        code.push_str("        println!(\"Step: {} State: {:?} Symbol: {:?}\",\n");
        code.push_str(
            "            i, tape_machine.state, tape_machine.result[tape_machine.index]);\n\n",
        );

        code.push_str(
            "        match (tape_machine.state, &tape_machine.result[tape_machine.index]) {\n",
        );

        // Sort transitions so that the ones with star condition are executed last
        // This is to ensure compatibility with switch statements
        let mut sorted_transitions = self.transitions.clone();
        sorted_transitions.sort_by(|a, b| {
            if a.condition == Condition::Star {
                std::cmp::Ordering::Greater
            } else if b.condition == Condition::Star {
                std::cmp::Ordering::Less
            } else {
                std::cmp::Ordering::Equal
            }
        });
        for transition in sorted_transitions {
            let condition = match &transition.condition {
                Condition::OR(symbols) => {
                    let mut condition_str = String::new();
                    for (i, symbol) in symbols.iter().enumerate() {
                        condition_str.push_str(&format!("TapeMachineSymbol::Symbol{}", symbol));
                        if i < symbols.len() - 1 {
                            condition_str.push_str(" | ");
                        }
                    }
                    condition_str
                }
                Condition::Star => "_".to_string(),
            };

            code.push_str(&format!(
                "            (TapeMachineState::{}, {}) => ",
                transition.initial_state, condition
            ));
            code.push_str("{\n");

            for step in &transition.steps {
                match step {
                    TransitionStep::R => code.push_str("                tape_machine.r();\n"),
                    TransitionStep::L => code.push_str("                tape_machine.l();\n"),
                    TransitionStep::X => {
                        code.push_str("                // X means do nothing\n");
                    }
                    TransitionStep::P(symbol) => {
                        code.push_str(&format!(
                            "                tape_machine.p(TapeMachineSymbol::Symbol{});\n",
                            symbol
                        ));
                    }
                }
            }

            code.push_str(&format!(
                "                tape_machine.state = &TapeMachineState::{};\n",
                transition.final_state
            ));
            code.push_str(&format!(
                "                println!(\"Final State: {{:?}}\", TapeMachineState::{});\n",
                transition.final_state
            ));
            code.push_str("            }\n");
        }

        code.push_str("            (_, _) => {\n");
        code.push_str("                println!(\"State: {:?} Index: {:?} Symbol: {:?}\", tape_machine.state, tape_machine.index, tape_machine.result[tape_machine.index]);\n");
        code.push_str("                let binary_result: String = tape_machine.result.iter().map(|x| x.as_str()).collect();\n");
        code.push_str("                println!(\"{}\", binary_result);\n");
        code.push_str("                panic!(\"Invalid state reached\");\n");
        code.push_str("            }\n");
        code.push_str("        }\n");
        code.push_str("    }\n\n");

        code.push_str("    let binary_result: String = tape_machine.result.iter().map(|x| x.as_str()).collect();\n");
        code.push_str("    println!(\"{}\", binary_result);\n");
        code.push_str("    let clean_result: String = tape_machine.result.iter().filter( |&x| x != &TapeMachineSymbol::SymbolX).map(|x| x.as_str()).collect();\n");
        code.push_str("    println!(\"=========\\n\");\n");
        code.push_str("    println!(\"{}\", clean_result);\n");
        code.push_str("}\n");

        code
    }
}
pub trait ToDot {
    fn to_dot(&self) -> String;
}

impl ToDot for ParseTree {
    fn to_dot(&self) -> String {
        let mut dot = String::from(
            "digraph {
                rankdir=LR;
                labelloc=\"t\";
                node [shape=circle, style=filled, fillcolor=lightblue, fontname=\"Arial\"];
                edge [fontcolor=blue, fontname=\"Arial\"];
                ",
        );

        // Define states
        for state in &self.states {
            let shape = if state == &self.initial_state {
                "doublecircle"
            } else {
                "circle"
            };
            let fillcolor = if state == &self.initial_state {
                "lightgreen"
            } else {
                "lightblue"
            };
            let width = if state == &self.initial_state {
                "1.5"
            } else {
                "1.2"
            };
            let height = if state == &self.initial_state {
                "1.5"
            } else {
                "1.2"
            };
            dot.push_str(&format!(
                "  \"{}\" [shape={}, fillcolor={}, width={}, height={}]; ",
                state, shape, fillcolor, width, height
            ));
        }

        // Define transitions
        for transition in &self.transitions {
            let condition = match &transition.condition {
                Condition::OR(symbols) => format!("[{}]", symbols.join(",")),
                Condition::Star => "*".to_string(),
            };
            let steps: Vec<String> = transition
                .steps
                .iter()
                .map(|step| match step {
                    TransitionStep::R => "R".to_string(),
                    TransitionStep::L => "L".to_string(),
                    TransitionStep::X => "X".to_string(),
                    TransitionStep::P(func) => format!("P({})", func),
                })
                .collect();
            let label = format!("{} / {}", condition, steps.join("-"));
            let color = "black";
            dot.push_str(&format!(
                "  \"{}\" -> \"{}\" [label=\"{}\", color={}];
",
                transition.initial_state, transition.final_state, label, color
            ));
        }

        dot.push_str(" } ");
        dot
    }
}

#[derive(Debug, PartialEq, Clone)]
pub struct Parser {
    lexer: Lexer,
    cur_token: Token,
    peek_token: Token,
    pub tree: ParseTree,
}

impl Parser {
    pub fn new(lexer: Lexer) -> Self {
        info!("Initializing Parser");
        let mut parser = Parser {
            lexer,
            cur_token: Token {
                text: "\0".to_string(),
                kind: TokenType::EOF,
            },
            peek_token: Token {
                text: "\0".to_string(),
                kind: TokenType::EOF,
            },
            tree: ParseTree {
                states: Vec::new(),
                initial_state: "".to_string(),
                symbols: Vec::new(),
                transitions: Vec::new(),
            },
        };
        parser.next_token(); // Initialize peek_token
        parser.next_token(); // Initialize cur_token
        parser
    }

    // Check if the current token matches the expected token type
    fn check_token(&self, kind: TokenType) -> bool {
        self.cur_token.kind == kind
    }

    // Check if the next token has the expected token type
    fn check_peek(&self, kind: TokenType) -> bool {
        self.peek_token.kind == kind
    }

    // Advance to the next token
    fn next_token(&mut self) {
        self.cur_token = self.peek_token.clone();
        self.peek_token = self.lexer.get_token().unwrap_or(Token {
            text: "\0".to_string(),
            kind: TokenType::EOF,
        });

        // If both current and peek token are newline, skip the newline
        if self.check_token(TokenType::NEWLINE) && self.check_peek(TokenType::NEWLINE) {
            self.next_token();
        }
    }

    // Abort the parsing process with an error message
    fn abort(&self, message: &str) {
        error!("Parsing error: {}", message);
        panic!("Parsing error: {}", message);
    }

    // Try to consume the current token if it matches the expected token type
    // If successful, print the token type and text (if available) and execute the optional action
    // Return true if the token was consumed, false otherwise
    fn try_consume<F>(&mut self, kind: TokenType, action: Option<F>) -> bool
    where
        F: FnMut(&Token),
    {
        if self.check_token(kind) {
            match kind {
                TokenType::IDENT => debug!("{:?}: {}", kind, self.cur_token.text),
                _ => debug!("{:?}", kind),
            }

            if let Some(mut action) = action {
                action(&self.cur_token);
            }

            self.next_token();
            true
        } else {
            false
        }
    }

    // Consume the current token if it matches the expected token type
    // If not, abort with an error message
    // Execute the optional action if provided
    fn consume<F>(&mut self, expected: TokenType, action: Option<F>)
    where
        F: FnMut(&Token),
    {
        if !self.try_consume(expected, action) {
            self.abort(&format!(
                "Expected {:?}, got {:?}",
                expected, self.cur_token.kind
            ));
        }
    }

    // Parse an initial state identifier: [IDENT]
    fn initial_state_identifier(&mut self) {
        self.consume(TokenType::LeftBracket, None::<fn(&Token)>);
        let mut initial_state = String::new();
        self.consume(
            TokenType::IDENT,
            Some(|token: &Token| {
                initial_state.push_str(&token.text);
            }),
        );
        if self.tree.initial_state.is_empty() {
            self.tree.initial_state = initial_state.clone();
            self.tree.states.push(initial_state);
        } else {
            self.abort("Initial state already defined.");
        }
        self.consume(TokenType::RightBracket, None::<fn(&Token)>);
        debug!("INITIAL_STATE_IDENTIFIER");
    }

    // Parse a list of state identifiers: IDENT (',' IDENT)*
    fn state_identifier_list(&mut self) {
        let mut state_identifiers = Vec::new();

        // Consume all tokens
        while self.check_token(TokenType::IDENT) || self.check_token(TokenType::LeftBracket) {
            if self.check_token(TokenType::LeftBracket) {
                self.initial_state_identifier();
            } else if !self.try_consume(
                TokenType::IDENT,
                Some(|token: &Token| {
                    state_identifiers.push(token.text.clone());
                }),
            ) {
                break;
            }
            if !self.try_consume(TokenType::COMMA, None::<fn(&Token)>) {
                debug!("STATE_IDENTIFIER_LIST");
                break;
            }
        }

        if self.tree.initial_state.is_empty() {
            self.abort("Initial state not defined.");
        }

        // If state identifiers have duplicates, abort with an error message
        state_identifiers.iter().for_each(|state_identifier| {
            if self.tree.states.contains(state_identifier) {
                self.abort(&format!("State {} already defined.", state_identifier));
            } else {
                self.tree.states.push(state_identifier.clone());
            }
        });
    }

    // Parse a states declaration: STATES ':' state_identifier_list NEWLINE
    fn states_declaration(&mut self) {
        self.consume(TokenType::STATES, None::<fn(&Token)>);
        self.consume(TokenType::COLON, None::<fn(&Token)>);
        self.state_identifier_list();
        self.consume(TokenType::NEWLINE, None::<fn(&Token)>);
        debug!("STATES_DECLARATION");
    }

    // Parse a list of symbol identifiers: IDENT (',' IDENT)*
    fn symbol_identifiers(&mut self) {
        let mut symbol_identifiers = Vec::new();

        self.consume(
            TokenType::IDENT,
            Some(|token: &Token| {
                symbol_identifiers.push(token.text.clone());
            }),
        );

        while self.try_consume(TokenType::COMMA, None::<fn(&Token)>) {
            self.consume(
                TokenType::IDENT,
                Some(|token: &Token| {
                    symbol_identifiers.push(token.text.clone());
                }),
            );
        }
        symbol_identifiers.iter().for_each(|symbol_identifier| {
            if self.tree.symbols.contains(symbol_identifier) {
                self.abort(&format!("Symbol {} already defined.", symbol_identifier));
            } else {
                self.tree.symbols.push(symbol_identifier.clone());
            }
        });

        // X is a special symbol
        self.tree.symbols.push("X".to_string());
        debug!("SYMBOL_IDENTIFIERS");
    }

    // Parse a symbols declaration: SYMBOLS ':' symbol_identifiers NEWLINE
    fn symbols_declaration(&mut self) {
        self.consume(TokenType::SYMBOLS, None::<fn(&Token)>);
        self.consume(TokenType::COLON, None::<fn(&Token)>);
        self.symbol_identifiers();
        self.consume(TokenType::NEWLINE, None::<fn(&Token)>);
        debug!("SYMBOLS_DECLARATION");
    }

    // Parse a transition step: R | L | P '(' IDENT ')' | X
    fn transition_step(&mut self) {
        // By default, do nothing
        let mut step: TransitionStep = TransitionStep::X;
        if self.try_consume(
            TokenType::R,
            Some(|token: &Token| {
                step = FromTokenAndValue::from_token_and_value(&token.clone(), None);
            }),
        ) {
        } else if self.try_consume(
            TokenType::L,
            Some(|token: &Token| {
                step = FromTokenAndValue::from_token_and_value(&token.clone(), None);
            }),
        ) {
        } else if self.try_consume(
            TokenType::X,
            Some(|token: &Token| {
                step = FromTokenAndValue::from_token_and_value(&token.clone(), None);
            }),
        ) {
        } else if self.try_consume(TokenType::P, None::<fn(&Token)>) {
            self.consume(TokenType::LeftParen, None::<fn(&Token)>);
            let mut print_string = String::new();
            // Either X or a symbol identifier
            if self.try_consume(
                TokenType::X,
                Some(|token: &Token| {
                    print_string.push_str(&token.text);
                }),
            ) {
            } else {
                self.consume(
                    TokenType::IDENT,
                    Some(|step: &Token| {
                        print_string.push_str(&step.text);
                    }),
                )
            };

            if !self.tree.symbols.contains(&print_string) {
                self.abort(&format!(
                    "Symbol {} not defined, So cannot be printed.",
                    print_string
                ));
            }
            step = FromTokenAndValue::from_token_and_value(
                &Token {
                    text: "P".to_string(),
                    kind: TokenType::P,
                },
                Some(print_string),
            );

            self.consume(TokenType::RightParen, None::<fn(&Token)>);
        } else {
            self.abort(&format!(
                "Expected {:?} or {:?} or {:?} or {:?} as an action step, got {:?}: {:?}",
                TokenType::R,
                TokenType::L,
                TokenType::P,
                TokenType::X,
                self.cur_token.kind,
                self.cur_token.text
            ));
        }
        self.tree.transitions.last_mut().unwrap().steps.push(step);
    }

    fn transition_steps(&mut self) {
        self.transition_step();
        while self.try_consume(TokenType::DASH, None::<fn(&Token)>) {
            self.transition_step();
        }
        debug!("TRANSITION_STEPS");
    }

    // Parse a list of transition conditions: IDENT ('|' IDENT)*
    fn transition_condition_list(&mut self) {
        let mut conditions: Vec<String> = Vec::new();

        // Consume X as well
        if self.try_consume(
            TokenType::X,
            Some(|token: &Token| {
                conditions.push(token.text.clone());
            }),
        ) {
        } else {
            self.consume(
                TokenType::IDENT,
                Some(|token: &Token| {
                    conditions.push(token.text.clone());
                }),
            );
        }

        while self.try_consume(TokenType::OR, None::<fn(&Token)>) {
            // Consume X as well
            if self.try_consume(
                TokenType::X,
                Some(|token: &Token| {
                    conditions.push(token.text.clone());
                }),
            ) {
            } else {
                self.consume(
                    TokenType::IDENT,
                    Some(|token: &Token| {
                        conditions.push(token.text.clone());
                    }),
                );
            }
        }
        self.tree.transitions.last_mut().unwrap().condition = Condition::OR(conditions);
        debug!("TRANSITION_CONDITION_LIST");
    }

    // Parse transition conditions: '*' | transition_condition_list
    fn transition_conditions(&mut self) {
        let mut star_condition = false;
        if !self.try_consume(
            TokenType::STAR,
            Some(|_token: &Token| {
                star_condition = true;
            }),
        ) {
            self.transition_condition_list();
        }

        // Override all other conditions with the star condition
        if star_condition {
            self.tree.transitions.last_mut().unwrap().condition = Condition::Star;
        }
        debug!("TRANSITION_CONDITIONS");
    }

    // Parse a transition declaration:
    // IDENT ',' transition_conditions ',' transition_steps ',' IDENT
    fn transition_declaration(&mut self) {
        // Initialize a new transition
        self.tree.transitions.push(Transition::new());

        // Initial state
        let mut initial_state = String::new();
        self.consume(
            TokenType::IDENT,
            Some(|token: &Token| {
                initial_state.push_str(&token.text);
            }),
        );
        self.tree.transitions.last_mut().unwrap().initial_state = initial_state;

        debug!("INITIAL_STATE_IDENTIFIER");
        self.consume(TokenType::COMMA, None::<fn(&Token)>);

        // Conditions
        self.transition_conditions();
        self.consume(TokenType::COMMA, None::<fn(&Token)>);

        // Actions
        self.transition_steps();
        self.consume(TokenType::COMMA, None::<fn(&Token)>);

        // Final state
        let mut final_state = String::new();
        self.consume(
            TokenType::IDENT,
            Some(|token: &Token| {
                final_state.push_str(&token.text);
            }),
        );
        self.tree.transitions.last_mut().unwrap().final_state = final_state;
        debug!("FINAL_STATE_IDENTIFIER");
        debug!("TRANSITION_DECLARATION");
    }

    // Parse transitions declarations:
    // TRANSITIONS ':' (NEWLINE transition_declaration)*
    fn transitions_declaration(&mut self) {
        self.consume(TokenType::TRANSITIONS, None::<fn(&Token)>);
        self.consume(TokenType::COLON, None::<fn(&Token)>);

        while self.try_consume(TokenType::NEWLINE, None::<fn(&Token)>) {
            if self.check_token(TokenType::EOF) {
                break;
            }
            self.transition_declaration();
        }
        debug!("TRANSITION_DECLARATIONS");
    }

    // Parse the entire program:
    // NEWLINE? states_declaration symbols_declaration transitions_declaration NEWLINE? EOF
    pub fn program(&mut self) {
        // Consume newlines
        while self.try_consume(TokenType::NEWLINE, None::<fn(&Token)>) {}
        self.states_declaration();
        self.symbols_declaration();
        self.transitions_declaration();
        // Consume newlines
        while self.try_consume(TokenType::NEWLINE, None::<fn(&Token)>) {}
        self.consume(TokenType::EOF, None::<fn(&Token)>);
        debug!("PROGRAM");
    }
}

{% endhighlight %}

</details>


## Conclusion

We were able to generate the rust code for the state machine, with
very minimal specification. You can find the full code and instructions to run [here](https://github.com/mabhay3420/state_machine_compile_rust).

One thing still bugs me: at the end of the day, we just substituted the parsed
values within the program. Can we actually construct the program as in:
1. Creating a module
2. Defining functions inside it
3. Writing the logic using these functions.

We can go a level deeper and work with LLVM IR. We won't try to have all bells
and whistles, but just simulate the state machine and print the result.

That is the content of the [next post][link_here].
