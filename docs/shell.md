---
locale: en
tags:
  - app:immosquare-cleaner
  - audience:technique
---

# Shell script formatting with shfmt

immosquare-cleaner formats shell scripts and shell configuration files with [shfmt](https://github.com/mvdan/sh), using a 2-space indent. This page lists the files concerned, what shfmt changes, and how to install it.

## Which shell files are formatted

The shell processor matches files by the end of their name, so dotfiles are covered as well as scripts:

| Matched name ending | Typical files                          |
| ------------------- | -------------------------------------- |
| `.sh`               | `deploy.sh`, `bin/setup.sh`            |
| `bash`, `zsh`       | `script.bash`, `config.zsh`            |
| `bashrc`, `zshrc`   | `.bashrc`, `.zshrc`                    |
| `bash_profile`      | `.bash_profile`                        |
| `zprofile`          | `.zprofile`                            |

An executable script without an extension is only matched when it is a Ruby script (`#!/usr/bin/env ruby`), which goes to RuboCop. A shell script without an extension is not recognized as shell: a repository clean skips it, so give it a `.sh` extension to have it formatted.

## What shfmt changes in a shell script

shfmt runs with `-i 2 -w`: it reindents the script with 2 spaces and rewrites it in place. It also normalizes spacing around redirections and keywords, and the cleaner makes sure the file ends with exactly one newline.

```diff
 #!/bin/bash
 if [ -z "$1" ]; then
-    echo "usage: deploy.sh <env>"
-        exit 1
+  echo "usage: deploy.sh <env>"
+  exit 1
 fi
 for host in $(cat hosts.txt); do
   ssh $host "sudo systemctl restart app"
 done
```

shfmt only formats: it does not quote variables or flag unsafe constructs. Pair it with [ShellCheck](https://www.shellcheck.net/) for that.

Install shfmt with `brew install shfmt`. When it is missing, immosquare-cleaner prints that command and leaves shell files as they are.
