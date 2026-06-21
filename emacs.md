# Emacs

Config for editing this dotfiles repo and the **silicon-grove** project
(TypeScript/Bun + Rust, with YAML/JSON/Markdown/Dockerfile/SQL throughout).

- **Editor:** GNU Emacs 30.2 (`emacs-plus@30`, installed via Brewfile) with
  native compilation enabled.
- **Config source:** `private_dot_emacs.d/init.el` → chezmoi deploys it to
  `~/.emacs.d/init.el`. Edit the source, then `chezmoi apply`.
- **CLI tooling** (language servers, formatters): mise, in
  `dot_config/mise/conf.d/fresh.toml`.

## First-run bootstrap

On a fresh machine, after `chezmoi apply` + `mise install`:

1. Launch Emacs. `use-package` pulls every package from MELPA on first start.
2. Open a `.ts`/`.rs`/`.yaml`/etc. file — **treesit-auto** prompts to download
   the tree-sitter grammar (`treesit-auto-install 'prompt`). Accept.
3. LSP starts automatically (Eglot) once the matching server is on `PATH`.

## What's installed and why

### Foundation
- **use-package** (built-in, Emacs 29+) — declarative, self-installing config
  (`use-package-always-ensure t`).
- **better-defaults** — sane editing baseline. *Note:* now pulled from MELPA;
  was previously a manual clone under `~/.emacs.d/better-defaults`.
- Built-ins enabled: `which-key-mode` (Emacs 30 built-in), `savehist-mode`,
  `recentf-mode`, `electric-pair-mode`, `display-line-numbers-mode` in prog
  buffers.
- **custom-file** redirected to `~/.emacs.d/custom.el` so Customize's auto-writes
  never collide with the chezmoi-managed (symlinked) `init.el`.

### PATH / environment
- **exec-path-from-shell** (`:when` GUI on macOS) — imports PATH from a *login*
  shell (`-l`, which sources `~/.zprofile`) so a Dock/Spotlight-launched
  `Emacs.app` can find the mise shims (language servers). No-op in terminal /
  headless sessions, which already inherit PATH. The shims PATH itself lives in
  `dot_zprofile`, so the `-l` login shell picks it up without sourcing the heavy
  interactive `~/.zshrc`.

### Appearance
- **color-theme-sanityinc-solarized** — `sanityinc-solarized-dark`
  (self-installing so a fresh machine reproduces it).
- Font: `Operator Mono SSm Book-11`.

### Syntax highlighting — tree-sitter
- **treesit-auto** — installs grammars on demand and remaps file types to the
  built-in `*-ts-mode` major modes (ts/tsx/js/json/yaml/toml/rust/bash/
  dockerfile/css/html). Emacs 30 ships the modes; grammars are downloaded
  per-machine, not committed.

### Markdown
- **markdown-mode** — `.md`/`README.md` open in `gfm-mode` (GitHub-flavored);
  `markdown-command` = `pandoc`; fenced code blocks highlight natively.
- **grip-mode** — GitHub-accurate live preview (needs `grip`:
  `uv tool install grip`). Bound to `g` in the markdown command map.

### LSP — Eglot (built-in)
`eglot-ensure` is hooked into: `typescript-ts-mode`, `tsx-ts-mode`,
`js-ts-mode`, `rust-ts-mode`, `yaml-ts-mode`, `json-ts-mode`, `bash-ts-mode`,
`dockerfile-ts-mode`. Servers live in mise (see below).

### Completion
- **corfu** — in-buffer completion popup (`corfu-auto`, `corfu-cycle`).
- **cape** — completion sources (`cape-file`, `cape-dabbrev`).
- **vertico** + **marginalia** + **orderless** — minibuffer completion,
  annotations, and fuzzy matching for command/file/project navigation.

### Git
- **magit** — `C-x g`.

