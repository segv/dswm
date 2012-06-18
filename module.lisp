;; Copyright (C) 2008 Julian Stecklina, Shawn Betts, Ivy Foster
;;
;;  This file is part of dswm.
;;
;; dswm is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; dswm is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this software; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place, Suite 330,
;; Boston, MA 02111-1307 USA

;; Commentary:
;;
;; Use `add-modules-dir' to add the location dswm searches for modules.

;; Directories with external modules:
;;
;; * $PREFIX/share/modules
;; * ~/.dswm.d/modules
;; * user-defined-dir

;; Code:

(in-package #:dswm)

(export '(load-module
          modules-list
	  add-modules-dir
          find-module))

(defun add-modules-dir (dir)
  "Add the location of the contrib modules"
  (push (string-as-directory dir) asdf:*central-registry*))

;; Add default modules directories
(add-modules-dir "${prefix}/share/dswm/modules/")
(push (data-dir "/modules/") asdf:*central-registry*)

(define-dswm-type :module (input prompt)
  (or (argument-pop-rest input)
      (completing-read (current-screen) prompt (modules-list) :require-match t)))

(defun modules-list ()
  "Return a list of the available modules."
  (let ((mod-list nil))
    (dolist (module-path asdf:*central-registry*)
      (dolist (subpath (list-directory module-path))
	(let ((local-name (car (last (pathname-directory subpath)))))
	  (when (and (not (member local-name mod-list))
		     (file-exists-p (make-pathname :defaults subpath :name local-name :type "asd")))
	    (push local-name mod-list)))))
    mod-list))

(defun find-system-file (name)
  "Find module from list avaliable modules FIXME: test"
  (labels ((system-p (dir-list name)
	     (let ((system
		    (make-pathname :directory (concat (princ-to-string (car dir-list)) "/" name)
				   :name name :type "asd")))
	       (cond ((null dir-list) nil)
		     ((file-exists-p system) system)
		     (t (system-p (cdr dir-list) name))))))
    (system-p asdf:*central-registry* name)))

(defcommand load-module (name) ((:module "Input module name: "))
  "Loads the contributed module with the given NAME."
  (let ((dir (dirname (find-system-file name))))
    (push dir asdf:*central-registry*)
    (require name)))

(defcommand list-modules () ()
  (let ((list nil))
    (dolist (w (modules-list))
      (setf list (concat w "~%" list)))
    (if (not (null list))
	(message (format nil "~a" list))
	(message "No modules found"))))

(defcommand module-info (name) ((:module "Input module name: "))
  "Shows full information about module"
  (load (find-system-file name))
  (let* ((module (asdf:find-system name))
	 (module-description
	  (handler-case (format nil "No description")
	    (unbound-slot () (asdf:system-description module))))
	 (module-author
	  (handler-case (format nil "Unknown")
	    (unbound-slot () (asdf:system-author module))))
	 (module-maintainer
	  (handler-case (format nil "Unknown")
	    (unbound-slot () (asdf:system-maintainer module))))
	 ;; (module-version
	 ;;  (handler-case (format nil "Unknown")
	 ;;    (unbound-slot () (asdf:system-version module))))
	 (module-licence
	  (handler-case (format nil "No one defined (`as is'?)")
	    (unbound-slot () (asdf:system-licence module)))))
    (message (format nil "Name:~20t~a~%Description:~20t~a~%Author:~20t~a~%Maintainer:~20t~a~%Licence:~20t~a~%"
		     name module-description module-author module-maintainer module-licence))))

;; End of file