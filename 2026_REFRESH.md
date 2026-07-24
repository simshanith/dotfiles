# 2026 Dotfiles Refresh

## Why

macOS switched to zsh as the default shell in Catalina (2019). These dotfiles were
originally bash-focused using Bash-It framework. Time to modernize.

## Future Plans

### Shell sugar (not yet adopted)
- **zsh-autosuggestions** - Fish-like suggestions as you type
- **zsh-syntax-highlighting** - Command highlighting

### iTerm2 prefs management (punted)
Ghostty is the primary terminal (`~/.config/ghostty/config`, chezmoi-managed).
iTerm2 stays installed as a secondary for `tmux -CC` control mode; its prefs
plist is intentionally **not** managed yet. Revisit if it earns a permanent seat.

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
| Fresh | chezmoi | Per-machine templating; no build step; active project |
| nvm | mise | Polyglot, fast, no shell-startup penalty |
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
| rtk | Token-optimizing CLI proxy for Claude Code (one-time `rtk init -g`, see below) |

### Brewfile Pared Down

Removed deprecated packages and trimmed to essentials:
- `boot2docker`, `docker-machine`, `fig` (old Docker tooling)
- `reattach-to-user-namespace` (tmux workaround)
- `mongodb` with args (needs tap now)
- `lighttable`, `lightpaper` (discontinued editors)
- `growl` (deprecated)
- Old cask tap names (`caskroom/*` → `homebrew/*`)

### Dotfile management: Fresh → chezmoi

Retired [Fresh](http://freshshell.com/) in favor of [chezmoi](https://www.chezmoi.io/)
(`mode = "symlink"`). GNU Stow was considered and rejected — the recurring pain in
this repo is *per-machine state* (mise `config.local.toml`, git user identity,
future work/personal split), which chezmoi templates solve natively and Stow does
not. See `CHEZMOI_MIGRATION.md` for the full rationale and cut-over log.

How it maps (source name → target):
- `dot_zshrc` → `~/.zshrc`; `.zshrc` sources `shell/*.sh` directly from `$DOTFILES`
  (those helpers stay outside chezmoi's tree via `.chezmoiignore`).
- `dot_gitconfig.tmpl` → `~/.gitconfig` (templated; folds in user identity from
  chezmoi data — no more `.gituserconfig` stub or `include.path` hack).
- `dot_tmux.conf` → `~/.tmux.conf` (`source-file`s the vendored seebi solarized theme).
- `dot_config/starship.toml`, `dot_config/ghostty/config`, `dot_inputrc` → their `~` paths.
- `dot_config/mise/conf.d/fresh.toml` → managed symlink (shared tool baseline);
  `create_config*.toml.tmpl` → seeded once, then edit-freely (chezmoi won't clobber).
- `private_bin/` → `~/bin` (`executable_cross_origin_chrome`, `symlink_subl`, `symlink_dotfiles`).
- `private_dot_emacs.d/init.el` → `~/.emacs.d/init.el`.
- seebi color files vendored into the repo (`shell/dircolors.ansi-universal`,
  `tmux/tmuxcolors-dark.conf`) — chezmoi can't fetch remote git like Fresh did.

Daily use: `chezmoi status` / `chezmoi diff` / `chezmoi apply` / `chezmoi edit`.
Per-machine answers (name/email/work/machine) live in `~/.config/chezmoi/chezmoi.toml`
(prompted by `chezmoi init`, not committed).

### Version management: nvm → mise

[mise](https://mise.jdx.dev/) owns the CLI toolchain (node, rust, go, bun, starship,
ripgrep, chezmoi itself, …). Shared baseline: `~/.config/mise/conf.d/fresh.toml`
(committed). Machine-local: `~/.config/mise/config.toml` (seeded once). Python is
delegated to `uv`. `eval "$(mise activate zsh)"` runs from `.zshrc`.

## Installation

```bash
git clone https://github.com/simshanith/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
exec zsh
```

### Post-install: wire rtk into Claude Code (one-time, per machine)

`rtk` (the token-optimizing Claude Code proxy) installs fleet-wide via the mise
baseline, but its Claude integration writes to `~/.claude/` — which chezmoi does
not manage — so it needs a single manual step after install:

```bash
rtk init -g          # hook + RTK.md + @RTK.md in ~/.claude/CLAUDE.md + settings.json
rtk init --show      # verify: all rows [ok]
```

Idempotent — safe to re-run. Skips automation in the dotfiles repo on purpose so
chezmoi never fights rtk over `~/.claude/CLAUDE.md` and `settings.json`.

rtk's own config *is* chezmoi-managed (`.chezmoitemplates/rtk-config.toml`, one
template → `~/.config/rtk/` on linux, `~/Library/Application Support/rtk/` on
darwin). It dials the hook back to where filtering measurably pays off: `rg`,
`grep`, `curl`, `diff` excluded (silent-failure risk or ~zero savings) and git
restricted to `commit`/`fetch` via `transparent_prefixes` (compact filters
stripped output the model needed, e.g. `git stash` SHAs). The whole JS toolchain
(`pnpm`, `npm`, `npx`, `yarn`, `bun`, `tsc`, `eslint`, `prettier`) is excluded too:
rtk drops the package-manager wrapper and substitutes its own handler, so
`pnpm lint` ran rtk's eslint instead of the project's `lint` script and
`pnpm exec prettier` resolved `prettier` off `PATH` instead of `node_modules/.bin`.
Across 90 days those commands saved 0.1% of their input tokens. Verify a rewrite
decision anytime with `rtk hook check "<cmd>"`.

## Verification

```bash
echo $SHELL              # /opt/homebrew/bin/zsh
which brew               # /opt/homebrew/bin/brew
starship --version       # Prompt
zoxide --version         # Directory jumping
mise doctor             # Toolchain healthy
chezmoi status          # Empty = $HOME matches the repo
```
