;;;; -*- Mode: lisp; indent-tabs-mode: nil -*-
;;;
;;; cffi-benchmarks.asd --- ASDF system definition for CFFI struct-return benchmarks.
;;;
;;; Copyright (C) 2026, Jesse Bouwman
;;;
;;; Permission is hereby granted, free of charge, to any person
;;; obtaining a copy of this software and associated documentation
;;; files (the "Software"), to deal in the Software without
;;; restriction, including without limitation the rights to use, copy,
;;; modify, merge, publish, distribute, sublicense, and/or sell copies
;;; of the Software, and to permit persons to whom the Software is
;;; furnished to do so, subject to the following conditions:
;;;
;;; The above copyright notice and this permission notice shall be
;;; included in all copies or substantial portions of the Software.
;;;
;;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
;;; NONINFRINGEMENT.  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
;;; HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
;;; WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
;;; DEALINGS IN THE SOFTWARE.
;;;

(load-systems "cffi-grovel")

(defclass c-benchmark-lib (c-source-file)
  ())

(defmethod perform ((o load-op) (c c-benchmark-lib))
  nil)

(defmethod perform ((o load-source-op) (c c-benchmark-lib))
  nil)

(defmethod output-files ((o compile-op) (c c-benchmark-lib))
  (let ((p (component-pathname c)))
    (values
     (list (make-pathname :defaults p :type (asdf/bundle:bundle-pathname-type :object))
           (make-pathname :defaults p :type (asdf/bundle:bundle-pathname-type :shared-library)))
     t)))

(defmethod perform ((o compile-op) (c c-benchmark-lib))
  (let ((cffi-toolchain:*cc-flags* `(,@cffi-toolchain:*cc-flags* "-O2" "-Wall" "-std=c99")))
    (destructuring-bind (obj dll) (output-files o c)
      (cffi-toolchain:cc-compile obj (input-files o c))
      (cffi-toolchain:link-shared-library dll (list obj)))))

(defsystem "cffi-benchmarks"
  :description "Benchmarks comparing libffi vs direct struct-return-by-value."
  :depends-on ("cffi" "cffi-libffi" "alexandria" "uiop")
  :components
  ((:module "benchmarks"
    :components
    ((:c-benchmark-lib "libbench")
     (:file "package")
     (:file "utils" :depends-on ("package"))
     (:file "bindings" :depends-on ("package" "libbench"))
     (:file "core-benchmarks" :depends-on ("utils" "bindings"))
     (:file "real-world" :depends-on ("utils" "bindings"))
     (:file "runner" :depends-on ("core-benchmarks" "real-world"))))))

;;; vim: ft=lisp et
