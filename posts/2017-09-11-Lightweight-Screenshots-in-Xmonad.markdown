---
title: Lightweight screenshots in Xmonad
---

## Introduction

Xmonad does not come with any kind of screenshot tool (or anything at all much, which in my view is a good thing - what it does do it does well). I didn't want a heavyweight system (something taken from GNOME or XFCE), but wanted some flexibility still. I made a little script which straps together `rofi`, `slop`, `maim` and `xclip` to provide a lightweight and flexible screenshotting tool. I'm posting it here for anyone who is looking for something similar. Add a keybinding in `xmonad` and off you go! Of course, this will work perfectly well with other window managers too. 

I wanted to be able to do a combination of the following things
 1. Capture the whole screen
 2. Capture just a section of the screen
 3. Possibly capture to clipboard
 4. Possibly capture to file
selectable quickly and easily from some kind of popup menu.

I decided to bind this script to `Mod-PrintScr`, with `PrintScr` bound to `maim -s -c 1,0,0,0.6 --format png /dev/stdout | tee ~/.screenshots/$(date +%F-%T).png | xclip -selection clipboard -t image/png -i` (capture selection to file and clipboard), a default of sorts.

## The script explained

The script is presented below. It is also available [here](https://github.com/rlupton20/dotfiles/blob/master/scripts/super-screenshot.sh). I imagine most people would want to modify it/rewrite it/use it as a basis for their own systems. Chances are, if you like using a tiler, you long lost interest in keeping to "sensible defaults". Tweak away!

`maim` is the main tool here for making screenshots. It can use `slop` in the background to do selections. `xclip` provides a way to get captures onto the clipboard. I wanted several options to be selectable when making a screenshot, so I encoded these options in a slightly horrible way into the script (see `OPTIONS`). The script breaks these down into actual option names that can be fed to `rofi` (a `dmenu` like tool - you could use `dmenu`) using fairly standard *nix sorcery, then uses the selection to extract the parameters from `OPTIONS` before making the screenshot.

We use `/dev/null` as a file when we don't want to actually save to file, and when we do, we create a new file in `SCREENSHOT_DIR` (with a datestamp) to store the capture in. When we don't want to save to clipboard, we pipe the capture into `xclip -h`, the help command for `xclip`. Massive hack, but it works.

## Source

```bash
#!/usr/bin/env bash

# DEPENDENCIES
# rofi, maim, slop, xclip

SCREENSHOT_DIR=~/.screenshots

# Options are separated by ;, with each field separated by :
# FIELD 0: name
# FIELD 1: maim switches
# FIELD 2: save to file
# FIELD 3: put on clipboard
OPTIONS='select:"-c 1,0,0,0.6 -s":y:y;window:"-c 1,0,0,0.6 -st 9999999":y:y;screen:"":y:y;clip:"-c 1,0,0,0.6 -s":n:y'

function get_maim_switches {
    echo $(echo $OPTIONS | tr ';' '\n' | grep ^${1} | awk -F ':' '{print $2}' | xargs echo)
}

function get_save {
    echo $(echo $OPTIONS | tr ';' '\n' | grep ^${1} | awk -F ':' '{print $3}' | xargs echo)
}

function get_clip {
    echo $(echo $OPTIONS | tr ';' '\n' | grep ^${1} | awk -F ':' '{print $4}' | xargs echo)
}


# Get user choice
CHOICE=$(echo $OPTIONS | tr ';' '\n' | awk -F ':' '{print $1}' | rofi -dmenu)

# Extract maim switches
MAIM_SWITCHES=$(get_maim_switches $CHOICE)

# Determine where to save the screenshot (possibly /dev/null)
TO_SAVE=$(get_save $CHOICE)
if [[ $TO_SAVE == y ]]
then
    SAVE_FILE=${SCREENSHOT_DIR}/$(date +%F-%T).png;
else
    SAVE_FILE=/dev/null
fi

# Determine whether to add to clipboard
TO_CLIP=$(get_clip $CHOICE)
if [[ $TO_CLIP == y ]]
then
    CLIP="-selection clipboard -t image/png -i"
else
    CLIP="-h" # Hack hack hack (pipe into help)
fi

# Do the screenshot
maim $MAIM_SWITCHES --format png /dev/stdout | tee $SAVE_FILE | xclip $CLIP
```
