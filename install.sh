#!/usr/bin/env bash

set -euo pipefail

DOTFILE_DIR="$(cd "$(dirname "$0")" && pwd)"

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info() { printf '  %b%s%b\n' "$CYAN" "$1" "$NC"; }
success() { printf '  %b✓ %s%b\n' "$GREEN" "$1" "$NC"; }
warn() { printf '  %b⚠ %s%b\n' "$YELLOW" "$1" "$NC"; }
error() { printf '  %b✗ %s%b\n' "$RED" "$1" "$NC" >&2; }
header() { printf '\n%b%s%b\n' "$BOLD" "$1" "$NC"; }

is_macos() { [[ "$(uname -s)" == "Darwin" ]]; }

is_debian() {
  [[ "$(uname -s)" == "Linux" ]] || return 1
  [[ -r /etc/os-release ]] || return 1
  grep -Eq '^ID="?debian"?$|^ID_LIKE="?([^" ]+ )*debian( [^" ]+)*"?$' /etc/os-release
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || {
    error "Missing required command: $1"
    return 1
  }
}

# Create a symlink, backing up any existing destination first.
# If a correct symlink already exists, skip it.
symlink() {
  local src="$1"
  local dst="$2"

  if [[ ! -e "$src" && ! -L "$src" ]]; then
    error "Link source does not exist: $src"
    return 1
  fi

  # Already pointing to the right place — nothing to do
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    info "Already linked: $dst"
    return
  fi

  # Back up an existing file, directory, or incorrect/broken symlink.
  if [[ -e "$dst" || -L "$dst" ]]; then
    local bak
    bak="${dst}.bak.$(date +%Y%m%d%H%M%S).$$"
    mv "$dst" "$bak"
    warn "Backed up: $dst → $bak"
  fi

  # Ensure parent directory exists
  mkdir -p "$(dirname "$dst")"

  ln -s "$src" "$dst"
  success "Linked: $dst → $src"
}

ensure_directory() {
  local dir="$1"

  if [[ -d "$dir" && ! -L "$dir" ]]; then
    return
  fi

  if [[ -e "$dir" || -L "$dir" ]]; then
    local bak
    bak="${dir}.bak.$(date +%Y%m%d%H%M%S).$$"
    mv "$dir" "$bak"
    warn "Backed up: $dir → $bak"
  fi

  mkdir -p "$dir"
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

  setup_codex

  mkdir -p "$HOME/.config"
  symlink "$DOTFILE_DIR/.config/starship" "$HOME/.config/starship"
  symlink "$DOTFILE_DIR/.config/presenterm" "$HOME/.config/presenterm"

  setup_zsh_tooling
  setup_neovim
}

setup_codex() {
  header "Codex configuration"
  ensure_directory "$HOME/.codex"
  symlink "$DOTFILE_DIR/.codex/config.toml" "$HOME/.codex/config.toml"
  symlink "$DOTFILE_DIR/.codex/AGENTS.md" "$HOME/.codex/AGENTS.md"
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

  if [[ "$selection" == "a" ]]; then
    symlink "$DOTFILE_DIR/.zsh-tooling" "$HOME/.zsh-tooling"
    return
  fi

  mkdir -p "$HOME/.zsh-tooling"

  for num in $selection; do
    if [[ ! "$num" =~ ^[0-9]+$ ]]; then
      warn "Invalid selection: $num"
      continue
    fi
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
  if [[ -e "$nvim_dir" || -L "$nvim_dir" ]]; then
    info "Neovim config already exists at $nvim_dir — skipping"
    return
  fi
  read -r -p "  Clone lazyvim config to ~/.config/nvim? [y/N]: " confirm
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    require_command git
    git clone --depth 1 https://github.com/overtfuture/lazyvim.git "$nvim_dir"
    success "Neovim config cloned"
  else
    warn "Skipping Neovim config"
  fi
}

setup_dependencies() {
  header "Installing dependencies"
  if is_macos; then
    "$DOTFILE_DIR/.bin/macos/setup-dependencies"
  elif is_debian; then
    "$DOTFILE_DIR/.bin/debian/setup-dependencies"
  else
    warn "Unsupported platform. Dependency setup supports macOS and Debian-based Linux."
  fi
}

setup_gitconfig() {
  header "Git configuration"
  require_command git
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

  require_command sudo
  if [[ ! -x /usr/sbin/sshd ]]; then
    error "Cannot validate SSH configuration: /usr/sbin/sshd is missing"
    return 1
  fi

  local security_target=/etc/ssh/sshd_config.d/001-ssh-macos-security.conf
  local macos_target=/etc/ssh/sshd_config.d/100-macos.conf
  local security_backup="${security_target}.dotfiles-backup.$$"
  local macos_backup="${macos_target}.dotfiles-backup.$$"
  local had_security=false
  local had_macos=false

  sudo mkdir -p /etc/ssh/sshd_config.d
  if sudo test -e "$security_target"; then
    sudo cp -p "$security_target" "$security_backup"
    had_security=true
  fi
  if sudo test -e "$macos_target"; then
    sudo cp -p "$macos_target" "$macos_backup"
    had_macos=true
  fi

  if ! sudo install -o root -g wheel -m 0644 \
      "$DOTFILE_DIR/sshd_conf.d/001-ssh-macos-security.conf" "$security_target" ||
    ! sudo install -o root -g wheel -m 0644 \
      "$DOTFILE_DIR/sshd_conf.d/100-macos.conf" "$macos_target" ||
    ! sudo /usr/sbin/sshd -t; then
    if [[ "$had_security" == true ]]; then
      sudo mv "$security_backup" "$security_target"
    else
      sudo rm -f "$security_target"
    fi
    if [[ "$had_macos" == true ]]; then
      sudo mv "$macos_backup" "$macos_target"
    else
      sudo rm -f "$macos_target"
    fi
    error "SSH configuration was invalid; previous files were restored"
    return 1
  fi

  [[ "$had_security" == false ]] || sudo rm -f "$security_backup"
  [[ "$had_macos" == false ]] || sudo rm -f "$macos_backup"
  success "SSH configs deployed"
  warn "Restart sshd to apply: sudo launchctl stop com.openssh.sshd && sudo launchctl start com.openssh.sshd"
}

# ─── Menu ─────────────────────────────────────────────────────────────────────

print_menu() {
  printf '\n%bDotfiles Setup%b\n' "$BOLD" "$NC"
  echo "────────────────"
  echo "  1) Full setup      (symlinks + dependencies + gitconfig + SSH)"
  echo "  2) Symlinks only"
  echo "  3) Codex config only"
  echo "  4) Dependencies only"
  echo "  5) Git config only"
  echo "  6) SSH config only (macOS)"
  echo "  7) Exit"
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
      printf '\n%b%bDone! Run '\''exec zsh'\'' to reload your shell.%b\n\n' "$GREEN" "$BOLD" "$NC"
      break
      ;;
    2) setup_symlinks ;;
    3) setup_codex ;;
    4) setup_dependencies ;;
    5) setup_gitconfig ;;
    6) setup_ssh ;;
    7)
      echo
      exit 0
      ;;
    *) error "Invalid choice: $choice" ;;
    esac
  done
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
