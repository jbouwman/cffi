;;;; -*- Mode: lisp; indent-tabs-mode: nil -*-
;;;
;;; core-benchmarks.lisp --- Core struct-return benchmarks.
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
;;; Baseline Benchmarks (no struct returns, for comparison)
;;;============================================================================

(defun bench-baseline-int ()
  "Benchmark baseline: function returning int."
  (benchmark "baseline-int" *benchmark-iterations*
    (noop-int)))

(defun bench-baseline-double ()
  "Benchmark baseline: function returning double."
  (benchmark "baseline-double" *benchmark-iterations*
    (noop-double)))

(defun bench-baseline-void ()
  "Benchmark baseline: void function."
  (benchmark "baseline-void" *benchmark-iterations*
    (noop-void)))

;;;============================================================================
;;; Small Struct Benchmarks (8-16 bytes)
;;;============================================================================

(defun bench-make-point2i ()
  "Benchmark: create point2i (8 bytes)."
  (benchmark "make-point2i (8B)" *benchmark-iterations*
    (make-point2i 10 20)))

(defun bench-add-point2i ()
  "Benchmark: add two point2i structs."
  (let ((a (make-test-point2i 1 2))
        (b (make-test-point2i 3 4)))
    (benchmark "add-point2i (8B)" *benchmark-iterations*
      (add-point2i a b))))

(defun bench-make-point2f ()
  "Benchmark: create point2f (8 bytes)."
  (benchmark "make-point2f (8B)" *benchmark-iterations*
    (make-point2f 10.0 20.0)))

(defun bench-add-point2f ()
  "Benchmark: add two point2f structs."
  (let ((a (make-test-point2f 1.0 2.0))
        (b (make-test-point2f 3.0 4.0)))
    (benchmark "add-point2f (8B)" *benchmark-iterations*
      (add-point2f a b))))

(defun bench-make-point2d ()
  "Benchmark: create point2d (16 bytes)."
  (benchmark "make-point2d (16B)" *benchmark-iterations*
    (make-point2d 10.0d0 20.0d0)))

(defun bench-add-point2d ()
  "Benchmark: add two point2d structs."
  (let ((a (make-test-point2d 1.0d0 2.0d0))
        (b (make-test-point2d 3.0d0 4.0d0)))
    (benchmark "add-point2d (16B)" *benchmark-iterations*
      (add-point2d a b))))

(defun bench-make-vec4f ()
  "Benchmark: create vec4f (16 bytes)."
  (benchmark "make-vec4f (16B)" *benchmark-iterations*
    (make-vec4f 1.0 2.0 3.0 4.0)))

(defun bench-add-vec4f ()
  "Benchmark: add two vec4f structs."
  (let ((a (make-test-vec4f 1.0 2.0 3.0 4.0))
        (b (make-test-vec4f 5.0 6.0 7.0 8.0)))
    (benchmark "add-vec4f (16B)" *benchmark-iterations*
      (add-vec4f a b))))

(defun bench-dot-vec4f ()
  "Benchmark: dot product with struct input (no struct return)."
  (let ((a (make-test-vec4f 1.0 2.0 3.0 4.0))
        (b (make-test-vec4f 5.0 6.0 7.0 8.0)))
    (benchmark "dot-vec4f (16B input)" *benchmark-iterations*
      (dot-vec4f a b))))

;;;============================================================================
;;; Medium Struct Benchmarks (24-48 bytes)
;;;============================================================================

(defun bench-make-point3d ()
  "Benchmark: create point3d (24 bytes)."
  (benchmark "make-point3d (24B)" *benchmark-iterations*
    (make-point3d 10.0d0 20.0d0 30.0d0)))

(defun bench-add-point3d ()
  "Benchmark: add two point3d structs."
  (let ((a (make-test-point3d 1.0d0 2.0d0 3.0d0))
        (b (make-test-point3d 4.0d0 5.0d0 6.0d0)))
    (benchmark "add-point3d (24B)" *benchmark-iterations*
      (add-point3d a b))))

(defun bench-cross-point3d ()
  "Benchmark: cross product of two point3d."
  (let ((a (make-test-point3d 1.0d0 0.0d0 0.0d0))
        (b (make-test-point3d 0.0d0 1.0d0 0.0d0)))
    (benchmark "cross-point3d (24B)" *benchmark-iterations*
      (cross-point3d a b))))

(defun bench-make-rect ()
  "Benchmark: create rect (32 bytes)."
  (benchmark "make-rect (32B)" *benchmark-iterations*
    (make-rect 0.0d0 0.0d0 100.0d0 100.0d0)))

