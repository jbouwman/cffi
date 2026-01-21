;;;; -*- Mode: lisp; indent-tabs-mode: nil -*-
;;;
;;; cffi-sbcl-fsbv.lisp --- Activate native SBCL struct-by-value support
;;;
;;; This file loads after functions.lisp to set *foreign-structures-by-value*.
;;; The actual implementation is in cffi-sbcl.lisp.

(in-package #:cffi-sys)

(when (alien-funcall-into-available-p)
  (setf cffi::*foreign-structures-by-value* 'foreign-funcall-form/fsbv-sbcl))
