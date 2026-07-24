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
| rtk | Token-optimizing CLI proxy for Claude Code (allowlist-gated, see below) |

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

### rtk in Claude Code (no manual step)

`rtk` (the token-optimizing proxy) installs fleet-wide via the mise baseline, and
its Claude Code wiring is handled by `run_after_20-claude-rtk-hook.sh` on every
`chezmoi apply`. There is nothing to run by hand.

**Do not run `rtk init -g`.** It points the Bash `PreToolUse` hook straight at
`rtk hook claude` and overwrites `~/.claude/RTK.md` with guidance claiming every
command is rewritten. Both are wrong for this setup, and the run-script undoes
them on the next apply.

#### Why it is an allowlist

rtk has no opt-in mode — `exclude_commands` and `transparent_prefixes` are both
denylists, so every handler it ships is armed by default and each release re-arms
the surface. Of the 33 handlers it hooks, 21 had been invoked *zero* times in 90
days while still able to rewrite.

They are not harmless: rtk *substitutes* rather than filters, dropping the wrapper
and any argument it does not recognize. `pnpm lint` ran rtk's eslint instead of
the project's `lint` script, `pnpm exec prettier` resolved `prettier` off `PATH`
instead of `node_modules/.bin`, and `next build` dropped `build` outright. So the
hook points at a wrapper instead:

```
Claude Bash call -> rtk-allowlist-hook -> allowed? -> rtk hook claude -> rewrite
                                       -> else    -> no output ------> unchanged
```

rtk stays the rewrite engine; the wrapper only decides *whether it is consulted*.

#### The pieces

| file | role |
|---|---|
| `~/.config/rtk-allowlist.toml` | the allowlist — the only file to edit |
| `~/bin/rtk-allowlist-hook` | the gate; relays allowed commands to rtk |
| `~/.claude/RTK.md` | in-session guidance, kept honest about what is rewritten |
| rtk's own config | deliberately minimal — no `[hooks]` section at all |

The allowlist holds the ~11 commands with measured savings plus `git commit` and
`git fetch`, which is 99.55% of lifetime savings (4.66M of 4.68M tokens).
Compound commands (pipes, `&&`, redirection) are never rewritten, since rtk parses
only the leading command. The gate fails open on every error path — bad JSON,
missing rtk, timeout — so it can never block a command, and falls back to built-in
defaults if the TOML is missing or malformed rather than reverting to rtk's
wide-open behavior.

rtk's own config pins only `[tracking]` and `[telemetry]`; everything else was
byte-for-byte its default. It carries no denylists on purpose — with the gate in
front they would be unreachable policy *and* a second place to edit, where
allowing something in the allowlist stayed silently inert because rtk still
excluded it. One list, one file.

Setting `commands = []` disables rewriting entirely while leaving `rtk gain` and
manual `rtk <cmd>` usage intact.

#### Verifying

```bash
# the actual decision (what matters):
echo '{"tool_name":"Bash","tool_input":{"command":"ls -la"}}' | ~/bin/rtk-allowlist-hook
# prints the rewrite, or nothing at all when the command is not allowlisted
```

`rtk hook check "<cmd>"` shows rtk's *engine* view, which ignores the allowlist —
it reports rewrites for commands the hook actually leaves alone. That gap is
expected, not a bug.

## Verification

```bash
echo $SHELL              # /opt/homebrew/bin/zsh
which brew               # /opt/homebrew/bin/brew
starship --version       # Prompt
zoxide --version         # Directory jumping
mise doctor             # Toolchain healthy
chezmoi status          # Empty = $HOME matches the repo
```
