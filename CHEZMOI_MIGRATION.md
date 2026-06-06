# Migration: Fresh → chezmoi

Branch: `simshanith/chezmoi-migration`
Status: **sketch** — nothing in this branch changes runtime yet. Read first, edit, then we cut a follow-up that actually moves files.

## Getting started with chezmoi

- Quick start: <https://www.chezmoi.io/quick-start/>
- User guide (skim): <https://www.chezmoi.io/user-guide/command-overview/>
- Templates reference: <https://www.chezmoi.io/user-guide/templating/>
- Already installed via `mise use -g cargo:chezmoi`. `which chezmoi` resolves in any shell that ran `mise activate`. (Currently v2.70.5.)

Mental model:

- **Source state**: a directory holding your dotfiles in chezmoi's naming convention (`dot_zshrc` not `.zshrc`, `dot_config/starship.toml` not `.config/starship.toml`). Default location is `~/.local/share/chezmoi`; we'll keep ours at `~/.dotfiles`.
- **Target state**: what chezmoi *would* produce in `$HOME` after applying templates and decoding the naming attributes.
- **Destination state**: what's actually in `$HOME` right now.
- `chezmoi apply` reconciles destination → target.
- `chezmoi diff` shows the gap. `chezmoi status` shows it briefly. `chezmoi edit <target>` opens the source file (with the right name mapping) in your editor. `chezmoi re-add` pulls a destination edit back into source.
- **Mode** is the big choice. Default is `file` (chezmoi copies content into `$HOME`); `mode = "symlink"` (set in `~/.config/chezmoi/chezmoi.toml`) makes every non-templated managed entry a symlink back to the source. We're picking symlink mode — it preserves the Fresh/Stow "edit either side, instant" feedback loop for the ~80% of files that aren't templates, while templated files (`.tmpl`) still render via `chezmoi apply` like normal.
- There's also a per-entry **`symlink_` prefix** for one-offs (`symlink_dot_foo` makes `~/.foo` a symlink whose target is whatever path is written inside the source file). Different from mode-level symlink, useful for things like wiring `~/bin/dotfiles` → `install.sh`.

Daily commands once migrated:

```bash
chezmoi status                 # what's drifted, what's pending
chezmoi diff                   # show all pending changes
chezmoi apply                  # reconcile $HOME to source
chezmoi edit ~/.zshrc          # edit source via target path (auto-applies on save by default)
chezmoi re-add                 # adopt modifications made directly in $HOME
chezmoi update                 # git pull + chezmoi apply
chezmoi cd                     # drop a shell in the source dir
```

## Why chezmoi instead of Stow

