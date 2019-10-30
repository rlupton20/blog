---
title: "The Y combinator - recursion without recursion"
date: 2019-10-30T12:21:36Z
draft: true
---

# Introduction

The Y combinator allows recursion to be expressed in languages that have no way to handle recursion.

The Little Schemer (amazon [uk](https://www.amazon.co.uk/Little-Schemer-MIT-Press/dp/0262560992/ref=as_sl_pc_tf_til?tag=zigschots20-21&linkCode=w00&linkId=01845223831793ea377c7e652c3f8547&creativeASIN=0262560992)/[us](https://www.amazon.com/Little-Schemer-Daniel-P-Friedman/dp/0262560992/ref=as_sl_pc_qf_sp_asin_til?tag=zigschots20-20&linkCode=w00&linkId=b4600a1821debb502f6423061932ea51&creativeASIN=0262560992)) gives a great introduction to recursion, including a section on the Y combinator. The presentation here is a little different, but The Little Schemer is a classic, and required reading for anyone wanting to get an insight into the power and beauty of recursion. It's a fantastic book!

# Recursive functions as fixed points of (higher-order) functions

The classic recursive definition of factorial is

```scheme
(define (factorial n)
  (if (= n 0)
    1
    (* n (factorial (- n 1)))))
```

This definition references itself. If we view it as an equation in terms of `factorial` however, we can write a new function

```scheme
(define (factorialize f)
  (lambda (n)
    (if (= n 0)
      1
      (* n (f (- n 1))))))
```

and observe that `(factorialize factorial)` is `factorial` - in other words `factorial` is a fixed-point of `factorialize`.

Observe also that `factorialize` is not recursive. The Y combinator finds fixed points of functions - it allows us to define factorial by

```scheme
(define factorial
  (Y factorialize))
```

# Deriving the Y combinator

As a start, notice that ideally to get `factorial` out of `factorialize`, we pass `factorialize` something like `factorialize` as it's argument. In fact, each of the following gets closer and closer to factorial

```scheme
(factorialize factorialize)                                ; Evaluates for 0
(factorialize (factorialize factorialize))                 ; Evaluates for 0, 1
(factorialize (factorialize (factorialize factorialize)))  ; Evaluates for 0, 1, 2
...
```

One can think of `factorial` as being something like

```scheme
(factorialize (factorialize (factorialize ...)))
```

**IMPROVE**

Now

```scheme
((lambda (f) (f f))
 factorialize)
```

is the same as `(factorialize factorialize)`, but using `factorialize` as an argument to `factorialize` doesn't quite work - the argument `factorialize` also needs an argument to represent `recur`. What we want to do is to call `factorialize` with a proper function for recurring:

```scheme
((lambda (f) (f f))
 (lambda (recur)
  (factorialize ?)))
```

Here the function `(lambda (recur) (factorialize ?))` is called with `recur` set to `(lambda (recur) (factorialize ?))`. But then this is just the same as `(recur recur)`, and, if we put `(recur recur)` in place of the `?`, we end up with our expression being equal to `(recur recur)` and `(factorialize (recur recur))` and hence `(factorialize expression)`, in other words we obtain a fixed point!

```scheme
((lambda (f) (f f))
 (lambda (recur)
  (factorialize (recur recur))))
```

What happens when we try and evaluate this?

```
((lambda (f) (f f))
 (lambda (recur)
  (factorialize (recur recur))))

;Aborting!: maximum recursion depth exceeded
```

Hmm. The issue here is that when trying to evaluate this procedure, `(recur recur)` has to be fully evaluated before a call to `factorialize` is made, but this means for our expression `exp` to be evaluated, `exp` must be evaluated - this leads to an infinite loop! What we want to do is to delay the evaluation of `(recur recur)` until it is needed (in other words evaluate it lazily). We can do this with the aid of a lambda:

```scheme
((lambda (f) (f f))
 (lambda (recur)
  (factorialize (lambda (x) ((recur recur) x)))))
```

Now:

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

Looking good! Notice that none of this has anything to do with `factorialize`. We can abstract:

```scheme
(define (Y F)
  ((lambda (f) (f f))
   (lambda (recur)
     (F (lambda (x) ((recur recur) x))))))
```

Hello Y combinator!

# Examples

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

There is nothing to stop multiple calls to recur:

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

# Unwinding the Y combinator
