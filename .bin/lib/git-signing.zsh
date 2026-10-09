# Configure Git for this shell and its children without writing ~/.gitconfig.
configure_git_signing() {
  local signer=ssh-keygen key_file="$HOME/.ssh/git_signing_key.pub"
  if [[ "$OSTYPE" == darwin* && -z "${SSH_CONNECTION:-}" ]]; then
    signer=/Applications/1Password.app/Contents/MacOS/op-ssh-sign
    key_file="$HOME/.ssh/1password_signing_key.pub"
  fi
  [[ -f "$key_file" ]] || key_file=''

  local count=${GIT_CONFIG_COUNT:-0}
  local start=${DOTFILES_GIT_SIGNING_CONFIG_START:--1}
  local previous_count=${DOTFILES_GIT_SIGNING_CONFIG_COUNT:-0}
  local -a previous_keys=(gpg.ssh.program gpg.ssh.defaultKeyCommand user.signingkey)
  local -a keys=(gpg.ssh.program gpg.ssh.defaultKeyCommand)
  local -a values=("$signer" 'ssh-add -L')
  local -a suffix_keys=() suffix_values=()
  if [[ -n "$key_file" ]]; then
    keys+=(user.signingkey)
    values+=("$key_file")
  fi
  local i name value_name

  # Remove our previous entries after `source ~/.zshrc` or `exec zsh`,
  # preserving overrides supplied by the caller or appended by other tools.
  if (( start >= 0 && previous_count >= 2 && previous_count <= 3 && count >= start + previous_count )); then
    local ours=true
    for (( i = 1; i <= previous_count; i++ )); do
      name="GIT_CONFIG_KEY_$((start + i - 1))"
      [[ "${(P)name}" == "${previous_keys[$i]}" ]] || ours=false
    done
    if [[ "$ours" == true ]]; then
      for (( i = start + previous_count; i < count; i++ )); do
        name="GIT_CONFIG_KEY_$i"
        value_name="GIT_CONFIG_VALUE_$i"
        suffix_keys+=("${(P)name}")
        suffix_values+=("${(P)value_name}")
      done
      count=$start
    fi
  fi

  export DOTFILES_GIT_SIGNING_CONFIG_START=$count
  export DOTFILES_GIT_SIGNING_CONFIG_COUNT=${#keys}
  for (( i = 1; i <= ${#keys}; i++ )); do
    export "GIT_CONFIG_KEY_$count=${keys[$i]}"
    export "GIT_CONFIG_VALUE_$count=${values[$i]}"
    (( count += 1 ))
  done
  # Keep later overrides after our defaults so their precedence survives reloads.
  for (( i = 1; i <= ${#suffix_keys}; i++ )); do
    export "GIT_CONFIG_KEY_$count=${suffix_keys[$i]}"
    export "GIT_CONFIG_VALUE_$count=${suffix_values[$i]}"
    (( count += 1 ))
  done
  export GIT_CONFIG_COUNT=$count
}
configure_git_signing
unfunction configure_git_signing
