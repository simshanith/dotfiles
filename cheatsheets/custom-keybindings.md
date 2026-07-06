# Custom Emacs keybindings

Every keybinding this config adds on top of stock Emacs, extracted from the
`:bind` declarations in `private_dot_emacs.d/init.el`.

The table below is **generated** — after changing any `:bind` in init.el,
regenerate it with:

```bash
emacs --batch -l cheatsheets/generate-custom-keys.el
```

(`--check` mode exits non-zero if it's stale: append `-- --check`.)

<!-- BEGIN GENERATED — edit init.el, not this table -->
| Key | Command | Package | Keymap |
|-----|---------|---------|--------|
| <kbd>g</kbd> | `grip-mode` | grip-mode | `markdown-mode-command-map` |
| <kbd><kbd>C-x</kbd> <kbd>g</kbd></kbd> | `magit-status` | magit | global |
| <kbd><kbd>C-c</kbd> <kbd>t</kbd></kbd> | `ghostel` | ghostel | global |
| <kbd><kbd>C-c</kbd> <kbd>z</kbd> <kbd>f</kbd></kbd> | `fzf-find-file` | fzf | global |
| <kbd><kbd>C-c</kbd> <kbd>z</kbd> <kbd>g</kbd></kbd> | `fzf-git-files` | fzf | global |
| <kbd><kbd>C-c</kbd> <kbd>z</kbd> <kbd>b</kbd></kbd> | `fzf-switch-buffer` | fzf | global |
| <kbd><kbd>C-c</kbd> <kbd>z</kbd> <kbd>e</kbd></kbd> | `fzf-recentf` | fzf | global |
| <kbd><kbd>C-c</kbd> <kbd>z</kbd> <kbd>r</kbd></kbd> | `fzf-grep-dwim` | fzf | global |
| <kbd><kbd>C-c</kbd> <kbd>z</kbd> <kbd>R</kbd></kbd> | `fzf-grep` | fzf | global |
| <kbd><kbd>C-c</kbd> <kbd>f</kbd></kbd> | `apheleia-format-buffer` | apheleia | global |
<!-- END GENERATED -->

## What each package does

One-liners for when the command name isn't enough; full write-ups in
[emacs.md](../emacs.md) under "What's installed and why".

- **magit** — the git porcelain. <kbd><kbd>C-x</kbd> <kbd>g</kbd></kbd> opens
  the status buffer; everything else keys off it.
- **ghostel** — embedded terminal on libghostty-vt (Ghostty's VT engine),
  themed to match standalone Ghostty. <kbd><kbd>C-c</kbd> <kbd>t</kbd></kbd>
  opens one.
- **fzf** — terminal `fzf` in a popup buffer for file/buffer jumps and
  whole-repo ripgrep. Complements (doesn't replace) the vertico minibuffer.
- **apheleia** — code formatter (prettier/shfmt/taplo/rustfmt via mise).
  <kbd><kbd>C-c</kbd> <kbd>f</kbd></kbd> formats the buffer **once**;
  format-on-save stays OFF unless you toggle <kbd>M-x</kbd>
  `apheleia-global-mode` for the session.
- **grip-mode** — GitHub-accurate live preview of the current markdown buffer
  in a browser (the `grip` CLI is in the mise baseline as `pipx:grip`).

## Notes

- **Keymap column**: `global` bindings work everywhere.
  `markdown-mode-command-map` hangs off the
  <kbd><kbd>C-c</kbd> <kbd>C-c</kbd></kbd> prefix in markdown buffers, so
  grip-mode is really <kbd><kbd>C-c</kbd> <kbd>C-c</kbd> <kbd>g</kbd></kbd>
  there.
- **Discovery**: `which-key-mode` is on (built-in since Emacs 30) — pause
  after any prefix (<kbd><kbd>C-c</kbd> <kbd>z</kbd></kbd>, <kbd>C-x</kbd>,
  <kbd><kbd>C-c</kbd> <kbd>C-c</kbd></kbd>) and the available continuations
  pop up. <kbd><kbd>C-h</kbd> <kbd>b</kbd></kbd> lists all bindings in the
  current buffer.
- **paredit** adds no `:bind` entries — it installs its own keymap via hooks
  in lisp buffers. See [paredit-cheatsheet.svg](paredit-cheatsheet.svg).
- **Fundamentals** (kill/yank, mark/region, dired, GNU refcard links):
  [emacs-fundamentals.md](emacs-fundamentals.md).
