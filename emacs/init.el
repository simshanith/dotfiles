;;; https://github.com/technomancy/emacs-starter-kit
(require 'package)
(add-to-list 'package-archives '("marmalade" . "https://marmalade-repo.org/packages/"))
(add-to-list 'package-archives '("melpa-stable" . "http://stable.melpa.org/packages/") t)

(defvar my-packages '(better-defaults paredit idle-highlight-mode ido-ubiquitous
                                      color-theme color-theme-solarized
                                      find-file-in-project magit smex scpaste))

(package-initialize)
(dolist (p my-packages)
  (when (not (package-installed-p p))
    (package-install p)))

(color-theme-solarized-dark)
