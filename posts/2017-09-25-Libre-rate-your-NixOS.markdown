---
title: Libre-rate your NixOS
---

NixOS by default requires you to turn on a special flag in order to use non-free packages. However, the default linux kernel comes with all the binary blobs typically packaged with the linux kernel. NixoOS makes it easy to specify a custom kernel in `/etc/nixos/configuration.nix`, and in particular, we can build a libre kernel free of binary blobs. This effectively let's you turn NixOS into a fully free platform.

Nix will take care of building and installing the kernel for us. It also makes it trivial to reproduce once we've got the setup we want. Upgrades can be achieved just by updating the source package being pulled.

Building a kernel takes a little time, so if this is being done on a lot of machines (and once you've got it working as you like), you may want to set up a custom repository and binary cache for your built kernel, and use this in your `configuration.nix`. [This article](http://sandervanderburg.blogspot.co.uk/2016/10/push-and-pull-deployment-of-nix-packages.html) should help with this, and provide other options for deployment.

# Overview

There are three stages to installing a custom kernel build:
  - Generate/obtain a kernel build configuration file
  - Write the build expression into `configuration.nix`
  - Testing

# Obtaining your current configuration

We can obtain the configuration file used to build the current kernel using `zcat /proc/config.gz`. Let's store this in a file alongside `configuration.nix` and use it to build our libre kernel.

```bash
$ zcat /proc/config.gz | sudo tee /etc/nixos/kernel.config
```

At a later point you could customize this file to adjust the kernel to your needs, or run the configuration tools bundled with the libre kernel to generate a configuration file completely customized to your needs. The above approach however will do to get started.

# Specifying our new kernel

Nix will take care of building our kernel properly. We just need to provide enough details in `configuration.nix`. The following addition to `configuration.nix` provides all we need to build the 4.12.10 linux-libre kernel in NixOS.


```nix
boot.kernelPackages = pkgs.linuxPackages_custom
  version = "4.12.10-gnu";
  src = pkgs.fetchurl {
    url = "http://www.linux-libre.fsfla.org/pub/linux-libre/releases/4.12.10-gnu/linux-libre-4.12.10-gnu.tar.xz";
    sha256 = "122a457b0def2050378359641cce341c4d5f3f3dc70d9c55d58ac82ccfaf361b";
  };
  configfile = /etc/nixos/kernel.config;
}; 
```

# Building and testing

Run `nixos-rebuild switch` to instantiate your new configuration. You can try out your new kernel and test it works easily, and if there are problems boot into the old working kernel from the bootloader (another nix win). You can roll back to your old configuration with `nixos-rebuild switch --rollback`.
