# Emacs fundamentals

Official GNU reference cards — linked, not vendored (they track Emacs releases upstream):

- [Refcards index](https://www.gnu.org/software/emacs/refcards/) — every card, all formats/translations
- [GNU Emacs refcard (PDF)](https://www.gnu.org/software/emacs/refcards/pdf/refcard.pdf) — the classic 2-page card: kill/yank, mark/region, buffers, windows, search, everything
- [Survival card (PDF)](https://www.gnu.org/software/emacs/refcards/pdf/survival.pdf) — 1-page bare minimum
- [Dired refcard (PDF)](https://www.gnu.org/software/emacs/refcards/pdf/dired-ref.pdf) — the file-manager buffer

## Mark, kill, yank — the core moves

| Key | Action |
|-----|--------|
| `C-SPC` | set mark; start selecting a region |
| `C-x C-x` | swap point and mark (see both ends of region) |
| `C-u C-SPC` | jump back to previous mark |
| `M-h` / `C-x h` | mark paragraph / whole buffer |
| `C-w` | kill (cut) region |
| `M-w` | copy region to kill ring |
| `C-k` | kill to end of line |
| `M-d` / `M-DEL` | kill word forward / backward |
| `C-y` | yank (paste) most recent kill |
| `M-y` | right after `C-y`: cycle back through earlier kills |
| `C-/` | undo (also `C-x u`) |

Everything killed lands on the **kill ring** — `C-y` then repeated `M-y` walks the whole history, so "clipboard" is plural in Emacs.

## Dired essentials

`C-x d` (or visit any directory) opens dired. Inside the buffer:

| Key | Action |
|-----|--------|
| `RET` / `o` | visit file (same / other window) |
| `^` | up to parent directory |
| `g` | refresh listing |
| `m` / `u` / `U` | mark file / unmark / unmark all |
| `% m` | mark files matching regexp |
| `d` then `x` | flag for deletion, then execute flags |
| `C` / `R` | copy / rename-or-move (marked files or file at point) |
| `+` | create directory |
| `!` / `&` | run shell command on file(s) (sync / async) |
| `q` | quit dired buffer |

Operations act on the **marked** files if any, else the file at point — the `m`-then-`C`/`R`/`!` pattern is the batch workflow.
