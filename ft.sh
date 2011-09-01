#!/usr/bin/env bash

# The following function (replace_path) is lifted directly from an SO post by the user Jonathan Leffler here:
# http://stackoverflow.com/questions/273909/how-do-i-manipulate-path-elements-in-shell-scripts
# ---------------------------------------------- BEGIN -------------------------------------------------------

# Usage:
#
# To replace a path:
#    replace_path         PATH $PATH /exact/path/to/remove /replacement/path
#
###############################################################################

# Remove or replace an element of $1
#
#   $1 name of the shell variable to set (e.g. PATH)
#   $2 a ":" delimited list to work from (e.g. $PATH)
#   $3 the precise string to be removed/replaced
#   $4 the replacement string (use "" for removal)
replace_path() {
  local path=$1
  local list=$2
  local remove=$3
  local replace=$4 # Allowed to be empty or unset
  export $path="$(echo "$list" | tr ":" "\n" | sed "s:^$remove\$:$replace:" | tr "\n" ":" | sed 's|:$||')"
}

# ---------------------------------------------- END ---------------------------------------------------------

if [[ -z "$RUBIES" ]]; then
  echo '$RUBIES must be set to use flip-the-tables.'
  return 1
fi

if [[ -n "$GEM_HOME" || -n "$GEM_PATH" ]]; then
  echo '$GEM_HOME and $GEM_PATH should not be set if you use flip-the-tables'
  return 1
fi

# Get the full list of versions
_ft_ruby_list() {
  echo $(for f in $(find "$RUBIES" -type d -d 1); do basename "$f"; done)
}

# Swap out ruby versions by replacing $RUBIES/<ruby1>/bin with $RUBIES/<ruby2>/bin
_ft_set_ruby() {
  local current=$1
  local pattern=$2
  local ruby=( $(find "$RUBIES" -type d -d 1 -name "${pattern}*") )
  if [[ ${#ruby[@]} -eq 0 ]]; then
    echo "Error: No ruby matched $pattern."
  elif [[ ${#ruby[@]} -gt 1 ]]; then
    echo "Error: ambiguous ruby \"$pattern\": the following rubies all matched"
    local r
    for r in ${ruby[@]}; do
      basename "$r"
    done
  elif [[ "$(dirname "$current")" != "${ruby[0]}" ]]; then
    echo -e "\033[01;32mSwitching to ruby $(basename "$ruby").\033[39m"
    replace_path PATH "$PATH" "$current" "$ruby/bin"
  fi
}

_ft_help() {
  echo 'flip-the-tables: easily switch ruby paths around.'
  echo 'Usage: ft [version|version-short|list|<ruby-version>]'
  echo 'The tab-completion should be a good hint :)'
}

shopt -s progcomp

_ft_complete_list() {
  local option
  for option in $(_ft_ruby_list); do echo "$option"; done
  for option in version short-version list help; do echo $option; done
}

_ft_completion() {
  COMPREPLY=()
  local current_word=${COMP_WORDS[COMP_CWORD]}
  COMPREPLY=($(compgen -W '$(_ft_complete_list)' -- $current_word))
  return 0
}

ft() {
  if [[ "$#" -ne 1 ]]; then
    _ft_help
  else
    local current=$(echo "$PATH" | tr ":" "\n" | grep -m 1 "^$RUBIES/.*/bin/\?\$")
    local current_short=$(basename $(dirname "$current"))
    if [[ -z "$current" ]]; then
      echo 'Error: not currently using Ruby in $RUBIES.'
    else
      case "$1" in
        help) _ft_help
          ;;
        version) echo "Current Ruby: $current_short"
          ;;
        short-version) printf "$current_short"
          ;;
        list)
          local ruby
          for ruby in $(_ft_ruby_list); do
            if [[ "$current_short" = "$ruby" ]]; then
              echo "* $ruby"
            else
              echo "  $ruby"
            fi
          done
          ;;
        *) _ft_set_ruby "$current" "$1"
          ;;
      esac
    fi
  fi
}

complete -F _ft_completion ft
