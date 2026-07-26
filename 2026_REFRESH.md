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

| Old                        | New       | Why                                                   |
| -------------------------- | --------- | ----------------------------------------------------- |
| Fresh                      | chezmoi   | Per-machine templating; no build step; active project |
| nvm                        | mise      | Polyglot, fast, no shell-startup penalty              |
| Bash-It themes             | Starship  | Cross-shell, fast, configurable                       |
| fasd                       | zoxide    | Faster, maintained, better algorithm                  |
| hub                        | gh        | Official GitHub CLI                                   |
| reattach-to-user-namespace | (removed) | Not needed since tmux 2.6                             |
| Python 2 http.server       | Python 3  | Python 2 EOL                                          |

### Tools Added

| Tool         | Purpose                                                                                  |
| ------------ | ---------------------------------------------------------------------------------------- |
| bat          | Better cat with syntax highlighting                                                      |
| fd           | Better find                                                                              |
| ripgrep (rg) | Better grep                                                                              |
| fzf          | Fuzzy finder                                                                             |
| git-delta    | Better git diff                                                                          |
| rtk          | Token-optimizing CLI proxy — always on PATH; automatic rewriting is a toggle (see below) |

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
this repo is _per-machine state_ (mise `config.local.toml`, git user identity,
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

`settings.python.uv_venv_auto` activates a uv project's `.venv` on `cd` (creating it
if absent), so `source .venv/bin/activate` is no longer needed. mise finds the project
by walking up for `uv.lock` — a bare `.venv` is ignored, so run `uv sync` once in a new
project before it takes effect.

## Installation

```bash
git clone https://github.com/simshanith/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
exec zsh
```

### rtk: on PATH always, automatic only when asked

`rtk` is a token-optimizing CLI proxy. It installs fleet-wide via the mise
baseline and is always available to invoke directly — `rtk read foo` works on
every machine. What is _optional_, and off by default, is the Claude Code hook
that rewrites Bash commands before you see them.

```bash
mise run rtk:hook           # enable: allowlisted commands get rewritten
mise run rtk:unhook         # disable: nothing is rewritten automatically
mise run rtk:hook:status    # what is actually wired, and any drift
mise run rtk:uninstall      # remove rtk entirely (dry run; pass -- --yes)
```

All four wrap `~/bin/rtk-hook` and `~/bin/rtk-uninstall`, which are runnable
directly. Both directions back up every file they touch and are safe to re-run.

**Why a toggle rather than a decision.** rtk _substitutes_ rather than filters:
it drops the wrapper and any argument it does not recognize.

- `pnpm lint` → ran rtk's own eslint instead of the project's `lint` script
- `pnpm exec prettier` → resolved `prettier` off `PATH`, not `node_modules/.bin`
- `next build` → dropped `build` outright
- a rewritten `grep` could hit a usage error rtk swallowed with **exit 0**, so a
  search silently returned nothing

Those are correctness bugs rather than overhead, and one silently-wrong result
costs more than the filtering saves. But the savings are real too — `rtk gain`
showed 4.7M tokens over 90 days, heavily concentrated in `cat`/`head`/`tail`.
Both facts are true, and which one dominates depends on the machine and the
week, so the posture is a switch rather than a verdict baked into the repo.

Invoked deliberately, none of that ambiguity exists: you asked for `rtk read`,
so you get `rtk read`. The hazard was always _automatic_ substitution.

**The allowlist.** When enabled, the Bash hook points at
`~/bin/rtk-allowlist-hook` rather than rtk's own `rtk hook claude`. rtk ships
only denylists (`exclude_commands`, `transparent_prefixes`), so every handler is
armed by default and each release re-arms the surface — 0.43.0 added three new
rewrite paths with no action on our side. The gate inverts that default: a
command is rewritten only if `~/.config/rtk-allowlist.toml` names it, and only
as the head of a single simple command. Anything with a pipe, `&&`, `;`, or a
redirect passes through untouched.

