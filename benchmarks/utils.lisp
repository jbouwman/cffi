;;;; -*- Mode: lisp; indent-tabs-mode: nil -*-
;;;
;;; utils.lisp --- Benchmark utilities and timing infrastructure.
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

(in-package #:cffi-benchmarks)

;;; Configuration variables

(defparameter *benchmark-iterations* 1000000
  "Number of iterations for each benchmark.")

(defparameter *warmup-iterations* 10000
  "Number of warmup iterations before timing.")

(defparameter *verbose* t
  "When true, print detailed benchmark progress.")

(defparameter *use-libffi* t
  "When true, use libffi for struct-by-value. When false, use direct SBCL support if available.")

;;; Internal variables

(defvar *benchmark-results* (make-hash-table :test 'equal)
  "Hash table storing benchmark results.")

;;; Timing utilities

(defun get-internal-real-time-us ()
  "Return current time in microseconds."
  (let ((units-per-second internal-time-units-per-second))
    (/ (* (get-internal-real-time) 1000000) units-per-second)))

(defun get-run-time-us ()
  "Return current CPU time in microseconds."
  (let ((units-per-second internal-time-units-per-second))
    (/ (* (get-internal-run-time) 1000000) units-per-second)))

(defmacro with-timing ((real-var cpu-var) &body body)
  "Execute BODY and bind elapsed real time and CPU time (in microseconds) to REAL-VAR and CPU-VAR."
  (let ((start-real (gensym "START-REAL"))
        (start-cpu (gensym "START-CPU"))
        (end-real (gensym "END-REAL"))
        (end-cpu (gensym "END-CPU")))
    `(let ((,start-real (get-internal-real-time-us))
           (,start-cpu (get-run-time-us)))
       (progn ,@body)
       (let ((,end-real (get-internal-real-time-us))
             (,end-cpu (get-run-time-us)))
         (let ((,real-var (- ,end-real ,start-real))
               (,cpu-var (- ,end-cpu ,start-cpu)))
           (values ,real-var ,cpu-var))))))

;;; Benchmark result structure

(defstruct benchmark-result
  name
  iterations
  real-time-us
  cpu-time-us
  (bytes-consed 0)
  implementation)

(defun result-time-per-call (result)
  "Return time per call in nanoseconds."
  (/ (* (benchmark-result-real-time-us result) 1000)
     (benchmark-result-iterations result)))

(defun result-calls-per-second (result)
  "Return number of calls per second."
  (/ (benchmark-result-iterations result)
     (/ (benchmark-result-real-time-us result) 1000000)))

;;; Core benchmarking macro

(defmacro benchmark (name iterations &body body)
  "Run BODY for ITERATIONS times, measuring time and memory.
Returns a BENCHMARK-RESULT structure."
  (let ((i (gensym "I"))
        (real-time (gensym "REAL"))
        (cpu-time (gensym "CPU"))
        (start-bytes (gensym "START-BYTES"))
        (end-bytes (gensym "END-BYTES")))
    `(progn
       ;; Warmup
       (dotimes (,i *warmup-iterations*)
         (declare (ignorable ,i))
         ,@body)
       ;; Force GC before measurement
       #+sbcl (sb-ext:gc :full t)
       ;; Actual benchmark
       (let ((,start-bytes #+sbcl (sb-ext:get-bytes-consed) #-sbcl 0))
         (with-timing (,real-time ,cpu-time)
           (dotimes (,i ,iterations)
             (declare (ignorable ,i))
             ,@body))
         (let ((,end-bytes #+sbcl (sb-ext:get-bytes-consed) #-sbcl 0))
           (make-benchmark-result
            :name ,name
            :iterations ,iterations
            :real-time-us ,real-time
            :cpu-time-us ,cpu-time
            :bytes-consed (- ,end-bytes ,start-bytes)
            :implementation (if *use-libffi* :libffi :direct)))))))

;;; Result formatting and comparison

(defun format-result (result &optional (stream *standard-output*))
  "Print a formatted benchmark result."
  (format stream "~&~A (~A):~%"
          (benchmark-result-name result)
          (benchmark-result-implementation result))
  (format stream "  Iterations: ~:D~%"
          (benchmark-result-iterations result))
  (format stream "  Total time: ~,2F ms~%"
          (/ (benchmark-result-real-time-us result) 1000))
  (format stream "  Per call:   ~,2F ns~%"
          (result-time-per-call result))
  (format stream "  Calls/sec:  ~,2E~%"
          (result-calls-per-second result))
  (when (plusp (benchmark-result-bytes-consed result))
    (format stream "  Bytes consed: ~:D~%"
            (benchmark-result-bytes-consed result))))

(defun compare-results (libffi-result direct-result &optional (stream *standard-output*))
  "Compare two benchmark results and print analysis."
  (let* ((libffi-ns (result-time-per-call libffi-result))
         (direct-ns (result-time-per-call direct-result))
         (speedup (/ libffi-ns direct-ns))
         (diff-ns (- libffi-ns direct-ns)))
    (format stream "~&Comparison for: ~A~%" (benchmark-result-name libffi-result))
    (format stream "  libffi:    ~,2F ns/call~%" libffi-ns)
    (format stream "  direct:    ~,2F ns/call~%" direct-ns)
    (format stream "  Speedup:   ~,2Fx~%" speedup)
    (format stream "  Saved:     ~,2F ns/call~%" diff-ns)
    (cond
      ((> speedup 1.1)
       (format stream "  Result:    Direct is ~,1F% faster~%"
               (* 100 (- 1 (/ 1 speedup)))))
      ((< speedup 0.9)
       (format stream "  Result:    libffi is ~,1F% faster~%"
               (* 100 (- speedup 1))))
      (t
       (format stream "  Result:    Performance is similar~%")))
    speedup))

;;; Running benchmarks with both implementations

(defun check-direct-support-available ()
  "Check if direct struct-return support is available in SBCL."
  #+sbcl
  (and (find-symbol "ALIEN-FUNCALL-INTO" "SB-ALIEN")
       (fboundp (find-symbol "ALIEN-FUNCALL-INTO" "SB-ALIEN")))
  #-sbcl
  nil)

(defvar *saved-fsbv-handler* nil
  "Saved value of CFFI::*FOREIGN-STRUCTURES-BY-VALUE*.")

(defun switch-to-libffi ()
  "Switch to using libffi for struct-by-value calls."
  (setf *use-libffi* t)
  ;; The cffi-libffi system sets this on load
  (when (find-symbol "FOREIGN-FUNCALL-FORM/FSBV-WITH-LIBFFI" "CFFI")
    (setf cffi::*foreign-structures-by-value*
          (symbol-function (find-symbol "FOREIGN-FUNCALL-FORM/FSBV-WITH-LIBFFI" "CFFI")))))

(defun switch-to-direct ()
  "Switch to using direct SBCL support for struct-by-value calls (if available)."
  (setf *use-libffi* nil)
  #+sbcl
  (when (find-symbol "FOREIGN-FUNCALL-FORM/FSBV-SBCL" "CFFI")
    (let ((fn (find-symbol "FOREIGN-FUNCALL-FORM/FSBV-SBCL" "CFFI")))
      (when (fboundp fn)
        (setf cffi::*foreign-structures-by-value* (symbol-function fn))))))

(defmacro with-implementation (impl &body body)
  "Execute BODY with the specified implementation (:libffi or :direct)."
  `(progn
     (ecase ,impl
       (:libffi (switch-to-libffi))
       (:direct (switch-to-direct)))
     ,@body))

(defun run-with-both-implementations (benchmark-fn name)
  "Run BENCHMARK-FN with both implementations and compare results.
BENCHMARK-FN should be a function of no arguments that returns a benchmark result."
  (let (libffi-result direct-result)
    ;; Run with libffi
    (with-implementation :libffi
      (when *verbose*
        (format t "~&Running ~A with libffi...~%" name))
      (setf libffi-result (funcall benchmark-fn)))

    ;; Run with direct (if available)
    (if (check-direct-support-available)
        (progn
          (with-implementation :direct
            (when *verbose*
              (format t "~&Running ~A with direct...~%" name))
            (setf direct-result (funcall benchmark-fn))))
        (progn
          (when *verbose*
            (format t "~&Direct support not available, skipping...~%"))
          (setf direct-result nil)))

    ;; Compare and report
    (when *verbose*
      (format t "~%")
      (format-result libffi-result)
      (when direct-result
        (format t "~%")
        (format-result direct-result)
        (format t "~%")
        (compare-results libffi-result direct-result)))

    ;; Store results
    (setf (gethash (cons name :libffi) *benchmark-results*) libffi-result)
    (when direct-result
      (setf (gethash (cons name :direct) *benchmark-results*) direct-result))

    (values libffi-result direct-result)))

;;; Summary reporting

(defun print-summary (&optional (stream *standard-output*))
  "Print a summary of all benchmark results."
  (format stream "~&~%========================================~%")
  (format stream "BENCHMARK SUMMARY~%")
  (format stream "========================================~%~%")

  (let ((names (remove-duplicates
                (mapcar #'car (alexandria:hash-table-keys *benchmark-results*))
                :test #'string=)))
    (format stream "~40A ~12A ~12A ~10A~%"
            "Benchmark" "libffi" "direct" "Speedup")
    (format stream "~40,,,'-A ~12,,,'-A ~12,,,'-A ~10,,,'-A~%"
            "" "" "" "")
    (dolist (name (sort names #'string<))
      (let ((libffi (gethash (cons name :libffi) *benchmark-results*))
            (direct (gethash (cons name :direct) *benchmark-results*)))
        (if (and libffi direct)
            (format stream "~40A ~10,2F ns ~10,2F ns ~8,2Fx~%"
                    name
                    (result-time-per-call libffi)
                    (result-time-per-call direct)
                    (/ (result-time-per-call libffi)
                       (result-time-per-call direct)))
            (format stream "~40A ~10,2F ns ~12A ~10A~%"
                    name
                    (if libffi (result-time-per-call libffi) 0)
                    "N/A"
                    "N/A")))))
  (format stream "~%"))

(defun clear-results ()
  "Clear all stored benchmark results."
  (clrhash *benchmark-results*))
