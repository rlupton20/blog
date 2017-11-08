---
title: What is functional programming?
---

Functional programming has been around for a while, but recently seems to be picking up momentum, most probably due to it being well suited to concurrent and parallel programming. It's a powerful tool to master, but it's not clear what makes a programming language functional. Can you "do functional programming" in a procedural or object oriented langauge? What is the essence of being a functional language? Why does functional programming give us particular benefits?

A language is often described as functional if it has function as first order objects. But this appears to be true of languages like Python and Rust, which aren't functional, and arguably is even true of C (one can pass around function pointers without too much trouble). More precisely, functional languages appear to have their roots in the lambda calculus, and so are, in a sense, an admission that their is something fundamentally mathematical about computation. This seems to capture something closer to the essence of the matter.

I'd like to propose that functional programming is, at it's core, about _abstraction over (the form of) computation_, as opposed to the procedural, and certainly object-oriented approach, which is fundamentally centred on abstraction over data.

# Algorithmic proofs of correctness

Reading classical texts on algorithms and their correctness from a mathematical perspective is interesting. For sake of illustration, let's work with a toy example, expressed in C, of a simple algorithm which finds the largest element in a non-empty array of positive 64-bit integers.

```C
uint64_t maximum(uint64_t array[], size_t length) {
    assert( length > 0); // Assert the array is non-empty

	uint64_t current_maximum = array[0];

	for(size_t i = 1; i < length; ++i) {
		if(array[i] > current_maximum) {
			current_maximum = array[i];
		}
	}

	return current_maximum;
}
```

Classically, to prove this algorithm returns the maximum integer in a non-empty array, we establish a _loop invariant_, and show that this loop invariant is true before entering the loop, is maintained across iterations of the loop, and hence (by induction, although often not stated this way) when the loop terminates is true. The loop invariant here would say that on iteration `j` of the loop, `current_maximum` is the largest element in the array `array[0:j]` (the array slice consisting of elements between `0` and `j`).

This is fine, apart from two things. Firstly, the proof by induction seems often to be unnecessarily clumsy. This appears to be because the language used to express the algorithm doesn't reflect the shape of the algorithm very well. Secondly, one begins to notice proofs of correctness of other algorithms seem to be, in essence, the same, and yet the details are different enough to justify their own proofs. If this were code, or if you have any mathematical training, one would be inclined to tease out any general underlying patterns, and examine them for what they are. Let's do that here.

Let's use type notation (like in Haskell) to extract the underlying form. Items of type `a -> b` are to be thought of as functions from values of type `a` to values of type `b`. It's not particularly important that these functions be pure at this point, but one may as well assume them to be. Let's use `[a]` to mean an array (or list) of elements of type `a`.

Examining the body of the `for` loop, we see that it is really just a function taking an item from an array, and some kind of aggregate value, and returning some kind of aggregate value which we assign back to `current_maximum` (in the case that the `if` statement fails, we're just returning `current_maximum` and assigning it back to itself). We return `current_maximum` at the end of the algorithm, and as input, take an array of elements. Let's say our array is of type `[a]`, and current maximum is of type `b` (both `uint64_t` in the above). Then we have:

```haskell
-- type of array (:: means "has type")
input :: [a]

-- result type (current_maximum)
result :: b

-- form of the for loop
forBody :: (a, b) -> b
```

This means that the `maximum` algorithm has the abstract form

```haskell
abstractForm :: ((a,b) -> b) -> [a] -> b
```

We can even describe the abstract form by it's behaviour on lists

```haskell
abstractForm f [] = error "list is empty"
abstractForm _[x] = x
abstractForm f (x:xs) = f x (abstractForm f xs)
```

Now, the point of this exercise is we can now extract the essence of the correctness proof as a _theorem schema_, giving us a correctness proof which is abstract over the form of the maximum algorithm.

More precisely, and better, immediate to prove by induction on the length of the list, we can prove

```
forall f :: (a,b) -> b
       P :: ([a],b) -> Bool
if

  (forall (x :: a) . P([x], abstractForm f [x]))
  and
  if P(xs, abstractForm f xs) then (forall (x :: a) . P(x:xs, f x (abstractForm f xs)))

then

  forall (x :: [a]) . P(x, abstractForm f x)
```

In fact, this _is_ (albeit informally) the statement of mathematical induction over the (recursively) defined list type. For the `maximum` algorithm, you can take `P(x, v)` as "`v` is the maximum of the list `x`", and `f` as the function

```haskell
f x y = if x > y then x else y
```

Proof of correctness then just boils down to establishing that, first `x` is the maximum of `[x]` (the first clause), and then, that if `v` is the maximum of `xs`, then `f x v` is the maximum of `x:xs`, which is self-evident.

In functional parlance, `abstractForm` would be known as `reduce` or `fold` (or more precisely `fold1` because we're requiring a non-empty list). It is the generic form of an iterative algorithm, because it is induction for the recursion that is implicitly behind iteration.

So what benefit does this bring to code? Functional programmers often say code is easier to reason about when written in a functional language. One of the reasons for this is perhaps because the preservation of invariants is encoded into the language itself, so that what is true about a program can become, to a greater extent, self-evident.

Some more specialised patterns occur frequently enough to be given their own names. `map`, `filter`, `drop`, `take` and friends are examples to dwell on.

# Monads

# Lisp macros
