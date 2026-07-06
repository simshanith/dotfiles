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
| <kbd>C-x g</kbd> | `magit-status` | magit | global |
| <kbd>C-c t</kbd> | `ghostel` | ghostel | global |
| <kbd>C-c z f</kbd> | `fzf-find-file` | fzf | global |
| <kbd>C-c z g</kbd> | `fzf-git-files` | fzf | global |
| <kbd>C-c z b</kbd> | `fzf-switch-buffer` | fzf | global |
| <kbd>C-c z e</kbd> | `fzf-recentf` | fzf | global |
| <kbd>C-c z r</kbd> | `fzf-grep-dwim` | fzf | global |
| <kbd>C-c z R</kbd> | `fzf-grep` | fzf | global |
| <kbd>C-c f</kbd> | `apheleia-format-buffer` | apheleia | global |
<!-- END GENERATED -->

## What each package does

One-liners for when the command name isn't enough; full write-ups in
[emacs.md](../emacs.md) under "What's installed and why".

- **magit** — the git porcelain. <kbd>C-x g</kbd> opens the status buffer;
  everything else keys off it.
- **ghostel** — embedded terminal on libghostty-vt (Ghostty's VT engine),
  themed to match standalone Ghostty. <kbd>C-c t</kbd> opens one.
- **fzf** — terminal `fzf` in a popup buffer for file/buffer jumps and
  whole-repo ripgrep. Complements (doesn't replace) the vertico minibuffer.
- **apheleia** — code formatter (prettier/shfmt/taplo/rustfmt via mise).
  <kbd>C-c f</kbd> formats the buffer **once**; format-on-save stays OFF
  unless you toggle <kbd>M-x</kbd> `apheleia-global-mode` for the session.
- **grip-mode** — GitHub-accurate live preview of the current markdown buffer
  in a browser (the `grip` CLI is in the mise baseline as `pipx:grip`).

## Notes

- **Keymap column**: `global` bindings work everywhere.
  `markdown-mode-command-map` hangs off the <kbd>C-c C-c</kbd> prefix in
  markdown buffers, so grip-mode is really <kbd>C-c C-c g</kbd> there.
- **Discovery**: `which-key-mode` is on (built-in since Emacs 30) — pause
  after any prefix (<kbd>C-c z</kbd>, <kbd>C-x</kbd>, <kbd>C-c C-c</kbd>) and
  the available continuations pop up. <kbd>C-h b</kbd> lists all bindings in
  the current buffer.
- **paredit** adds no `:bind` entries — it installs its own keymap via hooks
  in lisp buffers. See [paredit-cheatsheet.svg](paredit-cheatsheet.svg).
- **Fundamentals** (kill/yank, mark/region, dired, GNU refcard links):
  [emacs-fundamentals.md](emacs-fundamentals.md).