- **Templating solves the per-machine problem natively.** No more "shared baseline (symlinked) + per-machine override (copied)" two-file dance for `mise/config.toml`, `git/.gituserconfig`, etc. One `.tmpl` file, prompts on `chezmoi init`, renders to the right shape on each machine.
- **`run_once_*` scripts replace install-script glue.** Each script runs exactly once per content hash, state tracked in chezmoi's persistent state. The "is this already installed?" `if [[ -f ... ]]` chains in `install.sh` go away.
- **Built-in conditionals.** `{{ if eq .chezmoi.os "darwin" }}` and `{{ if .work }}` are first-class. Currently single-OS / single-class, but cheap insurance.
- **Active community.** Multiple 2025 blog posts including a [chezmoi + mise](https://manuelchichi.com.ar/blog/personal-toolset-2025/) walkthrough — the exact combo we're running. v2.70.5 was built today (2026-06-03).

## What Fresh did, mapped to chezmoi

| Fresh feature | Used for | chezmoi mechanism |
|---|---|---|
| Mirror (`fresh path/to/file --file=~/dest`) | `git/.gitconfig` → `~/.gitconfig` | source naming: `dot_gitconfig` |
| Rename (`shell/exports.sh` → `~/.exports`) | shell helpers | Doesn't need a rename — `.zshrc` sources from `$DOTFILES/shell/*.sh` directly (kept outside chezmoi's tree via `.chezmoiignore`) |
| Concatenate (gitconfig + gituserconfig) | git includes | Templated `dot_gitconfig.tmpl` with prompts on init |
| Concatenate (tmux.conf + tmux-colors-solarized) | tmux config | `dot_tmux.conf` has `source-file ~/.dotfiles/tmux/tmuxcolors-dark.conf` (vendored, ignored by chezmoi) |
| Pull from external git repos (seebi/*) | colors files | Vendor into repo; ignore from chezmoi |
| `--bin` (link executables) | `~/bin/dotfiles` | `install.sh` adds the symlink. Doesn't belong in chezmoi-managed state |

## Proposed source layout

Keep the repo at `~/.dotfiles`. chezmoi reads it via `--source ~/.dotfiles` (set once in `~/.config/chezmoi/chezmoi.toml`).

```
~/.dotfiles/
├── dot_zshrc                                            → ~/.zshrc
├── dot_inputrc                                          → ~/.inputrc
├── dot_gitconfig.tmpl                                   → ~/.gitconfig  (templated)
├── dot_gitattributes                                    → ~/.gitattributes
├── dot_gitignore                                        → ~/.gitignore
├── dot_tmux.conf                                        → ~/.tmux.conf
├── dot_emacs.d/
│   └── init.el                                          → ~/.emacs.d/init.el  (archives refreshed)
├── dot_config/
│   ├── starship.toml                                    → ~/.config/starship.toml
│   ├── ghostty/
│   │   └── config                                       → ~/.config/ghostty/config  (primary terminal)
│   ├── chezmoi/
│   │   └── chezmoi.toml.tmpl                            → ~/.config/chezmoi/chezmoi.toml  (init prompts)
│   └── mise/
│       ├── conf.d/fresh.toml                            → ~/.config/mise/conf.d/fresh.toml
│       ├── config.toml.tmpl                             → ~/.config/mise/config.toml        (templated)
│       └── config.local.toml.tmpl                       → ~/.config/mise/config.local.toml  (templated)
├── run_once_before_10-iterm2-shell-integration.sh.tmpl  # curls iTerm2 integration if absent
├── shell/                                               # NOT managed by chezmoi — sourced from .zshrc
│   ├── exports.sh
│   ├── path.sh
│   ├── aliases.sh
│   ├── functions.sh
│   ├── dircolors.sh
│   └── dircolors.ansi-universal                         # vendored from seebi
├── tmux/
│   └── tmuxcolors-dark.conf                             # vendored from seebi
├── git/
│   └── (empty after migration — .gituserconfig dance goes into the template)
├── bin/                                                 # managed by chezmoi → ~/bin (on PATH)
│   ├── executable_cross_origin_chrome                   → ~/bin/cross_origin_chrome  (+x)
│   ├── symlink_subl.tmpl                                → ~/bin/subl      (symlink, darwin only)
│   └── symlink_dotfiles                                 → ~/bin/dotfiles  (symlink → install.sh)
├── install.sh                                           # tiny bootstrap (brew + mise + chezmoi init --apply)
├── Brewfile
├── .chezmoiignore                                       # tells chezmoi to skip shell/, tmux/, git/, install.sh, etc.
├── .chezmoiroot                                         # marker file pointing chezmoi at the right root
├── README.md / readme.md / 2026_REFRESH.md / CHEZMOI_MIGRATION.md
└── backups/
```

## `~/.config/chezmoi/chezmoi.toml.tmpl` (init prompts)

This is what `chezmoi init` evaluates *first* — it asks questions, records the answers in `~/.config/chezmoi/chezmoi.toml`, and every other template can read from `{{ .* }}`.

```go-template
{{- $name := promptStringOnce . "name" "Full name" -}}
{{- $email := promptStringOnce . "email" "Git email" -}}
{{- $work := promptBoolOnce . "work" "Work machine?" false -}}
{{- $machine := promptStringOnce . "machine" "Machine label (e.g. mbp-personal)" "personal" -}}

sourceDir = "{{ .chezmoi.homeDir }}/.dotfiles"
mode = "symlink"

[data]
    name = {{ $name | quote }}
    email = {{ $email | quote }}
    work = {{ $work }}
    machine = {{ $machine | quote }}
```

Re-running `chezmoi init` won't re-prompt (the `promptXxxOnce` variants skip if a value is already recorded).

## `dot_gitconfig.tmpl`

```go-template
[user]
    name = {{ .name }}
    email = {{ .email }}

[core]
    excludesfile = ~/.gitignore
    attributesfile = ~/.gitattributes
{{/* rest of the file is identical to today's git/.gitconfig (minus the include hack) */}}
```

Replaces both the `~/.gitconfig` symlink **and** the `git/.gituserconfig` stub + `[include]` workaround in one file.

## `dot_config/mise/config.toml.tmpl`

```go-template
# Machine-specific mise entry point. Renders on `chezmoi apply`.
# Shared baseline lives in conf.d/fresh.toml.

