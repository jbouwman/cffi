;;;; -*- Mode: lisp; indent-tabs-mode: nil -*-
;;;
;;; runner.lisp --- Main benchmark runner and comparison utilities.
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

;;;============================================================================
;;; Configuration
;;;============================================================================

(defparameter *quick-iterations* 100000
  "Reduced iterations for quick benchmark runs.")

(defparameter *full-iterations* 1000000
  "Full iterations for comprehensive benchmark runs.")

;;;============================================================================
;;; Main Benchmark Runners
;;;============================================================================

(defun run-all-benchmarks (&key (quick nil) (verbose t))
  "Run all benchmarks comparing libffi vs direct struct returns.

   Arguments:
     QUICK - If true, run fewer iterations for faster results
     VERBOSE - If true, print detailed progress

   Returns a summary of results."
  (let ((*benchmark-iterations* (if quick *quick-iterations* *full-iterations*))
        (*warmup-iterations* (if quick 1000 10000))
        (*verbose* verbose))

    (format t "~&")
    (format t "========================================~%")
    (format t "CFFI Struct-Return-by-Value Benchmarks~%")
    (format t "========================================~%")
    (format t "~%")
    (format t "Comparing: libffi vs direct SBCL support~%")
    (format t "Iterations: ~:D~%" *benchmark-iterations*)
    (format t "Warmup: ~:D~%" *warmup-iterations*)
    (format t "~%")

    ;; Check for direct support
    (format t "Implementation Support:~%")
    (format t "  libffi: always available~%")
    (format t "  direct: ~A~%"
            (if (check-direct-support-available)
                "available (SBCL with alien-funcall-into)"
                "NOT available"))
    (format t "~%")

    (clear-results)

    ;; Load benchmark library
    (format t "Loading benchmark library...~%")
    (handler-case
        (load-benchmark-library)
      (error (e)
        (format t "~&ERROR: Could not load benchmark library: ~A~%" e)
        (format t "Make sure to compile the system first:~%")
        (format t "  (asdf:load-system :cffi-benchmarks)~%")
        (return-from run-all-benchmarks nil)))
    (format t "Benchmark library loaded.~%~%")

    ;; Run core benchmarks
    (run-core-benchmarks)

    ;; Run real-world benchmarks
    (format t "~%")
    (format t "========================================~%")
    (format t "Real-World Library Benchmarks~%")
    (format t "========================================~%")
    (run-real-world-benchmarks)

    ;; Print final summary
    (print-summary)

    ;; Return results hash
    *benchmark-results*))

(defun run-quick-benchmarks ()
  "Run a quick benchmark comparison with reduced iterations."
  (run-all-benchmarks :quick t))

(defun run-benchmark (name &key (iterations *benchmark-iterations*))
  "Run a specific benchmark by name.

   NAME should match one of the benchmark names, e.g.:
     \"make-point2i\"
     \"add-point2d\"
     \"identity-mat4f\"
"
  (let ((*benchmark-iterations* iterations)
        (benchmark-fn (find-benchmark-function name)))
    (if benchmark-fn
        (run-with-both-implementations benchmark-fn name)
        (format t "~&Unknown benchmark: ~A~%" name))))

(defun find-benchmark-function (name)
  "Find the benchmark function for a given name."
  (let ((fn-name (intern (format nil "BENCH-~A" (string-upcase name))
                         :cffi-benchmarks)))
    (when (fboundp fn-name)
      (symbol-function fn-name))))

;;;============================================================================
;;; Comparison Utilities
;;;============================================================================

