;;; early-init.el --- pre-init environment setup -*- lexical-binding: t; -*-

;; Emacs native-compilation (libgccjit) shells out to the gcc driver to link
;; each .eln.  On Homebrew macOS the gcc runtime libs it needs (libemutls_w.a,
;; libgcc, ...) live under gcc's version-specific libexec dir, which is NOT on
;; the default linker search path.  Without this, native-comp fails with:
;;   ld: library 'emutls_w' not found
;;   libgccjit.so: error: error invoking gcc driver
;;   Internal native compiler error: "failed to compile" ... "error invoking gcc driver"
;;
;; NOTE: an elisp `(setenv "LIBRARY_PATH" ...)` does NOT fix this -- libgccjit
;; invokes the driver at the C level using the C `environ`, which elisp setenv
;; never touches (it only updates `process-environment`).  The supported knob is
;; `native-comp-driver-options`, whose strings are passed straight to the gcc
;; driver; a `-L<dir>` for each gcc lib dir makes `ld` find libemutls_w.a et al.
;;
;; The variable's `defcustom` lives in comp.el, which is NOT loaded this early,
;; so the symbol is unbound here -- we `setq` (assign only, never read) it to a
;; fresh list.  A plain assignment binds it fine, and comp.el's later defcustom
;; won't clobber an already-bound value.  (Reading it here -- e.g. to append --
;; would signal "Symbol's value as variable is void" and abort early-init.)
;;
;; Dirs are globbed at runtime from the stable Homebrew `opt` symlinks, so this
;; survives gcc major bumps (…/16 -> …/17) and arch/OS-version changes
;; (aarch64-apple-darwin25) without edits.  A no-op off macOS, on a machine
;; without a Homebrew gcc, or when native-comp isn't available.
(when (and (eq system-type 'darwin)
           (fboundp 'native-comp-available-p)
           (native-comp-available-p))
  (let ((candidates
         (append
          ;; version-stable `current` dir
          (list "/opt/homebrew/opt/gcc/lib/gcc/current"
                "/usr/local/opt/gcc/lib/gcc/current")
          ;; the leaf holding libemutls_w.a: …/current/gcc/<triple>/<ver>/
          (file-expand-wildcards "/opt/homebrew/opt/gcc/lib/gcc/current/gcc/*/*")
          (file-expand-wildcards "/usr/local/opt/gcc/lib/gcc/current/gcc/*/*")))
        (dirs '()))
    (dolist (d candidates)
      (when (file-directory-p d)
        (push d dirs)))
    (when dirs
      (setq native-comp-driver-options
            (mapcar (lambda (d) (concat "-L" d))
                    (nreverse dirs))))))

;;; early-init.el ends here
