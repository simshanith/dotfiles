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
| `g` | `grip-mode` | grip-mode | `markdown-mode-command-map` |
| `C-x g` | `magit-status` | magit | global |
| `C-c t` | `ghostel` | ghostel | global |
| `C-c z f` | `fzf-find-file` | fzf | global |
| `C-c z g` | `fzf-git-files` | fzf | global |
| `C-c z b` | `fzf-switch-buffer` | fzf | global |
| `C-c z e` | `fzf-recentf` | fzf | global |
| `C-c z r` | `fzf-grep-dwim` | fzf | global |
| `C-c z R` | `fzf-grep` | fzf | global |
| `C-c f` | `apheleia-format-buffer` | apheleia | global |
<!-- END GENERATED -->

## Notes

- **Keymap column**: `global` bindings work everywhere.
  `markdown-mode-command-map` hangs off the `C-c C-c` prefix in markdown
  buffers, so grip-mode is really `C-c C-c g` there.
- **Discovery**: `which-key-mode` is on (built-in since Emacs 30) — pause
  after any prefix (`C-c z`, `C-x`, `C-c C-c`) and the available continuations
  pop up. `C-h b` lists all bindings in the current buffer.
- **paredit** adds no `:bind` entries — it installs its own keymap via hooks
  in lisp buffers. See [paredit-cheatsheet.svg](paredit-cheatsheet.svg).
- **Fundamentals** (kill/yank, mark/region, windows, search):
  [gnu-emacs-refcard.pdf](gnu-emacs-refcard.pdf).
