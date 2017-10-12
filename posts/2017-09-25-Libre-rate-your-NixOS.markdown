---
title: Libre-rate your NixOS
---

NixOS isn't a libre distribution by any means, but it comes close, and maintains a clear distinction between free and non-free packages (and in fact, different license types). This makes it possible to configure the system to exclude non-free packages, and with the addition of a libre kernel, allows us to turn NixOS into a libre platform. Of course, this isn't the same as leveraging an FSF endorsed distribution, but for those who are happy to maintain and take responsibility for the software running on their systems, it's as good. In fact, it's a little strange that the process of deblobbing normal systems isn't better documented and more widely done, after all, this is exactly what a libre distribution typically is. If you want a libre system out of the box, with nix-y functionality, GuixSD is also worth a look, but I really like NixOS, and I thought it worth the effort to libre-up.

By default, most non-free packages can't be installed on nixos without explicitly allowing unfree packages. There are a couple of places however where non-free software can be installed. The first is in the standard linux kernel, so our first job is to rebase our system on top of a libre linux build. NixOS does allows packages with the license type `unfreeRedistributableFirmware`, so the remainder of the work consists of blacklisting this license type.

# Installing a libre kernel

The default linux kernel comes with all the binary blobs typically packaged with the linux kernel. NixoOS makes it easy to specify a custom kernel in `/etc/nixos/configuration.nix`.

There are three stages to installing a custom kernel build:
  - Generate/obtain a kernel build configuration file
  - Write the build expression into `configuration.nix`
  - Testing

Nix will take care of building and installing the kernel for us. It also makes it trivial to reproduce once we've got the setup we want. Upgrades can be achieved just by updating the source package being pulled.

Building a kernel takes a little time, so if this is being done on a lot of machines (and once you've got it working as you like), you may want to set up a custom repository and binary cache for your built kernel, and use this in your `configuration.nix`. [This article](http://sandervanderburg.blogspot.co.uk/2016/10/push-and-pull-deployment-of-nix-packages.html) should help with this, and provide other options for deployment.

## Obtaining your current configuration

We can obtain the configuration file used to build the current kernel using `zcat /proc/config.gz`. Let's store this in a file alongside `configuration.nix` and use it to build our libre kernel.

```bash
$ zcat /proc/config.gz | sudo tee /etc/nixos/kernel.config
```

At a later point you could customize this file to adjust the kernel to your needs, or run the configuration tools bundled with the libre kernel to generate a configuration file completely customized to your needs. The above approach however will do to get started.

## Specifying our new kernel

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

## Building and testing

Run `nixos-rebuild switch` to instantiate your new configuration. You can try out your new kernel and test it works easily, and if there are problems boot into the old working kernel from the bootloader (another nix win). You can roll back to your old configuration with `nixos-rebuild switch --rollback`.

# Blacklisting unwanted licenses

`nixpkgs` can be configured to blacklist certain license types. The [license definition file](https://github.com/NixOS/nixpkgs/blob/master/lib/licenses.nix) lists all the licenses used in all the packages in nix. Anything with `free = false;` is recognized as a non-free package by nix, and can't be installed unless non-free packages are explicitly enabled. However, there are non-free licenses without this label. `unfreeRedistributableFirmware` is non-free yet doesn't have this label. To help avoid inadvertantly installing these kinds of packages, we need to blacklist this license (along with any others we want to avoid).

## System level

The following snippet, added to `configuration.nix` will do the job.

```
{ config, pkgs, lib, ... }:
{

  . 
  .
  .

# Block any unfree firmware (which isn't in the kernel)
  nixpkgs.config = {
    blacklistedLicenses = with lib.licenses; [
      unfreeRedistributableFirmware
    ];
  };

  .
  .
  .
};
```

It's also possible to specify a license whitelist, with the option `whitelistedLicenses`.

## User level

`nixpkgs` configuration at the system level isn't reflected for the users, so users will still by default be able to install non-free packages. User `nixpkgs` need to be configured separately. At present, the best way to do this is to add

```
{
  blacklistedLicenses = with stdenv.lib.licenses; [
	unfreeRedistributableFirmware
  ];
}
```

to `~/.config/nixpkgs/config.nix`. The [nixpkgs manual](https://nixos.org/nixpkgs/manual/#chap-packageconfig) contains information here that's useful.

If you use a manifest to install packages, you can add these configuration options to your import of `nixpkgs`. For example:

```
  # Define pkgs as <nixpkgs> with some licenses
  # blacklisted
  pkgs = import <nixpkgs> {
    config = {
      blacklistedLicenses = with _licenses; [
        unfreeRedistributableFirmware
      ];
    };
  };
```

Currently, there doesn't seem to be a way to add a system wide default for user nixpkgs configuration in the absence of an explicit configuration file, which is unfortunate. This works reasonably, in the meantime, and since firmware is the only non-free software available to users by default, is not as bad as it might seem.
