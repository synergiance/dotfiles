# Bash PS1 builder

RESET_COLOR="\033[0m"
GREEN="\033[01;32m"
BLUE="\033[01;34m"
SEPARATOR=""
STAGED="✚"
UNSTAGED="±"
UNTRACKED="*"
BRANCH=""
DETATCHED="➦"
ERROR="✘"
BOLT="⚡"
GEAR="⚙"

staged=0
unstaged=0
untracked=0
repo_path=""
branch_name=""

last_command=0

# [[ "${ref/.../}" == "$ref" ]]

get_git_status() {
  if [[ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" != "true" ]] ; then
    return 0
  fi
  repo_path="$(git rev-parse --git-dir 2>/dev/null)"
  branch_name="$(git branch 2>/dev/null | sed -n '/^\*/s/* //p')"
  readarray -t git_changes <<< $(git status --porcelain --ignore-submodules) #$(
  staged=0
  untracked=0
  unstaged=0
  if [[ ${#git_changes[@]} -eq 0 ]] ; then
    return 1
  fi
  for git_change in "${git_changes[@]}"; do
    if [[ $(expr length "${git_change}") -lt 2 ]] ; then
      continue
    fi
    stage_bit="${git_change:0:1}"
    unstage_bit="${git_change:1:1}"
    if [[ "${stage_bit}" == "?" ]] ; then
      untracked=$((untracked+1))
      continue
    fi
    if [[ "${stage_bit}" != " " ]] ; then
      staged=$((staged+1))
    fi
    if [[ "${unstage_bit}" != " " ]] ; then
      unstaged=$((unstaged+1))
    fi
  done
  if [[ $staged -gt 0 ]] ; then
    return 4
  fi
  if [[ $unstaged -gt 0 ]] ; then
    return 3
  fi
  if [[ $untracked -gt 0 ]] ; then
    return 2
  fi
  return 1
}

git_basic_prompt() {
  get_git_status
  git_return=$?
  if [[ $git_return -eq 0 ]] ; then
    return 0
  fi
  PS1+='\[\e[0m\]:\[\e[01;31m\]'
  PS1+=$branch_name
  if [[ $git_return -eq 1 ]] ; then
    return 0
  fi
  if [[ $staged -gt 0 ]] ; then
    PS1+=$STAGED
  fi
  if [[ $unstaged -gt 0 ]] ; then
    PS1+=$UNSTAGED
  fi
  if [[ $untracked -gt 0 ]] ; then
    PS1+=$UNTRACKED
  fi
}

git_fancy_prompt() {
  get_git_status
  git_return=$?
  if [[ $git_return -eq 0 ]] ; then
    PS1+='\[\e[34;49m\]${SEPARATOR}'
    return 0;
  fi
  if [[ $git_return -gt 2 ]] ; then
    PS1+='\[\e[34;43m\]${SEPARATOR}\[\e[30m\] '
  else
    PS1+='\[\e[34;42m\]${SEPARATOR}\[\e[30m\] '
  fi
  PS1+="${BRANCH} ${branch_name} "
  if [[ $staged -gt 0 ]] ; then
    PS1+="${STAGED} "
  fi
  if [[ $unstaged -gt 0 ]] ; then
    PS1+="${UNSTAGED} "
  fi
  if [[ $untracked -gt 0 ]] ; then
    PS1+="${UNTRACKED} "
  fi
  if [[ $git_return -gt 2 ]] ; then
    PS1+='\[\e[33;49m\]${SEPARATOR}'
  else
    PS1+='\[\e[32;49m\]${SEPARATOR}'
  fi
}

do_basic_userhost() {
  if [[ "$USER" != "root" ]] ; then
    PS1+='\[\e[01;32m\]\u@'
  else
    PS1+='\[\e[01;33m\]'
  fi
  PS1+='\h\[\e[0m\]'
}

do_fancy_userhost() {
  if [[ "$USER" == "root" ]] ; then
    PS1+='\[\e[33m\]${BOLT} \h'
  else
    PS1+='\[\e[32m\]\u@\h'
  fi
}

set_basic_prompt() {
  PS1=""                 # Reset PS1
  PS1+='\[\e[0m\]['      # Reset color and start prompt
  if [[ $last_command -ne 0 ]] ; then
    PS1+='${last_command}:'
  fi
  do_basic_userhost
  PS1+=':\[\e[01;34m\]\w'
  git_basic_prompt
  PS1+='\[\e[0m\]> '
}

set_fancy_prompt() {
  PS1=""
  PS1+='\[\e[0m\]\[\e[01;40m\] '
  if [[ $last_command -ne 0 ]] ; then
    PS1+='\[\e[31m\]${ERROR} ${last_command} '
  fi
  num_jobs=$(jobs -l | wc -l 2>/dev/null)
  if [[ $num_jobs -gt 0 ]] ; then
    PS1+='\[\e[36m\]${GEAR} ${num_jobs} '
  fi
  do_fancy_userhost
  PS1+=' \[\e[0;30;44m\]${SEPARATOR} \w '
  git_fancy_prompt
  PS1+='\[\e[0m\] '
}

set_prompt() {
  last_command=$? # Stash return value
  if [[ "${USE_FANCY_PROMPT}" == "true" ]] ; then
    set_fancy_prompt
  else
    set_basic_prompt
  fi
}

PROMPT_COMMAND='set_prompt'