(defun bench-union-rect ()
  "Benchmark: union of two rects."
  (let ((a (make-test-rect 0.0d0 0.0d0 50.0d0 50.0d0))
        (b (make-test-rect 25.0d0 25.0d0 50.0d0 50.0d0)))
    (benchmark "union-rect (32B)" *benchmark-iterations*
      (union-rect a b))))

(defun bench-intersect-rect ()
  "Benchmark: intersection of two rects."
  (let ((a (make-test-rect 0.0d0 0.0d0 50.0d0 50.0d0))
        (b (make-test-rect 25.0d0 25.0d0 50.0d0 50.0d0)))
    (benchmark "intersect-rect (32B)" *benchmark-iterations*
      (intersect-rect a b))))

;;;============================================================================
;;; Large Struct Benchmarks (64+ bytes)
;;;============================================================================

(defun bench-identity-mat4f ()
  "Benchmark: create identity mat4f (64 bytes)."
  (benchmark "identity-mat4f (64B)" *benchmark-iterations*
    (identity-mat4f)))

(defun bench-scale-mat4f ()
  "Benchmark: create scale matrix (64 bytes)."
  (benchmark "scale-mat4f (64B)" *benchmark-iterations*
    (scale-mat4f 2.0 2.0 2.0)))

(defun bench-mul-mat4f ()
  "Benchmark: multiply two 4x4 float matrices."
  (let ((a (identity-mat4f))
        (b (identity-mat4f)))
    (benchmark "mul-mat4f (64B)" (/ *benchmark-iterations* 10)
      (mul-mat4f a b))))

(defun bench-identity-mat4d ()
  "Benchmark: create identity mat4d (128 bytes)."
  (benchmark "identity-mat4d (128B)" *benchmark-iterations*
    (identity-mat4d)))

(defun bench-mul-mat4d ()
  "Benchmark: multiply two 4x4 double matrices."
  (let ((a (identity-mat4d))
        (b (identity-mat4d)))
    (benchmark "mul-mat4d (128B)" (/ *benchmark-iterations* 10)
      (mul-mat4d a b))))

;;;============================================================================
;;; Nested Struct Benchmarks
;;;============================================================================

(defun bench-make-line2d ()
  "Benchmark: create line2d (32 bytes, nested)."
  (benchmark "make-line2d (32B nested)" *benchmark-iterations*
    (make-line2d 0.0d0 0.0d0 10.0d0 10.0d0)))

(defun bench-make-triangle2d ()
  "Benchmark: create triangle2d (48 bytes, nested)."
  (benchmark "make-triangle2d (48B nested)" *benchmark-iterations*
    (make-triangle2d 0.0d0 0.0d0 10.0d0 0.0d0 5.0d0 8.66d0)))

(defun bench-make-bounds3d ()
  "Benchmark: create bounds3d (48 bytes, nested)."
  (benchmark "make-bounds3d (48B nested)" *benchmark-iterations*
    (make-bounds3d 0.0d0 0.0d0 0.0d0 10.0d0 10.0d0 10.0d0)))

