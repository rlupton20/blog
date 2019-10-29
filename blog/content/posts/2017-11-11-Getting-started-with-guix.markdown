---
title: Getting started with GuixSD
draft: true
---

In progress: A collection of tips for getting started with and using GuixSD.

# Automatically loading environment variables in the shell

As you install more packages with GuixSD, it requires more environment variables to be set in order that programs load correctly. This is in contrast to Nix, which seems to manage this automatically. As a first solution, adding the following to your `.bashrc` automatically exports the correct environment variables. I'm not yet happy with this solution, and I print out the commands just to check nothing bad is happening. This solution potentially also requires re-sourcing `.bashrc` when new packages are installed. Ugly still, but better than copying and pasting in the output every time a package is installed which requires an updated environment.

```bash
echo "Setting guix paths:"
while read -r variable
do
  EXISTING=$(echo $variable | sed -n 's/export\ \([^=]*\).*/$\1/p')
  CMD=$(echo ${variable}:${EXISTING})
  echo $CMD
  eval $CMD
done <<< "$(guix package --search-paths)"
```

A better solution would be to construct a file to source for each generation, and a) patch guix to source this for every shell and b) always reset the environment whenever a generation changes. I may implement this and try and get it added upstream at a later date.
