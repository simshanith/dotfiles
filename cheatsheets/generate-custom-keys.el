;;; generate-custom-keys.el --- Regenerate custom-keybindings.md -*- lexical-binding: t; -*-

;; Extracts every `use-package' :bind entry from private_dot_emacs.d/init.el
;; and rewrites the table between the GENERATED markers in
;; cheatsheets/custom-keybindings.md. Run it after changing any :bind:
;;
;;   emacs --batch -l cheatsheets/generate-custom-keys.el
;;
;; Pass --check to exit non-zero (without writing) when the table is stale:
;;
;;   emacs --batch -l cheatsheets/generate-custom-keys.el -- --check

;;; Code:

(require 'cl-lib)

(defconst gck-root
  (file-name-directory
   (directory-file-name (file-name-directory load-file-name)))
  "Repo root (parent of the cheatsheets/ directory).")

(defconst gck-init-file (expand-file-name "private_dot_emacs.d/init.el" gck-root))
(defconst gck-md-file (expand-file-name "cheatsheets/custom-keybindings.md" gck-root))

(defun gck-read-forms (file)
  "Read all top-level sexps from FILE."
  (with-temp-buffer
    (insert-file-contents file)
    (let (forms)
      (condition-case nil
          (while t (push (read (current-buffer)) forms))
        (end-of-file))
      (nreverse forms))))

(defun gck-collect-use-package (form)
  "Return all (use-package ...) sexps in FORM, in source order.
Walks nested forms so packages wrapped in `when' etc. are found too."
  (let (acc)
    (cl-labels ((walk (f)
                  (when (consp f)
                    (if (eq (car f) 'use-package)
                        (push f acc)
                      (let ((tail f))
                        (while (consp tail)
                          (walk (car tail))
                          (setq tail (cdr tail))))))))
      (walk form))
    (nreverse acc)))

(defun gck-parse-bind (pkg spec map)
  "Flatten a use-package :bind SPEC for PKG into (PKG KEY CMD MAP) rows."
  (cond
   ;; Single pair: ("C-x g" . magit-status)
   ((and (consp spec) (stringp (car spec)))
    (list (list pkg (car spec) (cdr spec) map)))
   ;; List: pairs, possibly with :map / :prefix markers interleaved
   ((consp spec)
    (let ((items spec) (cur-map map) rows)
      (while items
        (let ((it (car items)))
          (cond
           ((eq it :map)
            (setq items (cdr items) cur-map (car items)))
           ((memq it '(:prefix :prefix-map :prefix-docstring))
            (setq items (cdr items)))     ; skip marker's value
           ((and (consp it) (stringp (car it)))
            (push (list pkg (car it) (cdr it) cur-map) rows))))
        (setq items (cdr items)))
      (nreverse rows)))))

(defun gck-bindings ()
  "All :bind rows from init.el, in source order."
  (let (rows)
    (dolist (form (gck-read-forms gck-init-file))
      (dolist (up (gck-collect-use-package form))
        (let ((pkg (cadr up))
              (rest (cddr up)))
          (while rest
            (when (memq (car rest) '(:bind :bind*))
              (setq rows (nconc rows (gck-parse-bind pkg (cadr rest) nil))))
            (setq rest (cdr rest))))))
    rows))

(defun gck-table ()
  "Render the bindings as a GFM table."
  (concat
   "| Key | Command | Package | Keymap |\n"
   "|-----|---------|---------|--------|\n"
   (mapconcat
    (lambda (row)
      (pcase-let ((`(,pkg ,key ,cmd ,map) row))
        (format "| <kbd>%s</kbd> | `%s` | %s | %s |"
                key cmd pkg (if map (format "`%s`" map) "global"))))
    (gck-bindings) "\n")
   "\n"))

(let* ((check (member "--check" command-line-args-left))
       (table (gck-table))
       (old (with-temp-buffer
              (insert-file-contents gck-md-file)
              (buffer-string)))
       (new (with-temp-buffer
              (insert old)
              (goto-char (point-min))
              (re-search-forward "^<!-- BEGIN GENERATED — edit init\\.el, not this table -->\n")
              (let ((start (point)))
                (re-search-forward "^<!-- END GENERATED -->")
                (delete-region start (match-beginning 0)))
              (goto-char (point-min))
              (re-search-forward "^<!-- BEGIN GENERATED — edit init\\.el, not this table -->\n")
              (insert table)
              (buffer-string))))
  (cond
   ((string= old new)
    (message "custom-keybindings.md is up to date"))
   (check
    (message "custom-keybindings.md is STALE — run: emacs --batch -l cheatsheets/generate-custom-keys.el")
    (kill-emacs 1))
   (t
    (with-temp-file gck-md-file (insert new))
    (message "custom-keybindings.md updated"))))

;;; generate-custom-keys.el ends here
