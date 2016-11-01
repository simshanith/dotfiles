#!/usr/bin/env bash

# requires GNU `dircolors` + `ls`
# `brew install coreutils`

# https://github.com/seebi/dircolors-solarized
if hash gdircolors 2>/dev/null; then
  eval `gdircolors ~/.dircolors`
elif hash dircolors 2>/dev/null; then
  eval `dircolors ~/.dircolors`
fi
