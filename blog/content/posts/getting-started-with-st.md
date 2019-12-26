---
title: "Getting Started With ST - the simple terminal"
date: 2019-12-26T18:35:10Z
draft: false
---


# Introduction

`st` is a [simple terminal emulator from suckless tools](https://st.suckless.org/). It provides the core features you need from a virtual terminal without being a bloated mess. While I like `urxvt`, `st` is smaller, simpler and a touch faster. Like most suckless tools, `st` provides a minimal feature set, with the expectation that users will patch in additional features as wanted, or compose `st` with other tools (e.g. `dmenu`) to provide a more complex experience. This approach may seem a bit spartan to many - editing C for configuration isn't the most friendly interface - but what you get is solid, easy to understand, and is very hackable. I use it on my systems because I like its minimalism.

# Getting the source and building

To build `st` you'll need a few libraries for building X applications, in particular `libX11`.
None of the following is surprising - clone the source, read the `README`, adjust as needed, build and install.

## Getting the source and basic build

Clone the source code directly from suckless.
```
$ git clone https://git.suckless.org/st
```

Change directory into the source tree

```
cd st
```

At this point, you may want to checkout the latest release tag (at time of writing it's `0.8.2`) with

```
git checkout 0.8.2
```

I'm happy building straight off master.

A simple build can be done by running

```
$ make st
```

and the binary is emitted to the source directory. It can be tested with

```
$ ./st
```

This is useful for testing customizations without installing system wide.

## System-wide installation

The built binary can be installed system wide using

```
$ sudo make clean install
```

## User installation

Alternatively, a user installation can be done by editing `config.mk`, changing the `PREFIX` variable to, e.g. `~/.local/` (assuming `~/.local/bin` is on your path).

```Makefile
PREFIX = ~/.local
```

then running

```
$ make clean install
```

If you need manpages for `st`, then you will need to update your `MANPATH` to include `~/local/share/man`.
Be aware that the `st` manpage conflicts with the SCSI tape device manuals - you may want to rename the man page. Maybe you don't care.

You can also read the man pages by telling `man` about the local search path

```
$ man -M ~/.local/share/man st
```

# Customization

Customization of `st` is usually done through editing the C files. I find it works pretty well out of the box (with `tmux` used from scrollback etc). Basic settings can be changed in the `config.h` configuration header file.

Further customization can be achieved by editing the C source code directly. The `st` webpage has a collection of [patches](https://st.suckless.org/patches/) from other users which can be applied to add new features. I find the default setup pretty much good to go - all I do usually is tweak the font size a little in `config.h`.

A `git` branch is useful for managing a collection of customizations. Changes can be rebased onto newer (or older) `st` versions, and new patch files can be generated using `git diff`.
