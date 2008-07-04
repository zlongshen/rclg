;;; RCLG: R-CommonLisp Gateway

;;; Copyright (c) 2005--2007, <rif@mit.edu>
;;;                           AJ Rossini <blindglobe@gmail.com>
;;; All rights reserved.
;;;
;;; Redistribution and use in source and binary forms, with or without
;;; modification, are permitted provided that the following conditions are
;;; met:
;;;
;;;     * Redistributions of source code must retain the above copyright
;;;       notice, this list of conditions and the following disclaimer.
;;;     * Redistributions in binary form must reproduce the above
;;;       copyright notice, this list of conditions and the following disclaimer
;;;       in the documentation and/or other materials provided with the
;;;       distribution.
;;;     * The names of the contributors may not be used to endorse or
;;;       promote products derived from this software without specific
;;;       prior written permission.
;;;
;;; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
;;; "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
;;; LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
;;; A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
;;; OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
;;; SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
;;; LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
;;; DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
;;; THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
;;; (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
;;; OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


;;; Author:      rif@mit.edu
;;; Maintainers: rif@mit.edu,
;;;              AJ Rossini <blindglobe@gmail.com>


;;; Intent: initialize environment stuff.  Purely developer level, no
;;; user tools.

(asdf:oos 'asdf:load-op 'cffi) ;; FIXME:AJR: Ugly hack.  Do it right!

(defpackage :rclg-cffi-sysenv
  (:use :common-lisp :cffi)
  (:export :posix-setenv :posix-getenv
	   :add-new-cffi-lib-directory
	   :posix-setrlimit :posix-getrlimit))

(in-package :rclg-cffi-sysenv)

;;;* Environmental Variables using CFFI

(defcfun ("getenv" posix-getenv) :string
  (envname :string))

(defcfun ("setenv" posix-setenv) :int
  (envname :string) (envval :string) (overwrite :int))


;;;* Library loading for weird cases

;; Could be a string, pathname, or list consisting of strings and
;; pathnames.  Works on both CFFI load path and system "LD_LIBRARY_PATH".
;;(add-new-cffi-lib-directory #P"/usr/lib/R/library/grDevices/libs/") ; test, works
;;(add-new-cffi-directory "/lib")  ;test, works.
;;(add-new-cffi-lib-directory #P"/usr/lib/" "/usr/local/lib") ; test, works

(defgeneric add-new-cffi-lib-directory (dir)
  (:documentation "Add directory(ies) to CFFI load path and LD_LIBRRARY_PATH."))

(defmethod add-new-cffi-lib-directory ((dir string))
  (pushnew (pathname dir)
	   *foreign-library-directories*
	   :test #'equal)
  (posix-setenv "LD_LIBRARY_PATH"
		(concatenate 'string
			     dir
			     ":" ;; if LD_LIBRARY_PATH is null, then we can drop this trailing ":"
			     (posix-getenv "LD_LIBRARY_PATH"))
		1))

(defmethod add-new-cffi-lib-directory ((dir pathname))
  (pushnew dir
	   *foreign-library-directories*
	   :test #'equal)
  (posix-setenv "LD_LIBRARY_PATH"
		(concatenate 'string
			     (namestring dir)
			     ":" ;; if LD_LIBRARY_PATH is null, then we can drop this trailing ":"
			     (posix-getenv "LD_LIBRARY_PATH"))
		1))

;; if a list, break down into components
(defmethod add-new-cffi-lib-directory ((dir list))
  (dolist (adir dir)
    (add-new-cffi-lib-directory adir)))

;; need to inlcude a default operation which simply aborts, indicating bad inputs.

;;(add-new-cffi-lib-directory (list #p"/usr" "/usr/local"))

;;;* RESOURCES
#|
  #include <sys/time.h>
  #include <sys/resource.h>

       int getrlimit(int resource, struct rlimit *rlim);
       int setrlimit(int resource, const struct rlimit *rlim);

DESCRIPTION
       getrlimit()  and  setrlimit()  get  and  set resource limits respectively.
       Each resource has an associated soft and hard limit,  as  defined  by  the
       rlimit structure (the rlim argument to both getrlimit() and setrlimit()):

            struct rlimit {
                rlim_t rlim_cur;  /* Soft limit */
                rlim_t rlim_max;  /* Hard limit (ceiling for rlim_cur) */
            };
|#

;;;* Resource limit manipulation (esp for stack)

#|

;; Not clear that these are used anywhere?
(defctype rlim_t :int
  "numbers describing range limits")

(defcstruct rlimitStruct
   (rlim_cur rlim_t)  ;; soft limit
   (rlim_max rlim_t)) ;; hard limit

(defcfun ("getrlimit" posix-getrlimit) :int
  (resource :int) (rlimit rlimitStruct))

(defcfun ("setrlimit" posix-setrlimit) :int
  (resource :int) (rlimit rlimitStruct))
|#