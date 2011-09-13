#!/bin/sh

# The following function (replace_path) is lifted from an SO post by the user Jonathan Leffler here:
# http://stackoverflow.com/questions/273909/how-do-i-manipulate-path-elements-in-shell-scripts
# ---------------------------------------------- BEGIN -------------------------------------------------------

# Usage:
#
# To replace a path:
#    replace_path         PATH $PATH /exact/path/to/remove /replacement/path
#
###############################################################################

# Remove or replace an element of $PATH
#
#   $1 a ":" delimited list to work from (e.g. $PATH)
#   $2 the precise string to be removed/replaced
#   $3 the replacement string (use "" for removal)
replace_path() {
  local list="$1"
  local remove="$2"
  local replace="$3" # Allowed to be empty or unset
  export PATH="$(echo "$list" | tr ":" "\n" | sed "s:^$remove\$:$replace:" | tr "\n" ":" | sed 's|:$||')"
}

# ---------------------------------------------- END ---------------------------------------------------------

if [[ -n "$BASH_VERSION" ]]; then
  export _ft_shell_bash=1
elif [[ -n "$ZSH_VERSION" ]]; then
  export _ft_shell_zsh=1
else
  echo "Only bash and zsh are supported."
  return 1
fi

if [[ -z "$RUBIES" ]]; then
  echo '$RUBIES must be set to use flip-the-tables.'
  return 1
fi

if [[ -n "$GEM_HOME" || -n "$GEM_PATH" ]]; then
  echo '$GEM_HOME and $GEM_PATH should not be set if you use flip-the-tables'
  return 1
fi

if [[ -z "$FT_DEFAULT_RUBY" ]]; then
  echo '$FT_DEFAULT_RUBY must be set to use flip-the-tables.'
  return 1
fi

