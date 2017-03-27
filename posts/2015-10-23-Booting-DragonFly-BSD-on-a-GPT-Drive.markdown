---
title: Booting DragonFly BSD with HAMMER on a GPT drive
---

Here I’ll outline how I managed to get DragonFly BSD to boot from a single slice (Linux: partition) by chainloading the DragonFly bootloader boot1.

Note: for clarity’s sake, I’ll stick to the BSD terminology here. Slice refers to what Linux would dub a partition, and partition refers to a Linux “partition of a partition”. Linux’s `sda1` would therefore be slice `0` of disk `sda` (BSD counts from `0`), which on my BSD system is denoted `da0s0` (disk 0 slice 0 – first disk first slice).

# Introduction

So first a little background. DragonFly BSD comes with a simple installer that works very well if your disk has an MBR partition table, or takes up the entire disk. The kernel is GPT compatible but the bootloader is not (inspection of the boot1 source code reveals it is exclusively MBR based). This need not be a problem if DragonFly is your only system, or you’re happy with MBR and DragonFly’s boot0 bootloader.

However, GPT offers many advantages, especially if you would like to dual boot alongside a linux installation, with plenty of slices. I wanted to dual boot alongside Arch linux, and bootload with GRUB2. This is what I’ll outline below.

One straightforward way to get this to work is to accept UFS partitions for DragonFly, loading the DragonFly kernel directly using GRUB. However, one of the attractions of DragonFly is its filesystem HAMMER, and unfortunately, unlike UFS, GRUB does not understand HAMMER.

The automatic installer installs DragonFly to one slice with three partitions. A small boot partition of type UFS, a swap partition, and the rest of type HAMMER. HAMMER allows for a series of pseudofilesystems, which incorporate the classic UNIX `/var`, `/usr` `/home` (and so on). This is the setup I wanted to achieve. However, the automatic installer doesn’t work with GPT format partition tables.

## Proceed with installations

First I installed Arch. The Arch documentation is good and suffices for the install. Its worth noting that despite using GPT, my system was running a BIOS, and not the more modern UEFI. I haven’t tested this with UEFI, and I don’t have a machine to try it with (which I’m willing to risk). Arch is easy to use to partition the drive with GPT, and a small (1MB) partition can be added at the start to install GRUB to for BIOS/GPT compatibility. The Arch documentation makes it clear how to do this. Of course, leave space for the DragonFly installation. I left ~70GB at the end of the drive.

Next install DragonFly. This must proceed manually, because the automatic installer won’t work for GPT. An invaluable guide which I initially overlooked is the readme file. Drop a directory (cd ..) and then you’ll find it – more README. This gives you a guide to manual installation. This and reading the man files ought to get you through the install, but here are a few notes. The entire process is not particularly complicated, and is not unlike installing Arch. There are a few differences, and its worth reading around the process a bit to familiarise yourself.

Add your DragonFly slice where you want it using the gpt tool (“man gpt” for details). You might need to feed it the start block (and possibly other parameters) to get it in the right place, because with GPT the first bit of free space is a tiny slot at the start of the disk. You just need one slice. Partitions of this will do the rest.

My DragonFly slice was the sixth GPT slice, so DragonFly names that da0s5. I’ll use this below. Adjust as necessary for your setup.

Don’t install `boot0` (no `boot0cfg` commands!), but do install bootblocks to the slice with:

```
disklabel64 -B da0s5
```

This installs boot1/boot2 to the start of the slice. This is essential for chainloading, because GRUB will pass control to these boot blocks.

The disklabel was set to mimic that of the automatic installer, an `a` partition mounted `/boot` of type `UFS` (in the label BSD4.2), `b` of type swap, and `d` of type HAMMER, mounted as `/`. I essentially mimicked the arrangement found here: https://www.dragonflybsd.org/docs/newhandbook/environmentquickstart/#index2h2. The README file and disklabel manual should suffice to set this up.

