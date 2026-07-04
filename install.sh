#!/bin/bash

set -euo pipefail

DOTFILE_DIR="$(cd "$(dirname "$0")" && pwd)"

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info() { echo -e "  ${CYAN}${1}${NC}"; }
success() { echo -e "  ${GREEN}✓ ${1}${NC}"; }
warn() { echo -e "  ${YELLOW}⚠ ${1}${NC}"; }
error() { echo -e "  ${RED}✗ ${1}${NC}"; }
header() { echo -e "\n${BOLD}${1}${NC}"; }

is_macos() { [[ "$(uname)" == "Darwin" ]]; }

# Create a symlink, backing up any existing non-symlink file first.
# If a correct symlink already exists, skip it.
symlink() {
  local src="$1"
  local dst="$2"

  # Already pointing to the right place — nothing to do
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    info "Already linked: $dst"
    return
  fi

  # Existing real file/directory — back it up
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    local bak="${dst}.bak.$(date +%Y%m%d%H%M%S)"
    mv "$dst" "$bak"
    warn "Backed up: $dst → $bak"
  fi

  # Stale or wrong symlink — remove it
  if [ -L "$dst" ]; then
    rm "$dst"
  fi

  # Ensure parent directory exists
  mkdir -p "$(dirname "$dst")"

  ln -s "$src" "$dst"
  success "Linked: $dst → $src"
}

# ─── Sections ────────────────────────────────────────────────────────────────

setup_symlinks() {
  header "Setting up symlinks"

  symlink "$DOTFILE_DIR/.zprofile" "$HOME/.zprofile"
  symlink "$DOTFILE_DIR/.zshrc" "$HOME/.zshrc"
  symlink "$DOTFILE_DIR/.tmux.conf" "$HOME/.tmux.conf"
  symlink "$DOTFILE_DIR/.gitignore_global" "$HOME/.gitignore_global"
  symlink "$DOTFILE_DIR/.zshrc_private" "$HOME/.zshrc_private"
  symlink "$DOTFILE_DIR/.bin" "$HOME/.bin"

  mkdir -p "$HOME/.config"
  symlink "$DOTFILE_DIR/.config/starship" "$HOME/.config/starship"
  symlink "$DOTFILE_DIR/.config/presenterm" "$HOME/.config/presenterm"

  setup_zsh_tooling
  setup_neovim
}

setup_zsh_tooling() {
  header "Select .zsh-tooling modules to link"
  echo "  Enter the numbers of tools you want (space-separated), then press Enter."
  echo "  Enter 'a' to install all. Leave blank to skip."
  echo "  Already-linked tools are marked with [✓]."
  echo

  local tools=()
  while IFS= read -r -d '' f; do
    tools+=("$(basename "$f")")
  done < <(find "$DOTFILE_DIR/.zsh-tooling" -maxdepth 1 -type f -print0 | sort -z)

  # Build display list with current link status
  for i in "${!tools[@]}"; do
    local tool="${tools[$i]}"
    local dst="$HOME/.zsh-tooling/$tool"
    local src="$DOTFILE_DIR/.zsh-tooling/$tool"
    local status=""
    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
      status=" ${GREEN}[✓]${NC}"
    fi
    printf "  %2d) %s%b\n" "$((i + 1))" "$tool" "$status"
  done

  echo
  read -r -p "  Selection: " selection

  if [ -z "$selection" ]; then
    warn "Skipping .zsh-tooling"
    return
  fi

  mkdir -p "$HOME/.zsh-tooling"

  if [[ "$selection" == "a" ]]; then
    local dst="$HOME/.zsh-tooling"
    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$DOTFILE_DIR/.zsh-tooling" ]; then
      info "Already linked: $dst"
    else
      [ -L "$dst" ] && rm "$dst"
      ln -s "$DOTFILE_DIR/.zsh-tooling" "$dst"
      success "Linked: $dst → $DOTFILE_DIR/.zsh-tooling"
    fi
    return
  fi

  for num in $selection; do
    local idx=$((num - 1))
    if [ "$idx" -ge 0 ] && [ "$idx" -lt "${#tools[@]}" ]; then
      local tool="${tools[$idx]}"
      symlink "$DOTFILE_DIR/.zsh-tooling/$tool" "$HOME/.zsh-tooling/$tool"
    else
      warn "Invalid selection: $num"
    fi
  done
}

setup_neovim() {
  header "Neovim config"
  local nvim_dir="$HOME/.config/nvim"
  if [ -d "$nvim_dir" ]; then
    info "Neovim config already exists at $nvim_dir — skipping"
    return
  fi
  read -r -p "  Clone lazyvim config to ~/.config/nvim? [y/N]: " confirm
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    git clone https://github.com/overtfuture/lazyvim.git "$nvim_dir"
    success "Neovim config cloned"
  else
    warn "Skipping Neovim config"
  fi
}

setup_dependencies() {
  header "Installing dependencies"
  if ! is_macos; then
    warn "Dependency setup is macOS-only — skipping"
    return
  fi
  "$DOTFILE_DIR/.bin/macos/setup-dependencies"
}

setup_gitconfig() {
  header "Git configuration"
  "$DOTFILE_DIR/.bin/setup-gitconfig"
}

setup_ssh() {
  header "SSH server config"
  if ! is_macos; then
    warn "SSH config deployment is macOS-only — skipping"
    return
  fi

  echo "  This will copy SSH server configs to /etc/ssh/sshd_config.d/ (requires sudo)."
  read -r -p "  Proceed? [y/N]: " confirm
  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    warn "Skipping SSH config"
    return
  fi

  sudo cp "$DOTFILE_DIR/sshd_conf.d/001-ssh-macos-security.conf" /etc/ssh/sshd_config.d/
  sudo cp "$DOTFILE_DIR/sshd_conf.d/100-macos.conf" /etc/ssh/sshd_config.d/
  success "SSH configs deployed"
  warn "Restart sshd to apply: sudo launchctl stop com.openssh.sshd && sudo launchctl start com.openssh.sshd"
}

# ─── Menu ─────────────────────────────────────────────────────────────────────

print_menu() {
  echo -e "\n${BOLD}Dotfiles Setup${NC}"
  echo "────────────────"
  echo "  1) Full setup      (symlinks + dependencies + gitconfig + SSH)"
  echo "  2) Symlinks only"
  echo "  3) Dependencies only"
  echo "  4) Git config only"
  echo "  5) SSH config only"
  echo "  6) Exit"
  echo
}

main() {
  while true; do
    print_menu
    read -r -p "Choice: " choice
    case "$choice" in
    1)
      setup_symlinks
      setup_dependencies
      setup_gitconfig
      setup_ssh
      echo -e "\n${GREEN}${BOLD}Done! Run 'exec zsh' to reload your shell.${NC}\n"
      break
      ;;
    2) setup_symlinks ;;
    3) setup_dependencies ;;
    4) setup_gitconfig ;;
    5) setup_ssh ;;
    6)
      echo
      exit 0
      ;;
    *) error "Invalid choice: $choice" ;;
    esac
  done
}

main
