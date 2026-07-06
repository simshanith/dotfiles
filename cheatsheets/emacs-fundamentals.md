# Emacs fundamentals

Official GNU reference cards — linked, not vendored (they track Emacs releases upstream):

- [Refcards index](https://www.gnu.org/software/emacs/refcards/) — every card, all formats/translations
- [GNU Emacs refcard (PDF)](https://www.gnu.org/software/emacs/refcards/pdf/refcard.pdf) — the classic 2-page card: kill/yank, mark/region, buffers, windows, search, everything
- [Survival card (PDF)](https://www.gnu.org/software/emacs/refcards/pdf/survival.pdf) — 1-page bare minimum
- [Dired refcard (PDF)](https://www.gnu.org/software/emacs/refcards/pdf/dired-ref.pdf) — the file-manager buffer

## Mark, kill, yank — the core moves

| Key | Action |
|-----|--------|
| <kbd>C-SPC</kbd> | set mark; start selecting a region |
| <kbd><kbd>C-x</kbd> <kbd>C-x</kbd></kbd> | swap point and mark (see both ends of region) |
| <kbd><kbd>C-u</kbd> <kbd>C-SPC</kbd></kbd> | jump back to previous mark |
| <kbd>M-h</kbd> / <kbd><kbd>C-x</kbd> <kbd>h</kbd></kbd> | mark paragraph / whole buffer |
| <kbd>C-w</kbd> | kill (cut) region |
| <kbd>M-w</kbd> | copy region to kill ring |
| <kbd>C-k</kbd> | kill to end of line |
| <kbd>M-d</kbd> / <kbd>M-DEL</kbd> | kill word forward / backward |
| <kbd>C-y</kbd> | yank (paste) most recent kill |
| <kbd>M-y</kbd> | right after <kbd>C-y</kbd>: cycle back through earlier kills |
| <kbd>C-/</kbd> | undo (also <kbd><kbd>C-x</kbd> <kbd>u</kbd></kbd>) |

Everything killed lands on the **kill ring** — <kbd>C-y</kbd> then repeated <kbd>M-y</kbd> walks the whole history, so "clipboard" is plural in Emacs.

## Dired essentials

<kbd><kbd>C-x</kbd> <kbd>d</kbd></kbd> (or visit any directory) opens dired. Inside the buffer:

| Key | Action |
|-----|--------|
| <kbd>RET</kbd> / <kbd>o</kbd> | visit file (same / other window) |
| <kbd>^</kbd> | up to parent directory |
| <kbd>g</kbd> | refresh listing |
| <kbd>m</kbd> / <kbd>u</kbd> / <kbd>U</kbd> | mark file / unmark / unmark all |
| <kbd><kbd>%</kbd> <kbd>m</kbd></kbd> | mark files matching regexp |
| <kbd>d</kbd> then <kbd>x</kbd> | flag for deletion, then execute flags |
| <kbd>C</kbd> / <kbd>R</kbd> | copy / rename-or-move (marked files or file at point) |
| <kbd>+</kbd> | create directory |
| <kbd>!</kbd> / <kbd>&</kbd> | run shell command on file(s) (sync / async) |
| <kbd>q</kbd> | quit dired buffer |

Operations act on the **marked** files if any, else the file at point — the <kbd>m</kbd>-then-<kbd>C</kbd>/<kbd>R</kbd>/<kbd>!</kbd> pattern is the batch workflow.
