;;; init.el --- Emacs config for dotfiles + silicon-grove dev -*- lexical-binding: t; -*-

;;; Package bootstrap ---------------------------------------------------------
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)
;; Refresh the MELPA index on first run or when it's stale. MELPA keeps only
;; the latest build of each package, so an outdated index makes use-package
;; request version strings that 404. A periodic refresh self-heals that.
(let* ((archive (expand-file-name "elpa/archives/melpa/archive-contents"
                                  user-emacs-directory))
       (mtime (or (file-attribute-modification-time (file-attributes archive)) 0)))
  (when (or (not package-archive-contents)
            (> (float-time (time-since mtime)) (* 7 24 60 60)))  ; 7 days
    (package-refresh-contents)))

;; use-package is built into Emacs 29+. Make every declaration self-installing.
(require 'use-package)
(setq use-package-always-ensure t)

;; Keep Customize's auto-writes out of this chezmoi-managed file: send them to
;; a separate, un-managed custom.el so `chezmoi apply` never fights with Emacs.
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file)
  (load custom-file))

;;; Built-in quality-of-life ---------------------------------------------------
(use-package emacs
  :ensure nil
  :init
  (savehist-mode 1)                       ; persist minibuffer history
  (recentf-mode 1)                        ; recent files
  (electric-pair-mode 1)                  ; auto-close brackets/quotes
  (which-key-mode 1)                      ; built-in since Emacs 30
  ;; Keep backup (foo~), auto-save (#foo#), and lock (.#foo) files out of the
  ;; working tree — corral them under ~/.emacs.d/ so they never litter repos.
  (let ((backup-dir (expand-file-name "backups/" user-emacs-directory))
        (auto-save-dir (expand-file-name "auto-saves/" user-emacs-directory)))
    (make-directory backup-dir t)
    (make-directory auto-save-dir t)
    (setq backup-directory-alist `((".*" . ,backup-dir))
          auto-save-file-name-transforms `((".*" ,auto-save-dir t))
          auto-save-list-file-prefix (expand-file-name ".saves-" auto-save-dir)
          ;; .#foo lock files are usually the real annoyance on a single-user
          ;; machine; disable them. (Keep them if you edit over shared/NFS dirs.)
          create-lockfiles nil
          backup-by-copying t              ; don't break hardlinks/symlinks
          version-control t delete-old-versions t
          kept-new-versions 6 kept-old-versions 2))
  :hook (prog-mode . display-line-numbers-mode)
  :custom
  (inhibit-startup-screen t))

;;; Environment ---------------------------------------------------------------
;; GUI Emacs launched from the Dock/Spotlight gets launchd's minimal PATH, not
;; the shell's — so it can't see mise shims and Eglot can't find language
;; servers. Import PATH from a *login* shell (-l), which sources ~/.zprofile
;; (where the mise shims live) but skips the heavy interactive ~/.zshrc.
;; Gated to GUI sessions: a no-op on terminal/headless boxes that already
;; inherit PATH.
(use-package exec-path-from-shell
  :when (memq window-system '(mac ns))
  :init (setq exec-path-from-shell-arguments '("-l"))
  :config (exec-path-from-shell-initialize))

;;; Theme + font (self-installing so a fresh machine reproduces it) -----------
(use-package color-theme-sanityinc-solarized
  :config
  (load-theme 'sanityinc-solarized-dark t))

(set-face-attribute 'default nil :font "Operator Mono SSm Book-11")

;; better-defaults: sane editing baseline (now from MELPA, was a local clone).
(use-package better-defaults)

;;; Tree-sitter ---------------------------------------------------------------
;; Emacs 30 ships the *-ts-mode major modes but not the grammars.
;; treesit-auto installs missing grammars on demand and remaps file types
;; (ts/tsx/js/json/yaml/toml/rust/bash/dockerfile/css/html/...) to *-ts-mode.
;; Grammars live under ~/.emacs.d/tree-sitter (kept out of /usr/local/lib so
;; Homebrew doesn't flag them as unbrewed dylibs).
(setq treesit-extra-load-path
      (list (expand-file-name "tree-sitter" user-emacs-directory)))
(use-package treesit-auto
  :custom
  (treesit-auto-install 'prompt)          ; ask before downloading a grammar
  :config
  (treesit-auto-add-to-auto-mode-alist 'all)
  ;; treesit-auto's JavaScript recipe only claims .js/.jsx, so the ESM/CJS
  ;; extensions would otherwise fall through to fundamental-mode.
  (add-to-list 'auto-mode-alist '("\\.[cm]js\\'" . js-ts-mode))
  (global-treesit-auto-mode))

;;; Markdown ------------------------------------------------------------------
(use-package markdown-mode
  :mode (("README\\.md\\'" . gfm-mode)
         ("\\.md\\'"       . gfm-mode))
  :custom
  (markdown-command "pandoc")
  (markdown-fontify-code-blocks-natively t) ; highlight fenced ```ts blocks
  :hook (markdown-mode . visual-line-mode))

;; GitHub-accurate live preview (requires `grip`, in the mise baseline as
;; pipx:grip — installed via `uv tool` under the hood).
(use-package grip-mode
  :bind (:map markdown-mode-command-map ("g" . grip-mode)))

;;; LSP via Eglot (built-in) --------------------------------------------------
(use-package eglot
  :ensure nil
  :hook ((typescript-ts-mode . eglot-ensure)
         (tsx-ts-mode        . eglot-ensure)
         (js-ts-mode         . eglot-ensure)
         (rust-ts-mode       . eglot-ensure)
         (yaml-ts-mode       . eglot-ensure)
         (json-ts-mode       . eglot-ensure)
         (bash-ts-mode       . eglot-ensure)
         (dockerfile-ts-mode . eglot-ensure)))

;;; Completion: corfu (in-buffer) + vertico (minibuffer) ----------------------
(use-package corfu
  :init (global-corfu-mode)
  :custom
  (corfu-auto t)
  (corfu-cycle t))

(use-package cape
  :init
  (add-to-list 'completion-at-point-functions #'cape-file)
  (add-to-list 'completion-at-point-functions #'cape-dabbrev))

(use-package vertico
  :init (vertico-mode))

(use-package marginalia
  :init (marginalia-mode))

(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles partial-completion)))))

;;; Git -----------------------------------------------------------------------
(use-package magit
  :bind ("C-x g" . magit-status))

;;; Terminal — ghostel ---------------------------------------------------------
;; Terminal emulator on libghostty-vt; prebuilt native module auto-downloads on
;; first `M-x ghostel` (no compile step). Gated on module support so a
;; stripped/headless build no-ops instead of erroring. `module-file-suffix` is
;; the canonical test (non-nil iff modules are supported); `dynamic-modules`
;; isn't pushed onto `features` on every build, so don't gate on featurep.
;; ghostel ships ~daily and MELPA keeps only the newest build, so the 7-day
;; refresh above is too wide: a stale index 404s on a fresh install. Refresh
;; just-in-time, before the install.
;;   C-c t -> open a ghostel terminal
(when module-file-suffix
  (unless (package-installed-p 'ghostel)
    (package-refresh-contents))
  (use-package ghostel
    :bind ("C-c t" . ghostel)
    ;; ghostel renders ANSI colors through these faces (each inherits the stock
    ;; ansi-color-*), so the palette follows the Emacs theme, NOT
    ;; ~/.config/ghostty. Pin all 16 + default fg/bg to the Ghostty "iTerm2
    ;; Solarized Dark" hexes so the embedded terminal matches standalone Ghostty.
    :custom-face
    (ghostel-default              ((t (:foreground "#839496" :background "#002b36"))))
    (ghostel-color-black          ((t (:foreground "#073642"))))
    (ghostel-color-red            ((t (:foreground "#dc322f"))))
    (ghostel-color-green          ((t (:foreground "#859900"))))
    (ghostel-color-yellow         ((t (:foreground "#b58900"))))
    (ghostel-color-blue           ((t (:foreground "#268bd2"))))
    (ghostel-color-magenta        ((t (:foreground "#d33682"))))
    (ghostel-color-cyan           ((t (:foreground "#2aa198"))))
    (ghostel-color-white          ((t (:foreground "#eee8d5"))))
    (ghostel-color-bright-black   ((t (:foreground "#335e69"))))
    (ghostel-color-bright-red     ((t (:foreground "#cb4b16"))))
    (ghostel-color-bright-green   ((t (:foreground "#586e75"))))
    (ghostel-color-bright-yellow  ((t (:foreground "#657b83"))))
    (ghostel-color-bright-blue    ((t (:foreground "#839496"))))
    (ghostel-color-bright-magenta ((t (:foreground "#6c71c4"))))
    (ghostel-color-bright-cyan    ((t (:foreground "#93a1a1"))))
    (ghostel-color-bright-white   ((t (:foreground "#fdf6e3"))))))

;;; Fuzzy finding — fzf.el -----------------------------------------------------
;; Terminal `fzf` driven from a popup term buffer. Complements the minibuffer
;; stack (vertico/orderless): great for fast git-tracked file jumps and
;; whole-repo content grep. Needs the `fzf` binary (mise baseline) plus `rg`
;; for the grep commands — both already installed fleet-wide.
;;   C-c z f -> find file under default-directory   (fzf-find-file)
;;   C-c z g -> git-tracked files in the repo        (fzf-git-files)
;;   C-c z b -> switch buffer                         (fzf-switch-buffer)
;;   C-c z e -> recent files                          (fzf-recentf)
;;   C-c z r -> ripgrep content, seed from symbol     (fzf-grep-dwim)
;;   C-c z R -> ripgrep content, prompt for pattern   (fzf-grep)
(use-package fzf
  :bind (("C-c z f" . fzf-find-file)
         ("C-c z g" . fzf-git-files)
         ("C-c z b" . fzf-switch-buffer)
         ("C-c z e" . fzf-recentf)
         ("C-c z r" . fzf-grep-dwim)
         ("C-c z R" . fzf-grep))
  :custom
  ;; Use ripgrep for fzf-grep-* (default is `grep -nrH`); rg honors .gitignore
  ;; and is the rest-of-fleet's grep already.
  (fzf/grep-command "rg --no-heading -nH --color=always"))

;;; Editing polish ------------------------------------------------------------
(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

;; paredit: structural editing for lisps. Let it own parens in lisp buffers,
;; so turn off the global electric-pair-mode there to avoid double-inserts.
(use-package paredit
  :hook ((emacs-lisp-mode lisp-interaction-mode lisp-mode ielm-mode)
         . (lambda ()
             (electric-pair-local-mode -1)
             (enable-paredit-mode))))

;;; Formatting ----------------------------------------------------------------
;; Installed but format-on-save is OFF by default.
;;   C-c f             -> format the current buffer once
;;   M-x apheleia-global-mode -> toggle format-on-save for the session
(use-package apheleia
  :bind ("C-c f" . apheleia-format-buffer))

;;; chezmoi -------------------------------------------------------------------
;; Edit/diff/apply chezmoi-managed files from inside Emacs.
(use-package chezmoi)

;; Clojure / ClojureScript: not used yet. The staged layer (CIDER, paredit,
;; clojure-lsp, mise tooling) is documented in ~/.dotfiles/emacs.md.

;;; init.el ends here
