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
| rtk | Token-optimizing CLI proxy — explicit `rtk <cmd>` use only, no hook (see below) |

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

### rtk: on PATH, but never automatic

`rtk` is a token-optimizing CLI proxy. It stays installed fleet-wide and is
useful when you reach for it — but it is **not** wired into Claude Code. It runs
only when you type `rtk <cmd>` yourself.

**Why no hook.** rtk used to install a `PreToolUse` hook that rewrote Bash
commands automatically. The problem is that rtk *substitutes* rather than
filters: it drops the wrapper and any argument it does not recognize.

- `pnpm lint` → ran rtk's own eslint instead of the project's `lint` script
- `pnpm exec prettier` → resolved `prettier` off `PATH`, not `node_modules/.bin`
- `next build` → dropped `build` outright
- a rewritten `grep` could hit a usage error rtk swallowed with **exit 0**, so a
  search silently returned nothing

Those are correctness bugs, not overhead, and one silently-wrong result costs
more than the filtering saves. It is structural rather than something to wait
out: rtk ships only denylists (`exclude_commands`, `transparent_prefixes`), so
every handler is armed by default and each release re-arms the surface — 0.43.0
added three new rewrite paths with no action on our side.

Invoked deliberately, none of that ambiguity exists. You asked for `rtk read`,
so you get `rtk read`. The failure mode was always *automatic* substitution.

**Unhooking a machine.** chezmoi does not manage `~/.claude/`, so the hook and
the `@RTK.md` include survive on any machine that ran `rtk init -g`:

```bash
mise run rtk:unhook                              # dry run
mise run rtk:unhook -- --yes                     # apply
mise run rtk:unhook -- --yes --reset-history     # ...and zero the stats
```

This unwires the `PreToolUse` hook from `~/.claude/settings.json` (leaving
unrelated hooks alone), drops the `@RTK.md` include and `~/.claude/RTK.md`
(whose guidance describes hook rewriting that no longer happens), and keeps rtk
installed along with its config and history.

`--reset-history` wipes `history.db` so `rtk gain` restarts from zero. Worth
doing once: the existing database is ~6,800 hook-driven commands, which answers
"did the hook save tokens?" — a question that no longer matters. Starting clean
makes it answer "is invoking rtk by hand actually worth it?" instead.

To remove rtk altogether, `mise run rtk:uninstall` does the same cleanup plus
rtk's config/history directory and `mise uninstall --all rtk`.

Both tasks are dry-run by default, back up every file they edit, are safe to
re-run, and no-op once clean. They wrap `~/bin/rtk-uninstall`, which is also
runnable directly.

rtk's own config stays chezmoi-managed (`.chezmoitemplates/rtk-config.toml` →
`~/.config/rtk/` on linux, `~/Library/Application Support/rtk/` on darwin). It
pins telemetry off and carries **no** `[hooks]` section — with nothing invoking
rtk automatically, a denylist there would be unreachable policy.

## Verification

```bash
echo $SHELL              # /opt/homebrew/bin/zsh
which brew               # /opt/homebrew/bin/brew
starship --version       # Prompt
zoxide --version         # Directory jumping
mise doctor             # Toolchain healthy
chezmoi status          # Empty = $HOME matches the repo
```
