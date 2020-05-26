---
title: "Object Models, Threading Models and Actor Models"
date: 2020-05-24T14:50:15Z
draft: false
---

One of the often recognized issues with object-oriented programming is that it's often hard to write multithreaded software well. Why should this be the case?

One of the core principles of object-oriented programming is that objects own the state which they manage internally.
Objects present an API which can maintain a set of internal invariants. Methods on the object mutate state to ensure these invariants are upheld.
On a single threaded system this seems a tenable idea[^1] - mutations are easy to sequence when only one thing happens at a time. 

[^1]: And yet these systems still end up a total mess.

When two threads are involved the picture changes.
What matters in the multithreaded world is where the instruction pointers go on the individual threads.
Without exclusion, there is nothing to stop two threads executing method calls on an individual object at the same time, either because the two threads are running on different cores, or one thread got pre-empted part way through the execution of a method.
For methods which access (globally) read-only data this doesn't cause any issues.
As soon as we introduce mutation, we need either a way to sequence operations to keep the object consistent, or to use a lock and exclude concurrent access.

In other words, thread ownership must dominate object ownership.

Enforcing sequential access to data really limits the amount of concurrency we can achieve, and often can leave threads spinning or blocked, and not making progress.
It's not just that only one thread can operate on the data at any one time.
If a piece of data is read and written from two cores (for arguments sake, on the same socket, since non-uniform memory access only exacerbates these issues), then each write must be pushed out to L3 cache (L2 on older architectures) for the other core to see it.
This reduces the number of concurrent data accesses we can make in a fixed time period when 2 cores are trying to make progress, because the cost of a write increases about 10x. The key thing here is that this blocks other work from being done (in practice this is usually an `mfence` instruction).

Suppose we wanted to avoid that cost.
Object method execution would then have to be pinned to a single core.
But then how do objects communicate across cores?
We can't just call methods because then we start executing a foreign core's object methods on the wrong core.
The natural thing to do is to introduce queues, and have objects read messages and dispatch data to each other asynchronously on these queues. If our queues are single-producer-single-consumer then we don't need full sequential consistency, and can manage with release semantics on writes and acquire semantics on read, which is already guaranteed on regular writes and reads in the x86_64 instruction set anyway (these semantics place guarantees on the order on which memory changes are observed, but not when).

Note that the data must go via L3 cache still, but that happens asynchronously, and the core won't be waiting for the synchronization to happen (that is, for a memory fence instruction to do its work) and can progress with something else

At that point method calls are redundant, and our objects are actually just loops acting on data arriving in queues[^2].
What we really have is a small actor model.

[^2]: I'm not claiming this model is optimal and devoid of issues, or even fast, it's just a natural consequence of not wanting to pay the full price of a memory fence every read/write.

The differences here shouldn't be understated.
Passing messages is very different from making method calls.
To begin with asynchronous message passing provides no illusions of global temporal consistency - with multi-threaded code the system can appear to be in different states at different times in different places, and what matters is often what order things are observed in localised to one core.
Note that the ordering of observations is often not globally consistent, and is localised to individual cores.

At this point focusing on objects is just an unnecessary distraction.
