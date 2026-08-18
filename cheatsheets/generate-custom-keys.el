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

(defconst gck-map-prefixes
  '((markdown-mode-command-map . "C-c C-c"))
  "Invoking chord for prefix keymaps that hang off another key.
Lets the Key column show the full sequence (e.g. `C-c C-c g`) instead of
just the leaf key — the prefix isn't derivable from init.el's :bind.")

(defun gck-full-key (key map)
  "Prepend MAP's invoking prefix chord to KEY when known (see `gck-map-prefixes')."
  (let ((prefix (and map (cdr (assq map gck-map-prefixes)))))
    (if prefix (concat prefix " " key) key)))

(defun gck-kbd (key)
  "Render KEY as <kbd> keycaps: one per chord, multi-chord sequences
nested inside a grouping outer <kbd> (MDN pattern)."
  (let ((chords (split-string key " " t)))
    (if (cdr chords)
        (format "<kbd>%s</kbd>"
                (mapconcat (lambda (c) (format "<kbd>%s</kbd>" c)) chords " "))
      (format "<kbd>%s</kbd>" key))))

(defun gck-render-table (header rows)
  "Render HEADER (column titles) and ROWS (lists of cells) as a column-aligned
GFM table, matching prettier's left-aligned padding so the generated block is
stable under the repo's markdown formatter."
  (let* ((cols (length header))
         (widths (cl-loop for i below cols collect
                          (cl-loop for r in (cons header rows)
                                   maximize (length (nth i r))))))
    (cl-flet ((fmt (cells)
                (concat
                 "| "
                 (mapconcat (lambda (i)
                              (let ((s (or (nth i cells) "")))
                                (concat s (make-string (- (nth i widths) (length s)) ?\s))))
                            (number-sequence 0 (1- cols)) " | ")
                 " |")))
      (concat (fmt header) "\n"
              "| " (mapconcat (lambda (w) (make-string w ?-)) widths " | ") " |\n"
              (mapconcat #'fmt rows "\n") "\n"))))

(defun gck-table ()
  "Render the bindings as a column-aligned GFM table."
  (gck-render-table
   '("Key" "Command" "Package" "Keymap")
   (mapcar
    (lambda (row)
      (pcase-let ((`(,pkg ,key ,cmd ,map) row))
        (list (gck-kbd (gck-full-key key map))
              (format "`%s`" cmd) (format "%s" pkg)
              (if map (format "`%s`" map) "global"))))
    (gck-bindings))))

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
              ;; Blank lines around the table: prettier inserts them around an HTML
              ;; comment either way, so emit them or --check fights the formatter.
              (insert "\n" table "\n")
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
