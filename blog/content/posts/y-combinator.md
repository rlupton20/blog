---
title: "The Y combinator - understanding recursion without recursion"
date: 2019-10-30T12:21:36Z
draft: false
---

# Introduction

Recursion is central to functional programming, as a clearer alternative to loops as other control structures typical of imperative languages. Functional programming encourages programmers to study recursion in greater depths. I first encountered the Y combinator in the mind-bending penultimate chapter of the wonderful *The Little Schemer*, which explores recursion in great depth. In an effort to unbend my own mind on the subject, I decided to derive it for myself, so I could see how it worked, and gain an extra tool in dealing with recursion and closures.

> Do you now know why Y works? Read this chapter just one more time and you will. <br>
> *(The Little Schemer)*

The Y combinator was discovered by Haskell Curry in the 1940s. It allows recursion to be captured without functions needing to reference themselves by name. It provides some insight into the nature of recursion in the lambda calculus (where nothing has a name), and also demonstrates the power of closures.

We will conduct our explorations mostly in scheme, because it's expressive, concise and elegant, but we also give examples in Haskell and JavaScript at the end. The Haskell version is ludicrously simple and clear (relying on lazy evaluation), while the JavaScript version mirrors the Scheme version.

## Further reading

*The Little Schemer* (amazon [uk](https://www.amazon.co.uk/Little-Schemer-MIT-Press/dp/0262560992/ref=as_sl_pc_tf_til?tag=zigschots20-21&linkCode=w00&linkId=01845223831793ea377c7e652c3f8547&creativeASIN=0262560992)/[us](https://www.amazon.com/Little-Schemer-Daniel-P-Friedman/dp/0262560992/ref=as_sl_pc_qf_sp_asin_til?tag=zigschots20-20&linkCode=w00&linkId=b4600a1821debb502f6423061932ea51&creativeASIN=0262560992)) gives a great introduction to recursion, including a section on the Y combinator. The presentation here is a little different, since I wanted a more direct understanding of how the Y combinator worked.

# Recursive functions as fixed points of (higher-order) functions

The Y combinator allows the programmer to pass in a function which isn't explicitly recursive (doesn't reference itself by name), but describes a step in a recursive process with a continuation, and provides back a new function which recursively applies that step using itself as the continuation.

Let's start by making the term "step in a recursive process with a continuation" more concrete, and clarify how the Y combinator acts on these steps.

To give us something specific to think about, let's examine the factorial function. The classic recursive definition of factorial is expressed in Scheme as follows

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

and observe that `(factorialize factorial)` (`factorialize` applied to the `factorial` function) is itself `factorial`. The formal way to say this is that `factorial` is a fixed-point of `factorialize`.

Its important to understand that `factorialize` operates on all functions from numbers to numbers. In terms of function, we can look at `factorialize` as doing a single step in the factorial function, and then, instead of recursing, handing off the remainder of the work to a continuation which is passed in as a parameter. This is what is meant by a "step in a recursive process with a continuation". `factorialize` itself is not recursive - it hands the recursion over to some continuation which is passed in.

The Y combinator turns these recursive steps into full-blown recursive functions. Applied to `factorialize` it finds a fixed point (you can prove by induction that such a fixed point is necessarily the `factorial` function). This means we can define the factorial function by

```scheme
(define factorial
  (Y factorialize))
```

where here, `Y` is the Y combinator. How does it do this? In effect it passes `factorialize` in as the continuation to `factorialize`, so that the same recursive step is applied over-and-over, until we reach the base case.

# Deriving the Y combinator

## Capturing our own value

The fixed point perspective is a useful starting point, because we want the Y combinator applied to `factorialize` to be an expression `expr` which satisfies

```
expr = (factorialize expr)
```

One possible starting point is to ask, how can an expression capture it's own value? That is, can we write an expression, which, inside itself, has a handle on its own value.

The trick to doing this is to observe that applying the anonymous function `(lambda (f) (f f))` to a function allows a function to receive itself as an argument. If we feed this function another function, `(lambda (recur) ...)`, and try to evaluate it

```scheme
((lambda (f) (f f))
  (lambda (recur)
    ...))
```

Then inside the inner lambda, `recur` will be bound to the `(lambda (recur) ...)`. But then `(recur recur)` is just the inner lambda `(lambda (recur) ...)` applied to itself, which is the value of the expression we're trying to evaluate (that might take a few reads!).

In other words, if we try to evaluate the following

```scheme
((lambda (f) (f f))
  (lambda (recur)
    (recur recur)))
```

by applying the outer function, we get back to where started. If you try to evaluate this, it will just loop forever! In Haskell we could write this as

```haskell
let x = x in x
```

Since we are looking for a function `exp` with value `(factorialize exp)`, and we know `(recur recur)` has value `exp` in the above, we can try inserting a call to factorialize:

```scheme
((lambda (f) (f f))
  (lambda (recur)
    (factorialize (recur recur))))
```

By the same reasoning, if this has value `v`, then by applying the outer `lambda`, we see it also has value `(factorialize v)`. Great! We've found a fixed point for `factorialize`, and hence this must be the `factorial` function. In fact, if we parameterize over `factorialize` then we have the (formal) Y combinator!

## Making it run

What happens when we try and evaluate this? Firing up a Scheme interpreter and plugging it in

```
((lambda (f) (f f))
 (lambda (recur)
  (factorialize (recur recur))))

;Aborting!: maximum recursion depth exceeded
```

Hmm. The issue here is that when trying to evaluate this procedure, `(recur recur)` has to be fully evaluated before a call to `factorialize` is made (scheme evaluates its arguments before calling functions). This means for our expression `exp` to be evaluated, `exp` (`(recur recur)`) must first be evaluated - this leads to an infinite loop!

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

We started with the factorial function, so that ought to work as expected:

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

Another easy example is defining the length of a list:

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

One intuitive way to get `factorial` out of `factorialize`, is to pass `factorialize` something like `factorialize` as it's argument. In fact, each of the following gets closer and closer to `factorial`

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

Notice that to evaluate `factorial` on a given number, we only need finitely many of these calls to `factorialize`.

In fact, if we expand, for example, `((Y factorialize 3))` we get

```scheme
(factorialize
  (factorialize
    (factorialize
      ((factorialize _) 0))))
```

where the `_` represents a `lambda` which is never evaluated.

# In some other languages

The Y combinator is not restricted to Lisps. Let's give examples of the Y combinator in Haskell and JavaScript.

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

This to me seems something close to magic, even though in many ways its simpler to think about than the Scheme version. `y` is more often named `fix` in the Haskell community, presumably because it is a definition by equation of a fixed-point. Haskell really is quite beautiful.

## The Y combinator in JavaScript

JavaScript is not so beautiful. Lambdas and functions might be the only sensible parts of JavaScript, but that's an extraordinarily powerful part all the same. Another grace is that you can even try this snippet in the developer console of your browser.

```javascript
const y = (f) => ((g) => g(g))(
    (recur) => f((x) => recur(recur)(x))
);

const factorialize = (recur) => (n) => n == 0 ? 1 : n * recur (n - 1);
const factorial = y(factorialize);
```

# Conclusions

Lambdas really are way more powerful than you would at first think! I found understanding how to derive the Y combinator gives me a new way to think. There really are good reasons why functional programming reveres the lambda so much - they are the Jedi weapon par excellence.

I can imagine many folks would balk at the code for the y combinator - it's hard to see what it does at a glance. It's nonetheless wonderfully abstract, and can be understood by its properties. Nonetheless, explicit recursion is probably clearer.
