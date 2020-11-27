# Bash PS1 builder

# Settings
RESET_COLOR="\033[0m"
GREEN="\033[01;32m"
BLUE="\033[01;34m"
SEPARATOR=""
STAGED="✚"
UNSTAGED="±"
UNTRACKED="?"
IGNORED="!"
AHEAD="↑"
BEHIND="↓"
BRANCH=""
DETATCHED="➦"
ERROR="✘"
BOLT="⚡"
GEAR="⚙"

# Git Variables
staged=0
unstaged=0
untracked=0
ignored=0

repo_path=""
branch_name=""
detached=0
ahead=0
behind=0

# Prompt Variables
wd=""

last_command=0

# [[ "${ref/.../}" == "$ref" ]]

get_git_status() {
  if [[ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" != "true" ]] ; then
    return 0
  fi
  repo_path="$(git rev-parse --git-dir 2>/dev/null)"
  branch_name="$(git branch 2>/dev/null | sed -n '/^\*/s/* //p')"
  commit_tag=$(echo "$branch_name" | grep -Po "(?<=\(HEAD detached at )[a-fA-F0-9]+(?=\))")
  if [[ $? -eq 0 ]] ; then
    detached=1
    branch_name=$commit_tag
  else
    detached=0
  fi
  git_output=$(git status --porcelain=v2 --branch)
  staged=$(echo "$git_output" | grep -c -P "^[12] [MARCD]")
  unstaged=$(echo "$git_output" | grep -c -P "^[12] .[MARCD]")
  untracked=$(echo "$git_output" | grep -c "^\?")
  ignored=$(echo "$git_output" | grep -c "^!")
  tmpabstr=$(echo "$git_output" | grep "^# branch.ab")
  if [ "$tmpabstr" != "" ] ; then
    ahead=$(echo "$tmpabstr" | grep -Po "(?<=\s\+)[0-9]+")
    behind=$(echo "$tmpabstr" | grep -Po "(?<=\s\-)[0-9]+")
  else
    ahead=0
    behind=0
  fi
  if [ $staged -gt 0 ] ; then
    return 5
  fi
  if [ $unstaged -gt 0 ] ; then
    return 4
  fi
  if [ $untracked -gt 0 ] ; then
    return 3
  fi
  if [ $ignored -gt 0 ] ; then
    return 2
  fi
  return 1
}

git_basic_prompt() {
  get_git_status
  git_return=$?
  if [ $git_return -eq 0 ] ; then
    return 0
  fi
  PS1+='\[\e[0m\]:\[\e[01;31m\]'
  PS1+=$branch_name
  if [ $git_return -eq 1 ] ; then
    return 0
  fi
  if [ $staged -gt 0 ] ; then
    PS1+=$STAGED
  fi
  if [ $unstaged -gt 0 ] ; then
    PS1+=$UNSTAGED
  fi
  if [ $untracked -gt 0 ] ; then
    PS1+=$UNTRACKED
  fi
  if [ $ignored -gt 0 ] ; then
    PS1+=$IGNORED
  fi
  if [ $ahead -gt 0 ] ; then
    PS1+="${AHEAD}"
  fi
  if [ $behind -gt 0 ] ; then
    PS1+="${BEHIND}"
  fi
}

git_fancy_prompt() {
  get_git_status
  git_return=$?
  if [ $git_return -eq 0 ] ; then
    PS1+='\[\e[34;49m\]${SEPARATOR}'
    return 0;
  fi
  if [ $git_return -gt 3 ] ; then
    PS1+='\[\e[34;43m\]${SEPARATOR}\[\e[30m\] '
  else
    PS1+='\[\e[34;42m\]${SEPARATOR}\[\e[30m\] '
  fi
  if [ $detached -eq 1 ] ; then
    PS1+="${DETATCHED} "
  else
    PS1+="${BRANCH} "
  fi
  PS1+="${branch_name} "
  if [ $staged -gt 0 ] ; then
    PS1+="${STAGED} "
  fi
  if [ $unstaged -gt 0 ] ; then
    PS1+="${UNSTAGED} "
  fi
  if [ $untracked -gt 0 ] ; then
    PS1+="${UNTRACKED} "
  fi
  if [ $ignored -gt 0 ] ; then
    PS1+="${IGNORED} "
  fi
  if [ $ahead -gt 0 ] ; then
    if [ $behind -gt 0 ] ; then
      PS1+="${AHEAD}${BEHIND} "
    else
      PS1+="${AHEAD} "
    fi
  elif [ $behind -gt 0 ] ; then
    PS1+="${BEHIND} "
  fi
  if [ $git_return -gt 3 ] ; then
    PS1+='\[\e[33;49m\]${SEPARATOR}'
  else
    PS1+='\[\e[32;49m\]${SEPARATOR}'
  fi
}

do_basic_userhost() {
  if [ "$USER" != "root" ] ; then
    PS1+='\[\e[01;32m\]\u@'
  else
    PS1+='\[\e[01;33m\]'
  fi
  PS1+='\h\[\e[0m\]'
}

do_fancy_userhost() {
  if [ "$USER" == "root" ] ; then
    PS1+='\[\e[33m\]${BOLT} \h'
  else
    PS1+='\[\e[32m\]\u@\h'
  fi
}

get_truncated_pwd() {
  wd=$(echo ${PWD/#$HOME/'~'} | grep -Po "(^~(\/[^\/\n]*){0,3}$|^(\/[^\/\n]*){1,3}$|[^\/\n]*(\/[^\/\n]*){2})$")
}

set_basic_prompt() {
  PS1=""                 # Reset PS1
  PS1+='\[\e[0m\]['      # Reset color and start prompt
  if [ $last_command -ne 0 ] ; then
    PS1+='${last_command}:'
  fi
  do_basic_userhost
  PS1+=':\[\e[01;34m\]${wd}'
  git_basic_prompt
  PS1+='\[\e[0m\]> '
}

set_fancy_prompt() {
  PS1=""
  PS1+='\[\e[0m\]\[\e[01;40m\] '
  if [ $last_command -ne 0 ] ; then
    PS1+='\[\e[31m\]${ERROR} ${last_command} '
  fi
  num_jobs=$(jobs -l | wc -l 2>/dev/null)
  if [ $num_jobs -gt 0 ] ; then
    PS1+='\[\e[36m\]${GEAR} ${num_jobs} '
  fi
  do_fancy_userhost
  PS1+=' \[\e[0;30;44m\]${SEPARATOR} ${wd} '
  if [ ${wd:0:1} != "/" ] && [ ${wd:0:1} != "~" ] ; then
    wd="... ${wd}"
  fi
  git_fancy_prompt
  PS1+='\[\e[0m\] '
}

set_prompt() {
  last_command=$? # Stash return value
  get_truncated_pwd
  if [ "${USE_FANCY_PROMPT}" == "true" ] ; then
    set_fancy_prompt
  else
    set_basic_prompt
  fi
}

PROMPT_COMMAND='set_prompt'