(defun bench-expand-bounds3d ()
  "Benchmark: expand bounds3d with point."
  (let ((b (list 'min (make-test-point3d 0.0d0 0.0d0 0.0d0)
                 'max (make-test-point3d 10.0d0 10.0d0 10.0d0)))
        (p (make-test-point3d 15.0d0 5.0d0 5.0d0)))
    (benchmark "expand-bounds3d (48B nested)" *benchmark-iterations*
      (expand-bounds3d b p))))

;;;============================================================================
;;; Mixed-Type Struct Benchmarks
;;;============================================================================

(defun bench-make-mixed1 ()
  "Benchmark: create mixed1 (char, double, int)."
  (benchmark "make-mixed1 (mixed)" *benchmark-iterations*
    (make-mixed1 65 3.14d0 42)))

(defun bench-make-mixed2 ()
  "Benchmark: create mixed2 (complex alignment)."
  (benchmark "make-mixed2 (mixed)" *benchmark-iterations*
    (make-mixed2 100 65 1000 66 2.718d0)))

(defun bench-make-mixed3 ()
  "Benchmark: create mixed3 (all sizes)."
  (benchmark "make-mixed3 (mixed)" *benchmark-iterations*
    (make-mixed3 1 2 3 4 5.0 6.0d0)))

;;;============================================================================
;;; Accumulator/Loop Benchmarks
;;;============================================================================

(defun bench-normalize-vec4f ()
  "Benchmark: normalize vec4f."
  (let ((v (make-test-vec4f 1.0 2.0 3.0 4.0)))
    (benchmark "normalize-vec4f" *benchmark-iterations*
      (normalize-vec4f v))))

(defun bench-transpose-mat4f ()
  "Benchmark: transpose mat4f."
  (let ((m (identity-mat4f)))
    (benchmark "transpose-mat4f (64B)" *benchmark-iterations*
      (transpose-mat4f m))))

;;;============================================================================
;;; Benchmark Runners
;;;============================================================================

(defun run-baseline-benchmarks ()
  "Run baseline benchmarks (no struct returns)."
  (format t "~&~%=== Baseline Benchmarks ===~%")
  (run-with-both-implementations #'bench-baseline-void "baseline-void")
  (run-with-both-implementations #'bench-baseline-int "baseline-int")
  (run-with-both-implementations #'bench-baseline-double "baseline-double"))

(defun run-small-struct-benchmarks ()
  "Run small struct benchmarks (8-16 bytes)."
  (format t "~&~%=== Small Struct Benchmarks (8-16 bytes) ===~%")
  (run-with-both-implementations #'bench-make-point2i "make-point2i")
  (run-with-both-implementations #'bench-add-point2i "add-point2i")
  (run-with-both-implementations #'bench-make-point2f "make-point2f")
  (run-with-both-implementations #'bench-add-point2f "add-point2f")
  (run-with-both-implementations #'bench-make-point2d "make-point2d")
  (run-with-both-implementations #'bench-add-point2d "add-point2d")
  (run-with-both-implementations #'bench-make-vec4f "make-vec4f")
  (run-with-both-implementations #'bench-add-vec4f "add-vec4f")
  (run-with-both-implementations #'bench-dot-vec4f "dot-vec4f"))

(defun run-medium-struct-benchmarks ()
  "Run medium struct benchmarks (24-48 bytes)."
  (format t "~&~%=== Medium Struct Benchmarks (24-48 bytes) ===~%")
  (run-with-both-implementations #'bench-make-point3d "make-point3d")
  (run-with-both-implementations #'bench-add-point3d "add-point3d")
  (run-with-both-implementations #'bench-cross-point3d "cross-point3d")
  (run-with-both-implementations #'bench-make-rect "make-rect")
  (run-with-both-implementations #'bench-union-rect "union-rect")
  (run-with-both-implementations #'bench-intersect-rect "intersect-rect"))

(defun run-large-struct-benchmarks ()
  "Run large struct benchmarks (64+ bytes)."
  (format t "~&~%=== Large Struct Benchmarks (64+ bytes) ===~%")
  (run-with-both-implementations #'bench-identity-mat4f "identity-mat4f")
  (run-with-both-implementations #'bench-scale-mat4f "scale-mat4f")
  (run-with-both-implementations #'bench-mul-mat4f "mul-mat4f")
  (run-with-both-implementations #'bench-identity-mat4d "identity-mat4d")
  (run-with-both-implementations #'bench-mul-mat4d "mul-mat4d")
  (run-with-both-implementations #'bench-transpose-mat4f "transpose-mat4f"))

(defun run-nested-struct-benchmarks ()
  "Run nested struct benchmarks."
  (format t "~&~%=== Nested Struct Benchmarks ===~%")
  (run-with-both-implementations #'bench-make-line2d "make-line2d")
  (run-with-both-implementations #'bench-make-triangle2d "make-triangle2d")
  (run-with-both-implementations #'bench-make-bounds3d "make-bounds3d")
  (run-with-both-implementations #'bench-expand-bounds3d "expand-bounds3d"))

(defun run-mixed-struct-benchmarks ()
  "Run mixed-type struct benchmarks."
  (format t "~&~%=== Mixed-Type Struct Benchmarks ===~%")
  (run-with-both-implementations #'bench-make-mixed1 "make-mixed1")
  (run-with-both-implementations #'bench-make-mixed2 "make-mixed2")
  (run-with-both-implementations #'bench-make-mixed3 "make-mixed3"))

(defun run-accumulator-benchmarks ()
  "Run accumulator/computational benchmarks."
  (format t "~&~%=== Accumulator Benchmarks ===~%")
  (run-with-both-implementations #'bench-normalize-vec4f "normalize-vec4f"))

(defun run-core-benchmarks ()
  "Run all core benchmarks."
  (clear-results)
  (load-benchmark-library)
  (run-baseline-benchmarks)
  (run-small-struct-benchmarks)
  (run-medium-struct-benchmarks)
  (run-large-struct-benchmarks)
  (run-nested-struct-benchmarks)
  (run-mixed-struct-benchmarks)
  (run-accumulator-benchmarks)
  (print-summary))
