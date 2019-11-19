---
title: "Getting decent font rendering on stock Debian"
date: 2019-11-19T00:26:54Z
---

I recently converted one of my machines from a parabola installation to a Debian 10 system. I started from a text only interface - the bare minimum of packages - and installed the rest by hand. For reasons that aren't entirely clear, the default font rendering is pretty hideous. It took me a while to track down how to properly configure font rendering. Perhaps this isn't an issue for installs which include a desktop from the get go. If it is, maybe this can help. While I did this on Debian, there isn't much Debian specific - I've opted for the text file editing approach to configuration instead of strange menu-driven or ncurses stuff. This allows me to version the configuration or do automation work later.

# The very short version

Enter the following into `/home/user/.config/fontconfig/fonts.conf`.

```xml
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>

  <!-- Enable antialiasing for all fonts -->
  <match target="font">
    <edit mode="assign" name="antialias">
      <bool>true</bool>
    </edit>
  </match>

</fontconfig>
```

Restart an application (firefox, virtual terminal) to see the changes. For me, just adding anti-aliasing to font rendering made all the difference. There are more dials to tune, but this was enough to make the font rendering passable.

# Beginning the art and craft of debugging fonts

I don't know why fonts remain such a painful part of the linux experience. Perhaps it's just me, but figuring out what's going on, and how to configure the font rendering isn't at all obvious. As such, I thought I'd make a list for my future self of tools to use to help determine what is going on.

- `fc-conflist` lists all the files which are read to determine font configuration.
- `xterm` launched from a terminal usefully prints out some errors in font configuration (e.g. unrecognised entries). There ought to be a better way than this, but I don't know it (I discovered this by accident).
- `fc-cache` builds font information caches.
- `fc-list` lists all fonts on the system.

Using these together with restarting a test application can help get the fonts to render as you would like.

I also noticed taking screenshots was well worthwhile, or at least doing a side-by-side comparison of different settings. I thought my settings had made one program render very strangely compared to previous settings, but direct comparison showed no difference! In fact, anti-aliasing was the only change I made where I could tell the difference in the font rendering (it's possible all other settings I tried were already set in the other configuration files). Now text doesn't look like total garbage.

At a future point, when I can find the will to do it, I'll tune the rendering further still, and expand these notes.