Then format your partitions, mount them (as per README), and create the pseudofilesystems (PFSs), and mount them. cpdup everything in to place and tidy up.

Editing the example fstab file proved to be hassle with a tempermental vi, so I wrote one from scratch, mimicking that displayed in: https://www.dragonflybsd.org/docs/newhandbook/environmentquickstart/#index2h2 (look for the `cat /etc/fstab` output – personally, however, I chose to softlink `/var/tmp` to `/tmp` also – the README here has a mistake, it links `/mnt/var/tmp` to `/tmp` instead of `/mnt/tmp` – this would create a link to the install media!).

The instructions will ask you to reboot. You can if you like. It is easy to boot back in to the install media and make the changes to get the system to boot. You won’t need drives mounted. One thing you might like to do is attempt chainloading in the current state (use the GRUB configuration detailed below), and confirm you get “Boot Error” as your error message. The following trick will fix this.

Tricking `boot1` – making your system boot

Now for the trick. If we were to chainload `(hd0, gpt6)`, which is GRUBs view of `da0s5`, we would get a “Boot Error” from `boot1`. This is because `boot1` looks for an MBR, and then looks for a BSD partition, from which it tries to boot. At the moment it won’t find DragonFly, because its slice is recorded in the GPT, which `boot1` does not understand.

However, if `boot1` was finding no MBR, it would return a “Read Error” (one needs to read the source code to discover this). So `boot1` must find an MBR. Where? In fact GPT specifies the existence of a “Protective MBR” for compatibility with MBR and BIOS systems. This is what `boot1` finds. You can view this (from the install media) with:

`fdisk da0`

This should show you the contents of the protective MBR, and it should show you the slice one is the entire disk, and the rest (2-4) are unused. This is so MBR systems do not think there is free space on the disk, when in actual fact GPT is managing it. The protective MBR of course occupies the same position on the disk as a normal MBR.

`boot1` needs no more information than where to find DragonFly. Furthermore, `boot2` makes use of the disklabel, and doesn’t use the information which `boot1` gathers from the MBR, so we can write entries to the protective MBR without fear of the effect of these entries propagating too far. There is also nothing to stop us writing overlapping entries to this MBR either, using fdisk for example. So what we do is add a new entry to the protective MBR, which points to the `da0s5`, so that `boot1` can find it, and begin booting the rest of the system.

First run `gpt show da0`, and note down the start block and size (in blocks) of your DragonFly slice. Now run “fdisk -u da0”, leaving the first slice as is, but updating the second slice to be of type `165` (BSD’s type, and the one boot1 is looking for), and enter the start block you noted down, and also the size. Leave 3 and 4 unaltered and write this to the table. You can now chainload!

With this modification, `boot1` reads the protective MBR and finds an entry pointing to DragonFly (as if DragonFly were installed on a genuine MBR). This is enough to kickstart the system. Since the kernel has GPT compatibility, it sees the DragonFly partition as da0s5 as it should on a genuine GPT system. In fact, once boot1 has done its work, the rest of the system loads as if it were booted directly from the GPT format partition table.

Of course, if the GPT slice for DragonFly is moved, the protective MBR also requires updating. GPT compatibility of the bootloader is a much more desirable solution, but this is a simple and usable workaround for now. luxh on #dragonflybsd has pointed out that the tool “gptsync” can be used to help synchronise entries from the GPT with the MBR. Presumably, other people have used similar tricks elsewhere!

GRUB2 configuration

Just to be clear, my GRUB configuration file (`/etc/grub.d/40_custom`), has as entry

```
menuentry “DragonFly BSD” {

setroot=(hd0,gpt6)

chainloader +1

}
```

A standard chainloader configuration. Install with `grub-mkconfig -o /boot/grub/grub.cfg`, from linux, or wherever it’s installed (`update-grub` if you are using *buntu).

## Acknowlegments

Thanks goes to the members of the #dragonflybsd irc channel for helping me eliminate possible causes of booting issues, providing insight into the current limitations of the boot system, and providing some encouragement for finding this solution.

