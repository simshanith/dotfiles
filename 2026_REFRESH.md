# 2026 Dotfiles Refresh

## Why

macOS switched to zsh as the default shell in Catalina (2019). These dotfiles were
originally bash-focused using Bash-It framework. Time to modernize.

## Future Plans

### mise - Polyglot Version Manager
Replace nvm (and rvm, pyenv, etc.) with [mise](https://mise.jdx.dev/):
- Single tool for Node, Ruby, Python, Go, Java, etc.
- Faster than nvm (no shell startup penalty)
- Compatible with `.nvmrc`, `.node-version`, `.ruby-version`
- Configuration in `~/.config/mise/config.toml`

```bash
brew install mise
# In .zshrc: eval "$(mise activate zsh)"
```

### GNU Stow - Simpler Symlink Management
Consider replacing Fresh with [GNU Stow](https://www.gnu.org/software/stow/):
- Simpler mental model (directories mirror `~/`)
- No build step - what you see is what you link
- Widely used in dotfiles community
- Each "package" is a directory that gets symlinked

```bash
brew install stow
cd ~/.dotfiles
stow zsh shell git tmux  # Creates symlinks to ~/
```

### Other Considerations
- **zsh-autosuggestions** - Fish-like suggestions as you type
- **zsh-syntax-highlighting** - Command highlighting

---

## What Changed

### Shell: bash → zsh
- Primary config: `~/.zshrc` (was `~/.bash_profile`)
- History: `~/.zsh_history` with zsh-specific options
- Completions: Native zsh completion system

### Architecture: Intel → Apple Silicon
- Homebrew location: `/opt/homebrew` (was `/usr/local`)
- Universal path handling for both architectures

### Directory Structure
```
bash/           →  shell/           # Shell-agnostic configs
├── exports.bash    ├── exports.sh
├── path.bash       ├── path.sh
├── aliases.bash    ├── aliases.sh
└── functions.bash  └── functions.sh
```

Old bash-specific files removed (git history preserved).

### Tools Replaced

| Old | New | Why |
|-----|-----|-----|
| Bash-It themes | Starship | Cross-shell, fast, configurable |
| fasd | zoxide | Faster, maintained, better algorithm |
| hub | gh | Official GitHub CLI |
| reattach-to-user-namespace | (removed) | Not needed since tmux 2.6 |
| Python 2 http.server | Python 3 | Python 2 EOL |

### Tools Added

| Tool | Purpose |
|------|---------|
| bat | Better cat with syntax highlighting |
| fd | Better find |
| ripgrep (rg) | Better grep |
| fzf | Fuzzy finder |
| git-delta | Better git diff |

### Brewfile Pared Down

Removed deprecated packages and trimmed to essentials:
- `boot2docker`, `docker-machine`, `fig` (old Docker tooling)
- `reattach-to-user-namespace` (tmux workaround)
- `mongodb` with args (needs tap now)
- `lighttable`, `lightpaper` (discontinued editors)
- `growl` (deprecated)
- Old cask tap names (`caskroom/*` → `homebrew/*`)

## Configuration

### Fresh Shell Manager

Still using [Fresh](http://freshshell.com/) for symlink management. Updated `.freshrc`
to build zsh configs instead of bash.

Fresh builds:
- `~/.zshrc` ← `zsh/.zshrc`
- `~/.exports` ← `shell/exports.sh`
- `~/.path` ← `shell/path.sh`
- `~/.aliases` ← `shell/aliases.sh`
- `~/.functions` ← `shell/functions.sh`
- `~/.config/starship.toml` ← `starship/starship.toml`
- `~/.gitconfig` ← `git/.gitconfig` + `git/.gituserconfig`
- `~/.tmux.conf` ← `tmux/.tmux.conf` + solarized colors
- `~/.dircolors` ← seebi/dircolors-solarized

### Git Config

Uses `include.path` to allow `git config --global` while preserving Fresh defaults.
Set up by `install.sh`.

## Installation

```bash
git clone https://github.com/simshanith/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
exec zsh
```

## Verification

```bash
echo $SHELL              # /bin/zsh
which brew               # /opt/homebrew/bin/brew
starship --version       # Prompt
zoxide --version         # Directory jumping
fresh                    # No errors
```
