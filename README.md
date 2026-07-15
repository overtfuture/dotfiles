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

- Symlinks shared shell, tool, application, and Codex configuration while backing up existing files.
- Dependencies use Homebrew on macOS and native `apt-get` packages on Debian, Ubuntu, and other Debian derivatives.
- Git configuration optionally builds a correctly formatted SSH `allowed_signers` file from your public GitHub keys.
- SSH server configuration is macOS-only and is validated with `sshd -t` before the script reports success.

Re-run the installer any time to add new links or update configuration. The Debian installer does not add third-party package repositories; release-dependent packages such as `eza` and `starship` are installed only when the configured Debian repositories provide them.

## Codex

The shared Codex configuration installs these links while leaving credentials, sessions, logs, and other generated state local to each machine:

```text
~/.codex/config.toml -> <dotfiles>/.codex/config.toml
~/.codex/AGENTS.md   -> <dotfiles>/.codex/AGENTS.md
```

Run the existing installer and choose **Codex config only**:

```shell
./install.sh
```

Existing destination files or incorrect symlinks are backed up with a timestamp before the shared files are linked. Running the installer again with the correct links already present is safe.

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