[tools]
{{- if .work }}
# Work-only tools
# example: aws-vault = "latest"
{{- end }}
```

The `config.local.toml.tmpl` similarly absorbs whatever you'd put in it today. The `cp ~/.dotfiles/mise/config.local.toml ~/.config/mise/config.local.toml` dance from current `install.sh` disappears.

## `run_once_before_10-iterm2-shell-integration.sh.tmpl`

```bash
#!/usr/bin/env bash
# Runs exactly once per content hash, before chezmoi apply touches files.
{{ if eq .chezmoi.os "darwin" -}}
set -euo pipefail
target="$HOME/.iterm2_shell_integration.zsh"
[[ -f "$target" ]] || curl -fsSL https://iterm2.com/shell_integration/zsh -o "$target"
{{ end -}}
```

## `.chezmoiignore`

Keeps directories that are *referenced* by chezmoi-managed files (shell helpers, vendored colors, bootstrap script) out of the apply pass:

```
README.md
readme.md
2026_REFRESH.md
CHEZMOI_MIGRATION.md
Brewfile
dotfiles.sublime-project
bash_screenshot.png
install.sh
.freshrc
.idea
.claude
backups
iterm2-preferences
shell
tmux
git
mise
```

(The lowercased dirs here are the *source-side* directories whose contents are referenced by managed files but don't themselves represent target files. Confusing for one read; once you've internalized the `dot_` convention it's obvious.)

## `.zshrc` patch (replaces Fresh sourcing)

```diff
-# Fresh shell manager
-source ~/.fresh/build/shell.sh
+# Source shell helpers directly from the dotfiles repo
+: "${DOTFILES:=$HOME/.dotfiles}"
+for f in exports path aliases functions dircolors; do
+    [[ -r "$DOTFILES/shell/$f.sh" ]] && source "$DOTFILES/shell/$f.sh"
+done

-for file in ~/.{exports,path,aliases,functions,extra}; do
-    [[ -r "$file" ]] && source "$file"
-done
-unset file
+# Per-machine extras (not in repo)
+[[ -r ~/.extra ]] && source ~/.extra
```

## `dot_tmux.conf` (was `tmux/.tmux.conf`)

Add one line at the bottom:

```
source-file ~/.dotfiles/tmux/tmuxcolors-dark.conf
```

(`tmux/tmuxcolors-dark.conf` is vendored from `seebi/tmux-colors-solarized`. `.chezmoiignore` keeps the `tmux/` source dir out of apply.)

## `install.sh` rewrite (sketch)

```bash
#!/bin/bash
set -euo pipefail
DOTFILES="${DOTFILES:-$HOME/.dotfiles}"

# 1. Homebrew (chezmoi can't run without it on a fresh machine)
command -v brew >/dev/null || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew bundle --file="$DOTFILES/Brewfile" || true

# 2. mise (Brewfile already has it; this just activates for this shell)
eval "$(mise activate bash)"
mise install -y    # picks up chezmoi from fresh.toml

# 3. chezmoi takes it from here
chezmoi init --source="$DOTFILES" --apply

# 4. ~/bin is chezmoi-managed now (executable_ scripts + symlink_ entries), so the
#    `chezmoi init --apply` above already created ~/bin/{dotfiles,subl,cross_origin_chrome}.
#    No manual ln needed here.