The list is short on purpose — `cat` `head` `tail` `ls` `gh` `find` `wc` `du`
`ps` `vitest` `cargo`, plus `git commit` and `git fetch` — each earning its place
in `rtk gain`. The whole JS toolchain is deliberately absent.

**How the toggle sticks.** The choice is a marker file
(`~/.config/rtk-hook-enabled`), per-machine and uncommitted. `chezmoi apply`
runs `run_after_20-claude-rtk-hook.sh`, which _reconciles to the marker_ rather
than asserting the hook: enabled machines get their wiring repaired if it
drifted, disabled machines are left alone. Without that gate a `chezmoi apply`
would silently undo `rtk-unhook`. An absent marker means disabled, so a fresh
machine gets rtk on PATH and no hook until it asks — the right default for a
fleet that is mostly headless.

**Migrating a machine that is already wired.** A machine hooked before the
toggle existed has no marker, so `rtk:hook:status` reports a hook with no
recorded intent and does nothing about it — `chezmoi apply` leaves such a
machine exactly as-is. Run `mise run rtk:hook` once to keep the hook and record
that choice, or `mise run rtk:unhook` to drop it.

This also means `rtk init -g` is never run. It repoints the hook straight at
`rtk hook claude`, re-arming everything, and overwrites `~/.claude/RTK.md`.
`rtk-hook status` reports that drift if it happens.

**Stats.** `rtk-hook disable --reset-history` wipes `history.db` so `rtk gain`
restarts from zero. Worth doing when going opt-in: an existing database is
mostly hook-driven traffic, which answers "did the hook save tokens?" — a
question that stops mattering once it is off. Starting clean makes it answer "is
invoking rtk by hand actually worth it?" instead.

rtk's own config is chezmoi-managed (`.chezmoitemplates/rtk-config.toml`, one
template → `~/.config/rtk/` on linux, `~/Library/Application Support/rtk/` on
darwin). It pins telemetry off and carries **no** `[hooks]` section: with the
allowlist deciding what reaches rtk, a denylist there is unreachable policy and
a second place to edit.

### Formatting

Four formatters, one file type each, all installed via mise and all usable from
Emacs (apheleia) or the shell:

| Type     | Tool       | Config          |
| -------- | ---------- | --------------- |
| TOML     | `taplo`    | `.taplo.toml`   |
| shell    | `shfmt`    | `.editorconfig` |
| Markdown | `oxfmt`    | (defaults)      |
| TS/JSON  | `prettier` | (defaults)      |

```bash
taplo fmt --check          # TOML
shfmt -d install.sh shell/*.sh private_bin/*   # shell (skips the python ones)
oxfmt --check **/*.md      # Markdown
```

Two decisions worth knowing:

- **`align_entries = true`** in `.taplo.toml`. taplo's default collapses the
  hand-aligned `=` columns in `fresh.toml`; this keeps them. The cost is that
  taplo column-aligns trailing `# why` comments rather than leaving them at a
  fixed two spaces.
- **`.editorconfig` records two indent dialects** — `private_bin/*` uses tabs,
  `install.sh` and `shell/*.sh` use four spaces — rather than unifying them.
  shfmt reads it, so a bare `shfmt -d` respects both.

`oxfmt` handles Markdown rather than prettier. It delegates `.md` to prettier
internally, so output is near-identical (verified byte-for-byte on this repo's
files, bar one case where oxfmt correctly leaves `*` unescaped inside a table
cell). It is one binary for the job and much faster. Note that prettier's
Markdown defaults normalize `*emphasis*` to `_emphasis_` and re-pad every table
— that reflow is the bulk of any Markdown diff.

## Verification

```bash
echo $SHELL              # /opt/homebrew/bin/zsh
which brew               # /opt/homebrew/bin/brew
starship --version       # Prompt
zoxide --version         # Directory jumping
mise doctor             # Toolchain healthy
chezmoi status          # Empty = $HOME matches the repo
```
