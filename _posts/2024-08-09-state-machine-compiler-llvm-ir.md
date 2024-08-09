---
layout: post
title: State Machine Compiler - Going lower down the stack
subtitle: Translating to LLVM IR
cover-img: https://source.unsplash.com/featured/1920x1080/
thumbnail-img: https://source.unsplash.com/featured/1920x1080/
tags: []
comments: true
readtime: true
usemathjax: true
---

We will be translating the state machine language to LLVM IR.

1. Setup
- Install LLVM ( v18 to work with rust bindings)
- Install inkwell
- setup environment variables:
    export LLVM_SOURCE_DIR="/Users/mabhay/projects/llvm-project-llvmorg-18.1.8"
    # For rust bindings
    export LLVM_SYS_180_PREFIX=${LLVM_SOURCE_DIR}/build
    # Give priority to tools built from llvm source
    export PATH="$LLVM_SOURCE_DIR/build/bin:$PATH"
- Make modifications to the build command to make sure it can find the required libraries. See: https://github.com/TheDan64/inkwell/issues/345#issuecomment-2278650151

2. Write basic llvm compiler trait