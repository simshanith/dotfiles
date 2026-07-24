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
| rtk | (removed) | Rewrote commands into the wrong binary; see below |
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

### Removing rtk (was: a Claude Code token proxy)

`rtk` used to install fleet-wide and wire a `PreToolUse` hook into Claude Code
that rewrote Bash commands to token-cheaper equivalents. It has been dropped.

**Why.** rtk *substitutes* rather than filters: it drops the wrapper and any
argument it does not recognize. `pnpm lint` ran rtk's own eslint instead of the
project's `lint` script, `pnpm exec prettier` resolved `prettier` off `PATH`
instead of `node_modules/.bin`, and `next build` dropped `build` outright. A
`grep` rewrite could hit a usage error that rtk swallowed with exit 0, so a
search silently returned nothing. Those are correctness bugs, and they cost more
than the tokens saved — a single silently-wrong result outweighs the filtering.

The shape of the problem is structural: rtk ships only denylists
(`exclude_commands`, `transparent_prefixes`), so every handler it has is armed by
default and each release re-arms the surface. 0.43.0 added three new rewrite
paths with no action on our side.

**Uninstalling.** Dropping rtk from the mise baseline stops *new* machines
getting it, but chezmoi does not manage `~/.claude/`, so the hook and the
`@RTK.md` include survive on every machine that already ran `rtk init -g` — where
a dangling hook then fails on every Bash call. Removing the config from chezmoi's
source likewise only *unmanages* it; the file stays on disk. Hence an explicit
helper:

```bash
mise run rtk:uninstall             # dry run — prints exactly what it would remove
mise run rtk:uninstall -- --yes    # apply
```

It unwires the `PreToolUse` hook from `~/.claude/settings.json` (leaving
unrelated hooks alone), drops the `@RTK.md` include, deletes `~/.claude/RTK.md`
and rtk's config + history directory, and runs `mise uninstall --all rtk`. It
backs up any file it edits, is safe to re-run, and no-ops once clean. Pass
`--keep-binary` to undo only the Claude wiring and keep `rtk` runnable by hand.

Runnable directly as `rtk-uninstall` too — the task is a thin wrapper over
`~/bin/rtk-uninstall`. Both can be deleted from this repo once the fleet is
clean.

## Verification

```bash
echo $SHELL              # /opt/homebrew/bin/zsh
which brew               # /opt/homebrew/bin/brew
starship --version       # Prompt
zoxide --version         # Directory jumping
mise doctor             # Toolchain healthy
chezmoi status          # Empty = $HOME matches the repo
```