echo "Done. Restart shell: exec zsh"
echo "Verify: chezmoi status (should be empty)"
```

Gone vs current `install.sh`:
- `source ~/.fresh/build/shell.sh`
- `cp ~/.dotfiles/.freshrc ~/.freshrc`
- `fresh install`
- `git config --global include.path .../fresh/build/gitconfig` (rolled into the gitconfig template)
- The two `cp` blocks for mise templates (rolled into the chezmoi templates)
- The iTerm2 curl (moved to a `run_once_` script)
- The git-user-config stub creation (moved to chezmoi init prompts)

## File-by-file mapping

| Today | After migration | Notes |
|---|---|---|
| `zsh/.zshrc` | `dot_zshrc` | rename, edit per .zshrc patch above |
| `shell/*.sh` | `shell/*.sh` (unchanged) | not under chezmoi; sourced from `.zshrc` via `$DOTFILES` |
| `git/.gitconfig` | `dot_gitconfig.tmpl` | templated; absorbs `.gituserconfig` |
| `git/.gitattributes` | `dot_gitattributes` | rename |
| `git/.gitignore` | `dot_gitignore` | rename |
| `git/.gituserconfig` | gone — folded into chezmoi data via init prompts | per-machine answers stored in `~/.config/chezmoi/chezmoi.toml` (gitignored by chezmoi by default) |
| `tmux/.tmux.conf` | `dot_tmux.conf` | rename; add `source-file` line |
| seebi tmux colors | `tmux/tmuxcolors-dark.conf` (vendored) | ignored by chezmoi |
| `.inputrc` | `dot_inputrc` | rename |
| `emacs/init.el` | `dot_emacs.d/init.el` | newly managed; refresh package archives (drop marmalade, https melpa) |
| (live) `~/.config/ghostty/config` | `dot_config/ghostty/config` | newly managed; primary terminal (cmux/Ghostty), `iTerm2 Solarized Dark` theme |
| `starship/starship.toml` | `dot_config/starship.toml` | path mirrors target |
| seebi dircolors | `shell/dircolors.ansi-universal` (vendored) | ignored |
| `mise/fresh.toml` | `dot_config/mise/conf.d/fresh.toml` | path mirrors target |
| `mise/config.toml` | `dot_config/mise/config.toml.tmpl` | templated |
| `mise/config.local.toml` | `dot_config/mise/config.local.toml.tmpl` | templated |
| `install.sh` | `install.sh` (root); `~/bin/dotfiles` via `bin/symlink_dotfiles` | script not managed; the ~/bin symlink is |
| `bin/symlinks/subl,subl3` | `bin/symlink_subl.tmpl` → `~/bin/subl`; drop `subl3` | chezmoi `symlink_`, darwin-gated via `.chezmoiignore` |
| `bin/crossOriginChrome.sh` | `bin/executable_cross_origin_chrome` → `~/bin/cross_origin_chrome` | renamed snake_case, no ext; chezmoi `executable_` sets +x |
| iTerm2 integration curl | `run_once_before_10-iterm2-shell-integration.sh.tmpl` | chezmoi tracks state |

## Cut-over plan

1. Add `chezmoi` to `mise/fresh.toml` (already done — `mise use -g cargo:chezmoi`).
2. **Vendor the seebi color files into the repo** (replaces Fresh's external-fetch; chezmoi can't pull from remote git). These two files are effectively frozen, so vendor rather than submodule:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/seebi/dircolors-solarized/master/dircolors.ansi-universal \
     -o shell/dircolors.ansi-universal
   curl -fsSL https://raw.githubusercontent.com/seebi/tmux-colors-solarized/master/tmuxcolors-dark.conf \
     -o tmux/tmuxcolors-dark.conf
   ```
   Then point the loaders at the local copies: `shell/dircolors.sh` evals `$DOTFILES/shell/dircolors.ansi-universal` instead of `~/.dircolors`; `dot_tmux.conf` `source-file`s `~/.dotfiles/tmux/tmuxcolors-dark.conf`.
3. Create `.chezmoiignore`, `dot_config/chezmoi/chezmoi.toml.tmpl`.
4. Rename and (where needed) templatize files per the layout. One commit per cluster (git, mise, shell-roots, config dir, scripts) keeps the diff reviewable.
5. Rewrite `install.sh`.
6. On a clean profile *or* after backing up `~`'s currently-symlinked files: run `./install.sh`, then `chezmoi status` should report empty.
7. Delete `.freshrc`. Drop fresh references from `install.sh` and `Brewfile`. Remove `~/.fresh/` (manual on the dev machine).
8. Update `2026_REFRESH.md`: replace the Stow plan with chezmoi reality. Move from "Future Plans" to "What Changed."

## Open questions before we actually move files

_(Vendoring resolved — now step 2 of the cut-over plan. The `config.local.toml` comment fix is committed on this branch — `b5ab690`.)_

1. **`emacs/init.el`** — ✅ **include.** Migrate to `dot_emacs.d/init.el` (technomancy `emacs-starter-kit` lineage: `better-defaults`, `paredit`, `magit`, `smex`). Refresh the package archives during the move: drop the dead `marmalade-repo`, switch `melpa-stable` to `https`, add `melpa`. Wasn't in `.freshrc`, so this newly puts it under management.
2. **`iterm2-preferences/`** — 🅿️ **punt prefs management; Ghostty is now primary.** Ghostty's config is plain text (`~/.config/ghostty/config`) and joins chezmoi cleanly (now in the layout as `dot_config/ghostty/config`). iTerm2 stays *installed* as a secondary for the one thing Ghostty/cmux can't do yet — **`tmux -CC` control mode**, especially over remote ssh. Its other historical edge, the **hotkey/Quake window**, is already covered by Ghostty's `global:opt+`=toggle_quick_terminal`. Don't wire up iTerm2 prefs now; keep the how-to in case it earns a permanent seat:
   - Native "custom preferences folder": `defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$HOME/.dotfiles/iterm2-preferences"` + `LoadPrefsFromCustomFolder -bool true`. iTerm2 then reads/writes `com.googlecode.iterm2.plist` in that folder; commit it. Loosen `iterm2-preferences/.gitignore` (currently `*` / `!.gitignore`) to allow the plist.
   - Prefer that over chezmoi-managing the plist directly — iTerm2 rewrites it constantly; chezmoi would just leave the dir alone.
   - Watch for `tmux -CC` support landing in Ghostty/cmux — that's the trigger to retire iTerm2 entirely.
3. **`bin/symlinks/subl,subl3`** — ✅ **keep, simplified, chezmoi-managed.** *Not* a `mise link` candidate (that's for runtime versions, not app CLIs). chezmoi owns `~/bin` now, so a `symlink_subl.tmpl` entry creates `~/bin/subl` → `/Applications/Sublime Text.app/Contents/SharedSupport/bin/subl`, OS-gated via `.chezmoiignore` (`{{ if ne .chezmoi.os "darwin" }}bin/subl{{ end }}`); drop the `subl→subl3` indirection.
4. **`bin/crossOriginChrome.sh`** — ✅ **keep, modernized, chezmoi-managed.** Old (~2013) `--disable-web-security` launcher, verified still valid as of 2026. Reworked: `CHROME_BIN` override, `mktemp -d` profile (now flagged *required* — Chrome v73+ ignores `--disable-web-security` without a non-default `--user-data-dir`), security note. shellcheck-clean. Renamed snake_case / no extension; chezmoi `bin/executable_cross_origin_chrome` lands it at `~/bin/cross_origin_chrome` (+x, on PATH). **The live file is already renamed to `bin/cross_origin_chrome`; the `executable_` prefix gets added at cut-over (step 4) when chezmoi takes over `~/bin`.**
5. **Per-machine zsh overrides** — keep `~/.extra` (sourced by `.zshrc`, gitignored). Could move to chezmoi templates later if `.extra` gets crowded.
6. **The init prompts** — `name`, `email`, `work`, `machine` is the starting set. Add others lazily as needs surface.

---

## Footnote: why not Stow?

[GNU Stow](https://www.gnu.org/software/stow/manual/stow.html) is the boring, ubiquitous, well-documented option. For most of this conversation it was the right answer: minimum-viable symlink farm, every dotfiles blog post on the internet assumes its layout, ~5 commands and a one-paragraph mental model.

We're picking chezmoi over it because the *actual recurring pain* in this repo is per-machine state (mise `config.local.toml`, git `.gituserconfig`, the future "work vs personal" split). Stow + `install.sh` glue handles those manually; chezmoi templates handle them natively. Once you accept that constraint, chezmoi's bigger surface area starts paying for itself.

If the templating dream sours: chezmoi → Stow conversion is a one-time `rename dot_X → .X` plus moving everything into `<pkg>/` wrapper dirs. No data lock-in.

Stow sketch (preserved for posterity): each top-level dir is a package mirroring `$HOME` (`zsh/.zshrc` → `~/.zshrc`); `.stow-global-ignore` at root keeps junk out; `install.sh` runs `stow --target="$HOME" --restow zsh git tmux ...`; rename/concat/external problems handled exactly as in the chezmoi plan above (source helpers from `$DOTFILES`, git `[include]`, tmux `source-file`, vendor seebi).

## Footnote: why not tuckr?

[Considered.](https://github.com/RaphGL/Tuckr) Author's tool, ~zero third-party adoption, opinionated `Configs/<group>/` layout, hardcoded `dotfiles[_profile]` directory naming requires a `TUCKR_HOME` symlink shim. Doesn't beat Stow on adoption or chezmoi on power. Kept installed via mise (cheap) in case `tuckr status` is ever wanted over an arbitrary tree.
