---
title: "The Y combinator - recursion without recursion"
date: 2019-10-30T12:21:36Z
draft: true
---

# Introduction

The Y combinator allows recursion to be expressed without functions needing to reference themselves by name. It provides some insight into the nature of recursion in the lambda calculus, and also demonstrates the power of closures with lexical scoping. It is an essential weapon to study for any lambda warrior.

The Y combinator allows the programmer to pass in a function which isn't explicitly recursive (doesn't reference itself by name), but describes a step in a recursive process, and provides back a new function which recursively applies that step.

We will conduct our explorations mostly in scheme, because it's expressive, concise and elegant, but we also give examples in Haskell and JavaScript at the end.

## Further reading

The Little Schemer (amazon [uk](https://www.amazon.co.uk/Little-Schemer-MIT-Press/dp/0262560992/ref=as_sl_pc_tf_til?tag=zigschots20-21&linkCode=w00&linkId=01845223831793ea377c7e652c3f8547&creativeASIN=0262560992)/[us](https://www.amazon.com/Little-Schemer-Daniel-P-Friedman/dp/0262560992/ref=as_sl_pc_qf_sp_asin_til?tag=zigschots20-20&linkCode=w00&linkId=b4600a1821debb502f6423061932ea51&creativeASIN=0262560992)) gives a great introduction to recursion, including a section on the Y combinator. The presentation here is a little different, since I wanted a better understanding of how the Y combinator actually worked.

# Recursive functions as fixed points of (higher-order) functions

Let's start by making the term "step in a recursive process" a bit more precise, as well as clarifying what the Y combinator does with these descriptions of steps.

To give us something concrete to think about, let's examine the factorial function. The classic recursive definition of factorial is

```scheme
(define (factorial n)
  (if (= n 0)
    1
    (* n (factorial (- n 1)))))
```

This definition references itself. We can view it as an equation in terms of `factorial`, however. In fact, we can define

```scheme
(define (factorialize f)
  (lambda (n)
    (if (= n 0)
      1
      (* n (f (- n 1))))))
```

and observe that `(factorialize factorial)` is `factorial` - in other words `factorial` is a fixed-point of `factorialize`. `factorialize` operates on all functions from numbers to numbers. In terms of function, we can look at `factorialize` as doing a single step in the factorial function, and then, instead of recursing, handing off the remainder of the work to a continuation which is passed in as a parameter. This is what is meant by a step in a recursive process.

Observe that `factorialize` is not recursive - it hands the recursion over to some continuation which is passed in.

The Y combinator turns these recursive steps into full-blown recursive functions. Applied to `factorialize` it finds a fixed point (you can prove by induction that such a fixed point is necessarily the `factorial` function). This means we can define the factorial function by

```scheme
(define factorial
  (Y factorialize))
```

where here, `Y` is the Y combinator.

# Deriving the Y combinator

## Capturing our own value

The fixed point perspective is a useful starting point, because we want the Y combinator applied to `factorialize` to be an expression `expr` which satisfies

```
expr = (factorialize expr)
```

One possible starting point is to ask, how can expression capture it's own value? That is, can we write an expression, which inside itself, can have it's own value represented.

The trick to doing this is to observe that `(lambda (f) (f f))` allows a function to receive itself as an argument. If we feed it a function `(lambda (recur) ...)` and try to evaluate it

```scheme
((lambda (f) (f f))
  (lambda (recur)
    ...))
```

Then inside the inner lambda, `recur` will be bound to the `(lambda (recur) ...)`. But then `(recur recur)` is just the inner lambda `(lambda (recur) ...)` applied to itself, which is the value of the expression we're trying to evaluate.

In other words, if we try to evaluate the following

```scheme
((lambda (f) (f f))
  (lambda (recur)
    (recur recur)))
```

by applying the function, we get back to where started. If you try to evaluate this, it will just loop forever. In Haskell we could write this as

```haskell
let x = x in x
```

Since we are looking for a function `exp` with value `(factorialize exp)`, and we know `(recur recur)` has value `exp` in the above, we can insert a call to factorialize:

```scheme
((lambda (f) (f f))
  (lambda (recur)
    (factorialize (recur recur))))
```

If this has value `v`, then by applying the outer `lambda`, we see it also has value `(factorialize v)`. Great! We've found a fixed point for factorialize, and hence this must be the factorial function. In fact, if we parameterize over `factorialize` then we have the formal Y combinator!

## Making it run

What happens when we try and evaluate this?

```
((lambda (f) (f f))
 (lambda (recur)
  (factorialize (recur recur))))

;Aborting!: maximum recursion depth exceeded
```

Hmm. The issue here is that when trying to evaluate this procedure, `(recur recur)` has to be fully evaluated before a call to `factorialize` is made (scheme evaluates its arguments strictly). This means for our expression `exp` to be evaluated, `exp` (`(recur recur))`must be evaluated - this leads to an infinite loop!

To fix this, we want to delay the evaluation of `(recur recur)` until it is needed (in other words evaluate it lazily). We can do this with the aid of a lambda:

```scheme
((lambda (f) (f f))
 (lambda (recur)
  (factorialize (lambda (x) ((recur recur) x)))))
```

Let's try it:

```
(((lambda (f) (f f))
 (lambda (recur)
   (factorialize (lambda (x) ((recur recur) x))))) 0)

;Value: 1
```

```
(((lambda (f) (f f))
 (lambda (recur)
   (factorialize (lambda (x) ((recur recur) x))))) 5)

;Value: 120
```

Looking good! Notice that none of this has anything to do with `factorialize`. We can parameterise and abstract:

```scheme
(define (Y F)
  ((lambda (f) (f f))
   (lambda (recur)
     (F (lambda (x) ((recur recur) x))))))
```

Hello Y combinator!

# Examples of the Y combinator in action

We started with the factorial function, so that ought to work:

``` scheme
(define factorial
  (Y
   (lambda (recur)
     (lambda (n)
       (if (= n 0)
           1
           (* n (recur (- n 1))))))))


(factorial 5)

;Value: 120
```

Another easy example is defining the length of a list.

```scheme
(define length
  (Y
   (lambda (recur)
     (lambda (l)
       (if (null? l)
           0
           (+ 1 (recur (cdr l))))))))


(length '(1 2 3))

;Value: 3

```

Multiple calls to recur also work just fine:

```scheme
(define fibonacci
  (Y
   (lambda (recur)
     (lambda (n)
       (cond 
        ((= n 0) 0)
        ((= n 1) 1)
        (else (+ (recur (- n 1))
                 (recur (- n 2)))))))))
                 

(map fibonacci (list 0 1 2 3 4 5 6 7 8))

;Value: (0 1 1 2 3 5 8 13 21)
```

We can also use the Y combinator's definition to write recursive lambdas inline. To give a contrived example using length of lists:

```
(map
  ((lambda (F)
     ((lambda (f) (f f))
      (lambda (recur)
        (F (lambda (x) ((recur recur) x))))))
   (lambda (recur)
     (lambda (l)
       (if (null? l)
           0
           (+ 1 (recur (cdr l)))))))

  '((1) (1 2) (1 2 3)))

;Value: (1 2 3)
```

# Intuitions about Y as a limit

Let's try and get a different intuition for how Y works. Let's lean on our `factorial` and `factorialize` example some more.

One intuitive way to get `factorial` out of `factorialize`, is to pass `factorialize` something like `factorialize` as it's argument. In fact, each of the following gets closer and closer to factorial

```scheme
(factorialize factorialize)                                ; Evaluates correctly for 0
(factorialize (factorialize factorialize))                 ; Evaluates correctly for 0, 1
(factorialize (factorialize (factorialize factorialize)))  ; Evaluates for correctly 0, 1, 2
...
```

One can think of `factorial` as being something like

```scheme
(factorialize (factorialize (factorialize ...)))
```

However, if you expand out `(Y factorialize)`, this is exactly what you get! Notice that to evaluate `factorial` on a given number, we only need finitely many of these calls to `factorialize`. The Y combinator is in effect providing an additional call to `factorialize` as and when it's needed.

# In some other languages

## The Y combinator in Haskell

Lazy evaluation means that in Haskell we don't need to work so hard, and we can just write down what i means to be a fixed point

```haskell
y :: (a -> a) -> a
y f = let g = f g in g

factorial :: Integer -> Integer
factorial = y factorialize
  where
    factorialize _ 0 = 1
    factorialize recur n = n * recur (n - 1)
```

This to me seems something close to magic, even though in many ways its simpler to think about than the scheme version. `y` is more often named `fix` in the Haskell community, presumably because it is an definition by equation of a fixed point.

## The Y combinator in JavaScript

Lambdas and functions might be the only sensible bit of JavaScript - you even try this snippet in the developer console of your browser.

```javascript
const y = (f) => ((g) => g(g))(
    (recur) => f((x) => recur(recur)(x))
);

const factorialize = (recur) => (n) => n == 0 ? 1 : n * recur (n - 1);
const factorial = y(factorialize);
```
