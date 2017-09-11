---
title: Lightweight screenshots in Xmonad
---

# Introduction

Xmonad does not come with any kind of screenshot tool. I didn't want a heavyweight system (something taken from GNOME or XFCE), but wanted some flexibility still. I made a little script which straps together``rofi`, `slop`, `maim` and `xclip` to provide a lightweight and flexible screenshotting tool. Add a keybinding in `xmonad` and off you go!

I wanted to be able to do a combination of the following things
 - Capture the whole screen
 - Capture just a section of the screen
 - Possibly capture to clipboard
 - Possibly capture to file


# The script explained

The script is presented below. It is also available [here](https://github.com/rlupton20/dotfiles/blob/master/scripts/super-screenshot.sh).

`maim` is the main tool here for making screenshots. It can use `slop` in the background to do selections. `xclip` provides a way to get captures onto the clipboard. I wanted several options to be selectable when making a screenshot, so I encoded these options in a slightly horrible way into the script (see `OPTIONS`). The script breaks these down into actual option names that can be fed to `rofi` (a `dmenu` like tool - you could use `dmenu`) using fairly standard *nix sorcery, then uses the selection to extract the parameters from `OPTIONS` before making the screenshot.

We use `/dev/null` as a file when we don't want to actually save to file, and when we do, we create a new file in `SCREENSHOT_DIR` (with a datestamp) to store the capture in. When we don't want to save to clipboard, we pipe the capture into `xclip -h`, the help command for `xclip`. Massive hack, but it works.

# The script

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