(defun run-comparison (&key (iterations 100000))
  "Run a side-by-side comparison showing speedup for each struct size category."
  (let ((*benchmark-iterations* iterations)
        (*verbose* nil))

    (clear-results)
    (load-benchmark-library)

    (format t "~&")
    (format t "╔════════════════════════════════════════════════════════════════╗~%")
    (format t "║     libffi vs Direct Struct Return Performance Comparison      ║~%")
    (format t "╠════════════════════════════════════════════════════════════════╣~%")
    (format t "║ Iterations per benchmark: ~10:D                            ║~%"
            iterations)
    (format t "╚════════════════════════════════════════════════════════════════╝~%")
    (format t "~%")

    ;; Small structs
    (format t "~%▸ Small Structs (8-16 bytes) - typically register-passable~%")
    (format t "  ─────────────────────────────────────────────────────────~%")
    (print-comparison-row "point2i (8B)" #'bench-make-point2i)
    (print-comparison-row "point2f (8B)" #'bench-make-point2f)
    (print-comparison-row "point2d (16B)" #'bench-make-point2d)
    (print-comparison-row "vec4f (16B)" #'bench-make-vec4f)

    ;; Medium structs
    (format t "~%▸ Medium Structs (24-48 bytes) - may use stack return~%")
    (format t "  ─────────────────────────────────────────────────────────~%")
    (print-comparison-row "point3d (24B)" #'bench-make-point3d)
    (print-comparison-row "rect (32B)" #'bench-make-rect)
    (print-comparison-row "line2d (32B nested)" #'bench-make-line2d)
    (print-comparison-row "triangle2d (48B)" #'bench-make-triangle2d)

    ;; Large structs
    (format t "~%▸ Large Structs (64+ bytes) - always stack-returned~%")
    (format t "  ─────────────────────────────────────────────────────────~%")
    (print-comparison-row "mat4f (64B)" #'bench-identity-mat4f)
    (print-comparison-row "mat4d (128B)" #'bench-identity-mat4d)

    ;; Struct operations
    (format t "~%▸ Struct Operations (input + output)~%")
    (format t "  ─────────────────────────────────────────────────────────~%")
    (print-comparison-row "add point2d" #'bench-add-point2d)
    (print-comparison-row "union rect" #'bench-union-rect)
    (print-comparison-row "mul mat4f" #'bench-mul-mat4f)

    (format t "~%")
    (format t "Legend: ns/call = nanoseconds per call, speedup = libffi/direct~%")
    (format t "        Higher speedup means direct is faster~%")))

(defun print-comparison-row (label benchmark-fn)
  "Print a single comparison row."
  (let (libffi-result direct-result)
    (with-implementation :libffi
      (setf libffi-result (funcall benchmark-fn)))
    (when (check-direct-support-available)
      (with-implementation :direct
        (setf direct-result (funcall benchmark-fn))))

    (let* ((libffi-ns (result-time-per-call libffi-result))
           (direct-ns (if direct-result
                          (result-time-per-call direct-result)
                          nil))
           (speedup (if direct-ns (/ libffi-ns direct-ns) nil)))
      (if direct-ns
          (format t "  ~25A  libffi: ~7,1F ns  direct: ~7,1F ns  speedup: ~5,2Fx~%"
                  label libffi-ns direct-ns speedup)
          (format t "  ~25A  libffi: ~7,1F ns  direct: N/A~%"
                  label libffi-ns)))))

;;;============================================================================
;;; CSV Export
;;;============================================================================

(defun export-results-csv (&optional (pathname "benchmark-results.csv"))
  "Export benchmark results to CSV format."
  (with-open-file (stream pathname :direction :output :if-exists :supersede)
    (format stream "benchmark,implementation,iterations,total_time_us,time_per_call_ns,calls_per_second,bytes_consed~%")
    (maphash (lambda (key result)
               (format stream "~A,~A,~D,~F,~F,~F,~D~%"
                       (car key)
                       (cdr key)
                       (benchmark-result-iterations result)
                       (benchmark-result-real-time-us result)
                       (result-time-per-call result)
                       (result-calls-per-second result)
                       (benchmark-result-bytes-consed result)))
             *benchmark-results*))
  (format t "~&Results exported to ~A~%" pathname))

;;;============================================================================
;;; Analysis Utilities
;;;============================================================================

(defun analyze-by-struct-size ()
  "Analyze speedup by struct size."
  (let ((small-structs '("make-point2i" "make-point2f" "make-point2d" "make-vec4f"))
        (medium-structs '("make-point3d" "make-rect" "make-line2d" "make-triangle2d"))
        (large-structs '("identity-mat4f" "identity-mat4d")))

    (flet ((avg-speedup (names)
             (let ((speedups
                     (loop for name in names
                           for libffi = (gethash (cons name :libffi) *benchmark-results*)
                           for direct = (gethash (cons name :direct) *benchmark-results*)
                           when (and libffi direct)
                             collect (/ (result-time-per-call libffi)
                                        (result-time-per-call direct)))))
               (if speedups
                   (/ (reduce #'+ speedups) (length speedups))
                   nil))))

      (format t "~&~%Average Speedup by Struct Size:~%")
      (format t "  Small (8-16B):   ~A~%"
              (let ((s (avg-speedup small-structs)))
                (if s (format nil "~,2Fx" s) "N/A")))
      (format t "  Medium (24-48B): ~A~%"
              (let ((s (avg-speedup medium-structs)))
                (if s (format nil "~,2Fx" s) "N/A")))
      (format t "  Large (64B+):    ~A~%"
              (let ((s (avg-speedup large-structs)))
                (if s (format nil "~,2Fx" s) "N/A"))))))

;;;============================================================================
;;; Help
;;;============================================================================

(defun benchmark-help ()
  "Print help for the benchmark system."
  (format t "~&
CFFI Struct-Return-by-Value Benchmark Suite
============================================

This benchmark suite compares performance of struct-return-by-value
operations using two implementations:

  1. libffi    - Uses libffi library (portable, always available)
  2. direct    - Uses SBCL's native alien-funcall-into (faster, SBCL-only)

Quick Start:
  (cffi-benchmarks:run-all-benchmarks)        ; Full benchmark suite
  (cffi-benchmarks:run-quick-benchmarks)      ; Quick run with fewer iterations
  (cffi-benchmarks:run-comparison)            ; Side-by-side comparison table

Available Functions:
  RUN-ALL-BENCHMARKS &key quick verbose  - Run complete benchmark suite
  RUN-QUICK-BENCHMARKS                   - Quick benchmark with fewer iterations
  RUN-COMPARISON &key iterations         - Print comparison table
  RUN-BENCHMARK name &key iterations     - Run specific benchmark
  EXPORT-RESULTS-CSV &optional path      - Export results to CSV
  PRINT-SUMMARY                          - Print results summary
  ANALYZE-BY-STRUCT-SIZE                 - Show speedup by struct size
  CLEAR-RESULTS                          - Clear stored results

Individual Benchmark Suites:
  RUN-SMALL-STRUCT-BENCHMARKS            - 8-16 byte structs
  RUN-MEDIUM-STRUCT-BENCHMARKS           - 24-48 byte structs
  RUN-LARGE-STRUCT-BENCHMARKS            - 64+ byte structs
  RUN-NESTED-STRUCT-BENCHMARKS           - Nested struct composition
  RUN-MIXED-STRUCT-BENCHMARKS            - Mixed-type structs

Real-World Library Benchmarks:
  RUN-CLANG-BENCHMARKS                   - libclang (CXCursor, etc.)
  RUN-COCOA-BENCHMARKS                   - CoreGraphics (macOS only)

Configuration Variables:
  *BENCHMARK-ITERATIONS*                 - Iterations per benchmark
  *WARMUP-ITERATIONS*                    - Warmup iterations
  *VERBOSE*                              - Print detailed output
"))
