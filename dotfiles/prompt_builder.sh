#!/bin/bash
# Bash PS1 builder
#
# Author: Synergiance

RESET_COLOR="\033[0m"

git_prompt() {
  if ! git rev-parse --git-dir > /dev/null 2>&1;
  then
    return 0
  fi
  echo -ne "\001:$(git branch 2>/dev/null | sed -n '/^\*/s/* //p')"
  if ! git diff --quiet 2>/dev/null >&2;
  then
    echo -ne "*"
  fi
  #echo -ne "\002"
}

pre_prompt() {
  es=$?
  echo -ne "\001"
  if [[ $es -ne 0 ]]
  then
    echo -ne "${es}:"
  fi
  if [[ "$USER" != "root" ]]
  then
    echo -ne "\u@"
  fi
  #echo -ne "\002"
}

PROMPT_COMMAND='PS1="\[${RESET_COLOR}\][$(pre_prompt)\h:\w$(git_prompt)> "'
