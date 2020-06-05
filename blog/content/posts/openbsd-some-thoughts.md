---
title: "Some thoughts on BSD"
date: 2020-06-05T22:49:49Z
draft: false
---

I've played with BSD on and off over the course of the last few years. I initially messed around with DragonflyBSD for a while, and enjoyed the process (in part because some hackery was required to get it working in my arrangement), and was impressed by how useful the documentation was (in particular, `man` pages).

After acquiring a Thinkpad x200s for little money, I thought it might be interesting to give OpenBSD a shot. It's been fun to play with, and again, the documentation is excellent, but what struck me more is the sense of coherence the system has. Even compared to a minimal Debian install, the pieces of BSDs seem very well put together. Software has clear function, it does it well, and the interfaces, even for relatively complex things, are clear and simple.

There is plenty of neat linux software available too, and much that I wouldn't be without, but inevitably one runs into systems whose design beggars belief. On OpenBSD by contrast, I often find myself thinking that their solutions make sense, and address their problems directly and clearly. It's unclear why some of the linux equivalents are so complicated.

A recent example of this for me was mail. For one reason or another I've never set up a mail server of my own, and thought it would be worth learning how to do it, just so I could understand mail systems better.
I may later put one out in the wild for my own email.
SMTP and IMAP are simple enough protocols, they're testable by hand using `telnet`/`netcat`.
I messed around with `exim` for a while (the default mail transfer agent on Debian), and found reading through documentation somewhat painful.
I then decided to try OpenSMTP. The most striking thing was that an easy minimal configuration is provided in the `man` pages, and it's clear what that configuration does.
Moreover, defaults tend to start locked down, and you open up function as needed (which also means, you understand each piece of function as needed).
This makes reasoning about security in the system much simpler.

I could run OpenSMTP on linux just fine, but my impression with OpenBSD's tools (and BSDs more generally) is that they're very well designed, and have excellent UX.
Not UX in the sense of some narcissistic bullshit webapp, but the kind of experience where you don't feel like you're being treated like a child, and where you have the sense the designers care about avoiding users time spent thrashing around trying to figure out what the hell is going on.
Like they actually care that things work for you.
This makes me tempted to switch to a BSD on my main machine.

Most, if not all, of my toolchain would port across very naturally. I might miss a few compilers, but I find myself using `C11` and basic Unix tools exclusively more and more. It's certainly very tempting.
