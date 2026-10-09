# Dotfiles

## Quick Start

Clone and run the setup script on macOS or Debian-based Linux:

```shell
git clone https://github.com/overtfuture/dotfiles.git
cd dotfiles
./install.sh

# enjoy!
```

The script presents a menu to run a full setup or individual steps:

- Symlinks shared shell, tool, application, and Codex instructions while backing up existing files, and seeds a local Codex config when needed.
- Dependencies use Homebrew on macOS and native `apt-get` packages on Debian, Ubuntu, and other Debian derivatives.
- Git configuration optionally builds a correctly formatted SSH `allowed_signers` file from your public GitHub keys.
- SSH server configuration is macOS-only and is validated with `sshd -t` before the script reports success.

Re-run the installer any time to add new links or update configuration. The Debian installer does not add third-party package repositories; release-dependent packages such as `eza` and `starship` are installed only when the configured Debian repositories provide them.

## Shell customization

Keep machine-specific settings in `~/.zshrc_local` for interactive shells and
`~/.zprofile_local` for login shells. These files are optional, stay local, and
are not linked or overwritten by the installer. Start with
`.zshrc_local.example`; direct application installers to these local files when
possible. Keep credentials in `~/.zshrc_secrets`.

Git signing settings are passed to Git through the shell environment, so shell
startup never writes `~/.gitconfig`. Local macOS shells use the 1Password signer
and `~/.ssh/1password_signing_key.pub` when present. SSH and Linux shells use
`ssh-keygen` and `~/.ssh/git_signing_key.pub` when present. Otherwise Git honors
an explicitly configured signing key, or asks the SSH agent when none is set.
Set persistent identity and SSH signing defaults
with the installer's **Git config only** option. Apps launched outside these
shells use their own environment and the persistent Git configuration.

To profile interactive shell initialization:

```shell
DOTFILES_PROFILE_STARTUP=1 zsh -i -c exit
```

This prints zsh's function timing report. For overall startup time, use
`time zsh -i -c exit`. Completion caching can be added for commands shown to be
slow; measure before adding cache invalidation logic.

## Updating packages

Run `update` in an interactive shell, or run `~/.bin/update-system` directly.
On Linux it updates APT packages when available, using sudo only when needed.
It also updates Homebrew packages when Homebrew is installed. Each manager
stops its sequence on failure, so cleanup runs only after a successful upgrade.
Both managers are attempted, and the command returns a failure if either fails,
including Homebrew's final `brew doctor` check. Package upgrade and removal
prompts remain interactive.

## Checks

Install Bash, zsh, and ShellCheck, then run:

```shell
bash tests/check.sh
```

Checks cover shell syntax, ShellCheck for the installer and related Bash
scripts, installer backups and reruns, legacy tooling symlink migration,
Git signing selection without global writes, and package update failure
handling with mocked package managers. Tests use a temporary home
directory. CI runs the same checks on macOS and Linux.

Tooling modules are linked individually into `~/.zsh-tooling`, including when
you select all modules. A legacy directory symlink is backed up before switching
to individual links. Selecting modules adds links; it does not remove modules
already installed in a real directory.

## Codex

Codex configuration stays local because the app writes machine-specific settings
into it. The installer copies tracked defaults only when needed and links shared
instructions:

```text
~/.codex/config.toml   local file, seeded from .codex/config.example.toml
~/.codex/AGENTS.md  -> <dotfiles>/.codex/AGENTS.md
```

Run the existing installer and choose **Codex config only**:

```shell
./install.sh
```

Existing regular config files are preserved unchanged. A legacy config symlink
is backed up and replaced with a local copy of its current contents; a broken
symlink is backed up and replaced with the example defaults. New or migrated
config files use mode 0600. Running the installer again is safe.

Only `.codex/config.example.toml` is versioned. `.codex/config.toml`, credentials,
sessions, logs, and generated machine state are ignored. Changes to the example
do not overwrite existing local configuration; apply desired defaults manually.

The GitHub MCP server reads its bearer token from `GITHUB_PAT_TOKEN`; the token is not stored in this repository. For example, with the 1Password CLI:

```shell
export GITHUB_PAT_TOKEN="$(op read 'op://Private/GitHub Codex PAT/credential')"
```

If this dotfiles repository is public, configure that environment variable in a private or machine-local shell file such as `~/.zshrc_secrets`. Never add the token or the private shell file to version control.

Verify the installation and start Codex:

```shell
codex --version
codex
```

Then inspect MCP connections inside Codex:

```text
/mcp
```