# Push the flip-the-tables ruby to the front of the path
_ft_default_ruby=( $(find "$RUBIES" -maxdepth 1 -type d -name "${FT_DEFAULT_RUBY}*") )
if [[ ${#_ft_default_ruby[@]} -eq 0 ]]; then
  echo "Error: the default ruby \$FT_DEFAULT_RUBY ($FT_DEFAULT_RUBY) doesn't match any known rubies."
  return 1
elif [[ ${#_ft_default_ruby[@]} -gt 1 ]]; then
  echo "Error: the default ruby \$FT_DEFAULT_RUBY ($FT_DEFAULT_RUBY) is ambiguous: it matches each of"
  for r in "${_ft_default_ruby[@]}"; do echo "$r"; done
  return 1
fi
(( $_ft_shell_bash )) && export PATH="${_ft_default_ruby[0]}/bin:$PATH"
(( $_ft_shell_zsh )) && export PATH="${_ft_default_ruby[1]}/bin:$PATH"

# Get a usable readlink
export _ft_readlink=readlink
(${_ft_readlink} -f . > /dev/null 2>&1) || export _ft_readlink=greadlink
(${_ft_readlink} -f . > /dev/null 2>&1) || export _ft_readlink=""
if [[ -z "${_ft_readlink}" ]]; then
  echo "Error: no usable readlink found."
  echo
  echo "If you are on Mac OS X, install greadlink:"
  echo '$ brew install coreutils'
  echo "or"
  echo '$ sudo port install coreutils'
  return 1
fi

# Get the full list of versions
_ft_ruby_list() {
  echo $(for f in $(find "$RUBIES" -maxdepth 1 -type d | grep -v "$RUBIES$"); do basename "$f"; done)
}

# Swap out ruby versions by replacing $RUBIES/<ruby1>/bin with $RUBIES/<ruby2>/bin
_ft_set_ruby() {
  local current="$1"
  local pattern="$2"
  local change_reason=$3
  if [[ -z "$current" ]]; then
    current="$(echo "$PATH" | tr ":" "\n" | grep -m 1 "^$RUBIES/.*/bin/\?\$")"
  fi
  if [[ -z "$pattern" ]]; then
    pattern="$FT_DEFAULT_RUBY"
  fi
  local -a rubies
  rubies=( $(find "$RUBIES" -maxdepth 1 -type d -name "${pattern}*") )
  if [[ ${#rubies[@]} -eq 0 ]]; then
    echo "Error: No ruby matched $pattern."
    return 1
  elif [[ ${#rubies[@]} -gt 1 ]]; then
    echo "Error: ambiguous ruby \"$pattern\": the following rubies all matched"
    local r
    for r in "${rubies[@]}"; do basename "$r"; done
    return 1
  fi
  (( $_ft_shell_bash )) && local ruby="${rubies[0]}"
  (( $_ft_shell_zsh )) && local ruby="${rubies[1]}"
  if [[ "$(dirname "$current")" != "$ruby" ]]; then
    echo -e "\033[01;32mNow using ruby $(basename "$ruby").\033[39m"
    replace_path "$PATH" "$current" "$ruby/bin"
    export _ft_change_reason=$3
  fi
}

_ft_set_from_project_file() {
  local -a project_files
  project_files=( $(find "$1" -maxdepth 1 -type f -name "\.ft_ruby_*") )
  if [[ ${#project_files[@]} -eq 0 ]]; then
    if [[ "$1" = "/" ]]; then
      # Only switch back to the default if the current Ruby wasn't specified manually
      if [[ "${_ft_change_reason}" != "manual" ]]; then
        _ft_set_ruby
        export _ft_project_file=""
      fi
    else
      _ft_set_from_project_file "$(dirname "$1")"
    fi
  elif [[ ${#project_files[@]} -eq 1 ]]; then
    (( $_ft_shell_bash )) && local full_project_file="$(${_ft_readlink} -f "${project_files[0]}")"
    (( $_ft_shell_zsh )) && local full_project_file="$(${_ft_readlink} -f "${project_files[1]}")"
    if [[ "${full_project_file}" != "${_ft_project_file}" ]]; then
      (( $_ft_shell_bash )) && local file="$(basename "${project_files[0]}")"
      (( $_ft_shell_zsh )) && local file="$(basename "${project_files[1]}")"
      echo "Using flip-the-tables project file $1/$file"
      _ft_set_ruby "" "${file#\.ft_ruby_}" "file"
      export _ft_project_file="${full_project_file}"
    fi
  else # > 1 project files
    echo "Error: more than 1 matching flip-the-tables project files found in $1:"
    for f in "${project_files[@]}"; do echo "$f"; done
  fi
}

_ft_prompt_command() {
  if [[ "${_ft_cwd}" != "$(pwd)" ]]; then
    export _ft_cwd="$(pwd)"
    _ft_set_from_project_file "${_ft_cwd}"
  fi
}

export PROMPT_COMMAND='_ft_prompt_command;'"$PROMPT_COMMAND"

_ft_help() {
  echo 'flip-the-tables: easily switch ruby paths around.'
  echo 'Usage: ft [version|version-short|list|<ruby-version>]'
  echo 'The tab-completion should be a good hint :)'
}

if (( $_ft_shell_bash )); then
  shopt -s progcomp
fi

_ft_complete_list() {
  local option
  for option in $(_ft_ruby_list); do echo "$option"; done
  for option in version short-version list help; do echo $option; done
}

ft() {
  if [[ "$#" -ne 1 ]]; then
    _ft_help
  else
    local current="$(echo "$PATH" | tr ":" "\n" | grep -m 1 "^$RUBIES/.*/bin/\?\$")"
    local current_short="$(basename $(dirname "$current"))"
    if [[ -z "$current" ]]; then
      echo 'Error: not currently using Ruby in $RUBIES.'
    else
      case "$1" in
        help) _ft_help
          ;;
        version) echo "Current Ruby: $current_short"
          ;;
        short-version) echo -n "$current_short"
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
        *) _ft_set_ruby "$current" "$1" "manual"
          ;;
      esac
    fi
  fi
}

_ft_bash_completion() {
  COMPREPLY=()
  local current_word=${COMP_WORDS[COMP_CWORD]}
  COMPREPLY=($(compgen -W '$(_ft_complete_list)' -- $current_word))
  return 0
}

(( $_ft_shell_bash )) && complete -F _ft_completion ft
