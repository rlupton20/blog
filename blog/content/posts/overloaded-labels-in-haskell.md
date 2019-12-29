---
title: "Overloaded Labels in Haskell - towards better record fields"
date: 2019-12-29T20:19:09Z
draft: false
---

# Introduction

Haskell is one of my (if not my) favourite language. Like all languages it has its warts, and one which I have always found particularly annoying is the fact that record names of data types can't be overloaded (they are just functions, after all). I haven't been writing as much Haskell as I would like lately, and certainly haven't been messing around with the more cutting edge type level functionality, but noticed that GHC 8.0 (which was released a while ago now), was release with some new language extensions which looked like they would allow record names to be overloaded, in some shape or form.

The GHC wiki, which purports to provide the necessary documentation to understand this, describes what the new language extensions are, but not really how you might go about using it. So I cooked up a small toy to show how I think they are meant to be used.

# A short example

My toy example has two data types, a `User` data type, and an `Item` data type. Both of these have a field I want to call `name`. In order to be able define these two types, I need the `DuplicateRecordFields` extensions, otherwise GHC will complain. `OverloadedLabels` provides some syntactic sugar to use with the `IsLabel` type class, which brings the record syntax nearer to what one might expect. The other extensions are needed for the required type-level fu.

Here is a short working example - chuck it in a file called `OverloadedLabels.hs`,

```haskell
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedLabels #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
module OverloadedLabels where

import GHC.OverloadedLabels (IsLabel(..))
 
data User = User { name :: String } deriving (Eq, Show)

data Item = Item { name :: String
                 , uid :: Integer } deriving (Eq, Show)

instance IsLabel "name" (Item -> String) where
  fromLabel = name

instance IsLabel "name" (User -> String) where
  fromLabel = name
```

and fire it up in `ghci` with the `OverloadedLabels` extension (so that we can use the extended syntax interactively).

```
$ ghci -XOverloadedLabels OverloadedLabels.hs
GHCi, version 8.4.4: http://www.haskell.org/ghc/  :? for help
[1 of 1] Compiling OverloadedLabels ( OverloadedLabels.hs, interpreted )
Ok, one module loaded.
*OverloadedLabels>
```

The first thing to note is that, even with type annotations, the `name` accessor can't be used directly:

```
*OverloadedLabels> (name :: User -> String) $ User "bob"

<interactive>:4:2: error:
    Ambiguous occurrence ‘name’
    It could refer to either the field ‘name’,
                             defined at OverloadedLabels.hs:12:20
                          or the field ‘name’, defined at OverloadedLabels.hs:10:20
```

This would be the most ergonomic experience (albeit, not necessarily backward compatible). The `OverloadedLabels` extension gives a terse almost-ideal syntax for using `name` to access `name` fields:


```
*OverloadedLabels> #name $ User "bob" :: String
"bob"
*OverloadedLabels> #name $ Item "book" 5 :: String
"book"
```

(The type hints here help resolve the correct `IsLabel` instance - in real-world usage type inference will probably do the magic here for you).

Cool!

# Clarifying each extension

In this example, each extension is pretty straightforward

- `DuplicateRecordFields` instructs the compiler to allow the same record accessor names to be defined for multiple data types.
- `OverloadedLabels` provides the `#` syntactic sugar. In the above, `#name` decodes to a `fromLabel` instance for the appropriate types.

# Some observations

Notice how the `IsLabel` typeclass is about labelling the accessor function, and not the field of a record (in the example above we name the function `* -> String` not `String`). Also note that there is nothing preventing you from overloading `name` even further - we can use it to give an accessor for the `Integer` element of the `Item` datatype above.

```haskell
instance IsLabel "name" (Item -> Integer) where
  fromLabel = uid
```

```
*OverloadedLabels> #name $ Item "book" 5 :: Integer
5
```

Nonetheless, `IsLabel` can be used to label more than just record accessors - it's much more generic.

Also note that the accessor `name` is distinct from `#name`, which decodes to a type-level `Symbol` `"name"` - they are completely different objects - the naming here shows intention, more than anything.

# Looking forward

While this allows gives us overloaded record accessors, it's a shame about the boilerplate. Fortunately, work is being done to enable GHC to generate (or infer) the `IsLabel` instances by way of a `HasField` typeclass which is instantiated for each data type. Take a look at the work on magic type classes for more information. `HasField` has been merged into GHC 8.2, but without the typeclass inference for `IsLabel`. With that last piece in place, the `#` symbol should be usable with little to no boilerplate!
