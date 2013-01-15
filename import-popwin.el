;;; import-popwin.el --- popwin buffer near by import statements with popwin

;; Copyright (C) 2013 by Syohei YOSHIDA

;; Author: Syohei YOSHIDA <syohex@gmail.com>
;; URL:
;; Version: 0.01
;; Package-Requires: ((popwin "0.6"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Inspired by http://shibayu36.hatenablog.com/entry/2013/01/03/223056

;;; Code:

(eval-when-compile
  (require 'cl))

(require 'popwin)

(defgroup import-popwin nil
  "popup buffer near by import statements"
  :group 'popwin)

(defcustom import-popwin:height 0.4
  "height of popwin buffer"
  :type 'number
  :group 'import-popwin)

(defcustom import-popwin:position 'bottom
  "position of popwin buffer"
  :type 'symbol
  :group 'import-popwin)

(defvar import-popwin:info nil)
(defvar import-popwin:info-properties
  '(:before :regexp :after :fallback))

(defun import-popwin:match-mode (mode modes)
  (cond ((listp modes) (member mode modes))
        (t (eq mode modes))))

(defun import-popwin:find-info (mode)
  (loop for info in import-popwin:info
        for modes = (car info)
        when (import-popwin:match-mode mode modes)
        return (cdr info)))

(defun import-popwin ()
  (interactive)
  (let ((info (import-popwin:find-info major-mode)))
    (unless info
      (error (format "%s information is not registered!!" major-mode)))
    (let ((before-func (plist-get info :before))
          (fallback-func (plist-get info :fallback))
          (after-func (plist-get info :after))
          (regexp (plist-get info :regexp)))
      (when before-func
        (save-excursion
          (funcall before-func)))
      (popwin:popup-buffer (current-buffer)
                           :height import-popwin:height
                           :position import-popwin:position)
      (goto-char (line-end-position))
      (or (re-search-backward regexp nil t)
          (and fallback-func
               (save-excursion
                 (funcall fallback-func)))
          (goto-char (point-min)))
      (forward-line 1)
      (recenter)
      (when after-func
        (save-excursion
          (funcall after-func))))))

(defun import-popwin:registered-info-p (mode-list)
  (loop for mode in mode-list
        when (loop for info in import-popwin:info
                   when (import-popwin:match-mode mode (car info))
                   return info)
        return it))

(defun import-popwin:override-info (mode params oldinfo)
  (setcar oldinfo mode)
  (setcdr oldinfo params))

(defun import-popwin:add (&rest plist)
  (let ((mode (plist-get plist :mode))
        (params (loop for prop in import-popwin:info-properties
                      append (list prop (plist-get plist prop)))))
    (unless mode
      (error "missing :mode parameter"))
    (let* ((mode-list (if (listp mode)
                          mode
                        (list mode)))
           (registered-info (import-popwin:registered-info-p mode-list)))
      (if registered-info
          (import-popwin:override-info mode-list params registered-info)
        (push (cons mode-list params) import-popwin:info)))))

;; configuration
(import-popwin:add :mode '(c-mode c++-mode)
                   :regexp "^#include")

(import-popwin:add :mode '(cperl-mode perl-mode)
                   :regexp "^\\s-*use\\s-*[^;]+;")

(import-popwin:add :mode 'ruby-mode
                   :regexp "^require\\s-")

(import-popwin:add :mode 'python-mode
                   :regexp "^\\(import\\|from\\)\\s-+")

(import-popwin:add :mode 'emacs-lisp-mode
                   :regexp "^\\s-*(require\\s-+")

(provide 'import-popwin)

;;; import-popwin.el ends here