### Fuzzy finding — fzf.el
- **fzf.el** ([bling/fzf.el](https://github.com/bling/fzf.el)) — runs the
  terminal `fzf` in a popup term buffer. Complements the minibuffer stack
  (vertico/orderless); shines for fast git-tracked file jumps and whole-repo
  content grep. Needs the `fzf` binary (in the mise baseline); the grep commands
  use `rg` (`fzf/grep-command` = `rg --no-heading -nH --color=always`), also in
  the baseline.

  | Key | Command | Action |
  |-----|---------|--------|
  | `C-c z f` | `fzf-find-file` | files under `default-directory` |
  | `C-c z g` | `fzf-git-files` | files tracked in the git repo |
  | `C-c z b` | `fzf-switch-buffer` | switch buffer |
  | `C-c z e` | `fzf-recentf` | recent files |
  | `C-c z r` | `fzf-grep-dwim` | ripgrep content, seeded from symbol at point |
  | `C-c z R` | `fzf-grep` | ripgrep content, prompt for pattern |

### Editing polish
- **rainbow-delimiters** — colored paren nesting in prog buffers.
- **paredit** — structural editing in lisp buffers (emacs-lisp, lisp-interaction,
  lisp, ielm). `electric-pair-local-mode` is disabled there so paredit owns
  paren insertion.

### Formatting — apheleia (opt-in)
Installed but **format-on-save is OFF by default**.
- `C-c f` — format the current buffer once (`apheleia-format-buffer`).
- `M-x apheleia-global-mode` — toggle format-on-save for the session.

Formatters (in mise): `prettier` (TS/JSON/YAML/MD), `shfmt` (shell),
`taplo` (TOML), `rustfmt` (rust toolchain).

### chezmoi
- **chezmoi.el** — edit/diff/apply chezmoi-managed files from inside Emacs
  (knows the `private_dot_emacs.d/init.el` → `~/.emacs.d/init.el` mapping).

## mise tooling (`conf.d/fresh.toml`)

Language servers (`npm:` backend) and formatters (registry short names) install
fleet-wide via the shared baseline. To keep them off headless boxes, move the
"Emacs dev tooling" block to `~/.config/mise/config.local.toml`.

| Tool | mise entry | Backs |
|------|-----------|-------|
| typescript-language-server | `npm:typescript-language-server` | TS/JS/TSX (Eglot) |
| yaml-language-server | `npm:yaml-language-server` | YAML (Eglot) |
| vscode-langservers-extracted | `npm:vscode-langservers-extracted` | JSON/CSS/HTML (Eglot) |
| bash-language-server | `npm:bash-language-server` | Bash (Eglot) |
| dockerfile-language-server-nodejs | `npm:dockerfile-language-server-nodejs` | Dockerfile (Eglot) |
| marksman | `marksman` | Markdown LSP |
| prettier | `prettier` | format TS/JSON/YAML/MD |
| shfmt | `shfmt` | format shell |
| taplo | `taplo` | format TOML |

rust-analyzer + rustfmt come with the rust toolchain. If rust-analyzer is
missing: `rustup component add rust-analyzer rustfmt`.

## Keybindings (non-default)

| Key | Action |
|-----|--------|
| `C-x g` | `magit-status` |
| `C-c f` | `apheleia-format-buffer` (format once) |
| `C-c z f` | `fzf-find-file` |
| `C-c z g` | `fzf-git-files` |
| `C-c z b` | `fzf-switch-buffer` |
| `C-c z e` | `fzf-recentf` |
| `C-c z r` | `fzf-grep-dwim` (ripgrep, symbol at point) |
| `C-c z R` | `fzf-grep` (ripgrep, prompt) |
| `g` (markdown command map) | `grip-mode` preview |

---

## TODO: Clojure / ClojureScript layer

Neither dotfiles nor silicon-grove uses Clojure today, so this layer is staged
but inert. The pieces:

| Piece | Package / tool | Role |
|-------|----------------|------|
| Major mode | `clojure-ts-mode` | tree-sitter clj/cljs/edn |
| REPL / IDE | `cider` | nREPL REPL, eval-in-buffer, debugger; drives cljs via shadow-cljs/figwheel |
| Structural edit | `paredit` | already configured — extend hook to clojure modes |
| Linting | `clj-kondo` + `flycheck-clj-kondo` | static analysis |
| Refactor | `clj-refactor` | optional |
| LSP | `clojure-lsp` via Eglot | nav/completion (coexists with CIDER) |

**Coexistence:** run CIDER for the live REPL and clojure-lsp (Eglot) for
navigation/completion — the standard combo. For ClojureScript, CIDER connects
to a `shadow-cljs` or `figwheel-main` REPL; no extra Emacs package needed.

### Emacs side — add to `init.el` to enable

```elisp
(use-package clojure-ts-mode)             ; tree-sitter clj/cljs/edn mode
(use-package cider                        ; REPL + interactive dev
  :hook (clojure-ts-mode . cider-mode))
(use-package clj-refactor                 ; optional: threading/extract/etc
  :hook (clojure-ts-mode . clj-refactor-mode))
(use-package flycheck-clj-kondo)          ; clj-kondo static linting
(add-hook 'clojure-ts-mode-hook
          (lambda ()
            (electric-pair-local-mode -1)
            (enable-paredit-mode)))
(add-hook 'clojure-ts-mode-hook #'eglot-ensure)  ; needs clojure-lsp on PATH
```

### mise side — uncomment in `conf.d/fresh.toml`

```toml
clojure   = "latest"  # clj / clojure CLI (deps.edn, tools.build)
babashka  = "latest"  # bb: fast-startup Clojure scripting (shell-script killer)
clj-kondo = "latest"  # linter
"github:clojure-lsp/clojure-lsp" = "latest"  # LSP server for Eglot
# leiningen = "latest"  # optional classic build tool
```

> **babashka** is interesting on its own merits, independent of an Emacs Clojure
> setup — fast-startup Clojure for scripting, a candidate to take over scripting
> currently done in Bun. Can be enabled standalone.

### Naming footnote

The **marginalia** in this config is the *minibuffer-annotations* package
(~2021). It is **not** the older Clojure **Marginalia** literate-docs generator
(gdeer81) of around a decade ago — same name, different tool.
