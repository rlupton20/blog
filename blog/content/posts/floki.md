---
title: "Easy, reproducible, and shareable development environments"
date: 2020-03-18T19:32:29Z
---

Docker makes it easy to create container images containing the tools you need to work on a project. However this can be fiddly to use well in many circumstances. Here we will visit the normal approach of using a docker container for development environments, indicate some ways in which it gets complicated, and then introduce a solution, called [floki](https://github.com/Metaswitch/floki) which greases the wheels and makes the whole process easier.

# Creating a basic build environment with Docker

Let's imagine we have a little C project which we want to statically compile using musl libc. We might, in the K&R tradition, have

```C
#include <stdio.h>

int
main(int argc, char* argv[])
{
  printf("Hello, world\n");
  
  return 0;
}
```

in a file `main.c`, and a simple `Makefile`

```
.PHONY: clean

all:
      gcc -o main -static main.c

clean:
      rm main
```

To build against musl libc, it can be convenient to use a docker container built off of an alpine image as a base, where `make` and a C compiler have been installed. We can declare this in a `Dockerfile`

```
FROM alpine:latest

RUN apk update && apk add alpine-sdk
```

(in practice, using the `latest` tag and running `apk update` is unlikely to be reproducible - you'll want to pin your image more precisely).

This can be built with

```
$ docker build -t hello-world .
```

And we can mount our codebase at `/mnt` inside a container running this image with

```
$ docker run --rm -it -v $(pwd):/mnt hello-world:latest
```

From here, you should be able to `cd /mnt` and run `make` to get a statically linked binary linked against musl libc.

Great! This is a fine way to get working with docker as a build environment. However, it's a bit of a pain to run the build and then run steps when the needs of the build container change. This is of course scriptable, but repeating this pattern across many codebases leads to a lot of copy-pasting of scripts. Furthermore, if you need additional settings for your docker container - additional volume mounts, docker-in-docker for testing with e.g. `docker-compose`, or forwarding of an SSH agent to authenticate with a `git` server, the scripting becomes more unwieldy, and harder to maintain across codebases.

Oftentimes, build environments are neglected, and even if developers are using docker containers for their build, they don't share anything to replicate that environment for other users. Figuring out what is needed to build a project is an unnecessary time sink.

# floki

`floki` essentially lets you write what you want in a YAML file, and turns that into reality. It was created to solve the problems above, which I found across multiple microservice codebases. It's great for new developers wanting to get build environments, because they just need to run `floki` and they are good to go.

So how would the example above translate?

Well, we keep the `Dockerfile`, and then we create a file called `floki.yaml` in the root of our codebase:

```
image:
  build:
    name: hello-world
    dockerfile: Dockerfile

mount: /mnt
    
init:
   - echo 'Welcome to the hello-world build container'
```

We can then simply run `floki` from a shell, and `floki` takes care of building the docker image, and dropping us into the shell in the mounted working directory. It even prints out the friendly greeting from the `init` section - in practice it's nice to print some basic usage instructions here, for example, instructions for how to build a project, or run tests.

# More wins

Although this seems small, the ergonomics are already much better. Regardless, `floki` gives us more for free.

## docker-in-docker

If our docker container has the docker command line tools (or some other way to interact with a docker daemon), we can get docker-in-docker support by adding

```
dind: true
```

to our `floki.yaml`.

## SSH agent forwarding

`floki` lets you forward your SSH agent. This can be useful if you want to pull libraries from a private `git` server for a build, or if you want to configure a dockerized environment for SSHing into virtual machines (maybe you want to run `fabric` or `ansible` from inside the container).

You can enable this by adding

```
forward_ssh_agent: true
```

to your `floki.yaml`.

## Build-caches with `floki` volumes

Losing cached build artifacts between runs of build containers is annoying, especially if you have to compile them from source. `floki` lets you attach volumes (which can even be shared among different containers) to use as a build cache.

Here is an example for caching Rust artifacts

```
image: ekidd/rust-musl-builder
mount: /home/rust/src
forward_ssh_agent: true
shell: bash
volumes:
  registry:
    mount: /home/rust/registry
```

By default, each the volume is localised to a particular project (that is, the folder and filename for the `floki` configuration file). The `shared: true` key can be added to the `volume` key to use the same volume across all other projects with the same volume name (`registry` in the example above) and with the `shared` key set to true. In the example above, this would mean all rust containers with the `shared` `registry` volume will share the same volume. Combine this with a caching solution on the backing directory and you have a cross company build cache.

# Conclusion

Creating reproducible build environments makes reliable builds easier to achieve. [floki](https://github.com/Metaswitch/floki) makes doing this more ergonomic, and lowers the barrier to doing so, and makes it easier to share with other developers.

There is more than just the above - check out [the floki GitHub page for more](https://github.com/Metaswitch/floki).
