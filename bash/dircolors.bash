#!/usr/bin/env bash

# requires GNU `dircolors` + `ls`
# `brew install coreutils`

# https://github.com/seebi/dircolors-solarized
if [[ -x "$(command -v gdircolors)" ]]; then
  eval `gdircolors ~/.dircolors`
elif [[ -x "$(command -v dircolors)" ]]; then
  eval `dircolors ~/.dircolors`
fi
