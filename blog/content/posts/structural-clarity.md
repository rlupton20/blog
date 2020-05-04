---
title: "Structural Clarity"
date: 2020-05-04T19:55:55Z
---

There is a trend in software engineering to conflate "good code" with making it read like English (or your native language of choice). It's not obvious that this is a valuable thing to aim for. Indeed, working hard to make code read like English is often pointless, or even counterproductive, in a variety of situations.

To begin with, English is very imprecise, a quality computers don't grant much tolerance for. Clarity and precision is often not a function of how the code "reads", but of the core structure and invariants that bind it together[^1]. Attention is better spent, in the spirit of *via negativa*, removing what is not necessary to reduce a problem to it's core. This is all the more necessary for problems of performance and robustness which can often be hard to get correct. In some sense, the aim here is to elevate *why* something works above *how* - the expression of the precise implementation is often not all that interesting. 

[^1]: Solving problems in Haskell often leads to clear solutions. I think this is because functional programming in general is designed to describe precisely the structure of computation.

Instead aim for clarity by structure[^2]. Structure should emphasize correctness and efficiency, and make it clear why a problem is solved.

[^2]: It's borderline absurd that so many people complain Lisp is unreadable. Usually this means it doesn't read like English. However, it is often quite principled in structure.
