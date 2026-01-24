;;;; -*- Mode: lisp; indent-tabs-mode: nil -*-
;;;
;;; real-world.lisp --- Benchmarks using real-world libraries.
;;;
;;; This file contains benchmarks for struct-return-by-value using
;;; actual libraries like libclang, BLAS (complex numbers), and
;;; Cocoa/CoreFoundation (macOS).
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
;;; Library availability checking
;;;============================================================================

(defvar *libclang-available* nil)
(defvar *cocoa-available* nil)
(defvar *blas-available* nil)

(defun check-library-availability ()
  "Check which optional libraries are available."
  ;; Check libclang
  (setf *libclang-available*
        (ignore-errors
          (load-foreign-library '(:or "libclang.so" "libclang.dylib"
                                      (:framework "libclang")))
          t))

  ;; Check Cocoa (macOS only)
  #+darwin
  (setf *cocoa-available*
        (ignore-errors
          (load-foreign-library '(:framework "CoreGraphics"))
          (load-foreign-library '(:framework "Foundation"))
          t))

  ;; Check BLAS
  (setf *blas-available*
        (ignore-errors
          (load-foreign-library '(:or "libblas.so" "libblas.dylib"
                                      (:framework "Accelerate")))
          t))

  (when *verbose*
    (format t "~&Library availability:~%")
    (format t "  libclang: ~A~%" (if *libclang-available* "yes" "no"))
    (format t "  Cocoa:    ~A~%" (if *cocoa-available* "yes" "no"))
    (format t "  BLAS:     ~A~%" (if *blas-available* "yes" "no"))))

;;;============================================================================
;;; libclang Bindings and Benchmarks
;;;============================================================================

;;; CXSourceLocation is a struct containing:
;;; - ptr_data[0]: void*
;;; - ptr_data[1]: void*
;;; - int_data: unsigned
;;; Total: ~24 bytes on 64-bit

(defcstruct cx-source-location
  "libclang: Source location (24 bytes on 64-bit)."
  (ptr-data-0 :pointer)
  (ptr-data-1 :pointer)
  (int-data :unsigned-int))

;;; CXSourceRange contains two CXSourceLocations
;;; Total: ~48 bytes on 64-bit

(defcstruct cx-source-range
  "libclang: Source range (48 bytes on 64-bit)."
  (ptr-data-0 :pointer)
  (ptr-data-1 :pointer)
  (begin-int-data :unsigned-int)
  (end-int-data :unsigned-int))

;;; CXCursor is larger:
;;; - kind: enum CXCursorKind (int)
;;; - xdata: int
;;; - data[0-2]: void* (3 pointers)
;;; Total: ~32 bytes on 64-bit

(defcstruct cx-cursor
  "libclang: Cursor (32 bytes on 64-bit)."
  (kind :int)
  (xdata :int)
  (data-0 :pointer)
  (data-1 :pointer)
  (data-2 :pointer))

;;; CXString is a struct with pointer and flags
(defcstruct cx-string
  "libclang: String (16 bytes on 64-bit)."
  (data :pointer)
  (private-flags :unsigned-int))

;;; CXToken is:
;;; - int_data[0-3]: unsigned (4 ints)
;;; - ptr_data: void*
;;; Total: ~24 bytes on 64-bit

(defcstruct cx-token
  "libclang: Token (24 bytes on 64-bit)."
  (int-data-0 :unsigned-int)
  (int-data-1 :unsigned-int)
  (int-data-2 :unsigned-int)
  (int-data-3 :unsigned-int)
  (ptr-data :pointer))

;; Function declarations (only defined when libclang is available)
(defun define-clang-functions ()
  "Define libclang foreign functions."
  ;; clang_getNullLocation() returns CXSourceLocation
  (eval '(defcfun ("clang_getNullLocation" clang-get-null-location)
           (:struct cx-source-location)))

  ;; clang_getNullRange() returns CXSourceRange
  (eval '(defcfun ("clang_getNullRange" clang-get-null-range)
           (:struct cx-source-range)))

  ;; clang_getNullCursor() returns CXCursor
  (eval '(defcfun ("clang_getNullCursor" clang-get-null-cursor)
           (:struct cx-cursor)))

  ;; clang_equalLocations compares two locations
  (eval '(defcfun ("clang_equalLocations" clang-equal-locations) :unsigned-int
           (loc1 (:struct cx-source-location))
           (loc2 (:struct cx-source-location))))

  ;; clang_equalRanges compares two ranges
  (eval '(defcfun ("clang_equalRanges" clang-equal-ranges) :unsigned-int
           (range1 (:struct cx-source-range))
           (range2 (:struct cx-source-range))))

  ;; clang_equalCursors compares two cursors
  (eval '(defcfun ("clang_equalCursors" clang-equal-cursors) :unsigned-int
           (cursor1 (:struct cx-cursor))
           (cursor2 (:struct cx-cursor))))

  ;; clang_Range_isNull checks if range is null
  (eval '(defcfun ("clang_Range_isNull" clang-range-is-null) :int
           (range (:struct cx-source-range)))))

(defun bench-clang-null-location ()
  "Benchmark: clang_getNullLocation (24B struct return)."
  (benchmark "clang-getNullLocation (24B)" *benchmark-iterations*
    (clang-get-null-location)))

(defun bench-clang-null-range ()
  "Benchmark: clang_getNullRange (48B struct return)."
  (benchmark "clang-getNullRange (48B)" *benchmark-iterations*
    (clang-get-null-range)))

(defun bench-clang-null-cursor ()
  "Benchmark: clang_getNullCursor (32B struct return)."
  (benchmark "clang-getNullCursor (32B)" *benchmark-iterations*
    (clang-get-null-cursor)))

(defun bench-clang-equal-locations ()
  "Benchmark: clang_equalLocations (24B struct args)."
  (let ((loc (clang-get-null-location)))
    (benchmark "clang-equalLocations (24B args)" *benchmark-iterations*
      (clang-equal-locations loc loc))))

(defun bench-clang-equal-ranges ()
  "Benchmark: clang_equalRanges (48B struct args)."
  (let ((range (clang-get-null-range)))
    (benchmark "clang-equalRanges (48B args)" *benchmark-iterations*
      (clang-equal-ranges range range))))

(defun bench-clang-equal-cursors ()
  "Benchmark: clang_equalCursors (32B struct args)."
  (let ((cursor (clang-get-null-cursor)))
    (benchmark "clang-equalCursors (32B args)" *benchmark-iterations*
      (clang-equal-cursors cursor cursor))))

(defun run-clang-benchmarks ()
  "Run libclang benchmarks."
  (unless *libclang-available*
    (format t "~&libclang not available, skipping clang benchmarks.~%")
    (return-from run-clang-benchmarks nil))

  (format t "~&~%=== libclang Benchmarks ===~%")
  (define-clang-functions)
  (run-with-both-implementations #'bench-clang-null-location "clang-getNullLocation")
  (run-with-both-implementations #'bench-clang-null-range "clang-getNullRange")
  (run-with-both-implementations #'bench-clang-null-cursor "clang-getNullCursor")
  (run-with-both-implementations #'bench-clang-equal-locations "clang-equalLocations")
  (run-with-both-implementations #'bench-clang-equal-ranges "clang-equalRanges")
  (run-with-both-implementations #'bench-clang-equal-cursors "clang-equalCursors"))

;;;============================================================================
;;; Cocoa/CoreFoundation Bindings and Benchmarks (macOS only)
;;;============================================================================

#+darwin
(progn
  ;; CGPoint (16 bytes)
  (defcstruct cg-point
    "CoreGraphics: Point (16 bytes)."
    (x :double)  ; CGFloat is double on 64-bit
    (y :double))

  ;; CGSize (16 bytes)
  (defcstruct cg-size
    "CoreGraphics: Size (16 bytes)."
    (width :double)
    (height :double))

  ;; CGRect (32 bytes)
  (defcstruct cg-rect
    "CoreGraphics: Rect (32 bytes)."
    (origin (:struct cg-point))
    (size (:struct cg-size)))

  ;; CGVector (16 bytes)
  (defcstruct cg-vector
    "CoreGraphics: Vector (16 bytes)."
    (dx :double)
    (dy :double))

  ;; CGAffineTransform (48 bytes)
  (defcstruct cg-affine-transform
    "CoreGraphics: Affine Transform (48 bytes)."
    (a :double)
    (b :double)
    (c :double)
    (d :double)
    (tx :double)
    (ty :double))

  ;; NSRange (16 bytes)
  (defcstruct ns-range
    "Foundation: Range (16 bytes)."
    (location :unsigned-long)  ; NSUInteger
    (length :unsigned-long))

  ;; Define CoreGraphics functions
  (defun define-cocoa-functions ()
    "Define Cocoa/CoreGraphics foreign functions."
    ;; CGPointMake - inline function, may not be exported
    ;; Use CGRectGetMinX etc. which do return structs

    ;; CGRectMake is typically inlined, but some functions return CGRect
    ;; CGContextGetClipBoundingBox returns CGRect
    ;; We'll use CGRectInset which takes and returns CGRect

    ;; CGRectInset(rect, dx, dy) -> CGRect
    (eval '(defcfun ("CGRectInset" cg-rect-inset) (:struct cg-rect)
             (rect (:struct cg-rect))
             (dx :double)
             (dy :double)))

    ;; CGRectUnion(r1, r2) -> CGRect
    (eval '(defcfun ("CGRectUnion" cg-rect-union) (:struct cg-rect)
             (r1 (:struct cg-rect))
             (r2 (:struct cg-rect))))

    ;; CGRectIntersection(r1, r2) -> CGRect
    (eval '(defcfun ("CGRectIntersection" cg-rect-intersection) (:struct cg-rect)
             (r1 (:struct cg-rect))
             (r2 (:struct cg-rect))))

    ;; CGRectOffset(rect, dx, dy) -> CGRect
    (eval '(defcfun ("CGRectOffset" cg-rect-offset) (:struct cg-rect)
             (rect (:struct cg-rect))
             (dx :double)
             (dy :double)))

    ;; CGRectStandardize(rect) -> CGRect
    (eval '(defcfun ("CGRectStandardize" cg-rect-standardize) (:struct cg-rect)
             (rect (:struct cg-rect))))

    ;; CGRectIntegral(rect) -> CGRect
    (eval '(defcfun ("CGRectIntegral" cg-rect-integral) (:struct cg-rect)
             (rect (:struct cg-rect))))

    ;; CGAffineTransformMakeRotation(angle) -> CGAffineTransform
    (eval '(defcfun ("CGAffineTransformMakeRotation" cg-affine-transform-make-rotation)
             (:struct cg-affine-transform)
             (angle :double)))

    ;; CGAffineTransformMakeScale(sx, sy) -> CGAffineTransform
    (eval '(defcfun ("CGAffineTransformMakeScale" cg-affine-transform-make-scale)
             (:struct cg-affine-transform)
             (sx :double)
             (sy :double)))

    ;; CGAffineTransformConcat(t1, t2) -> CGAffineTransform
    (eval '(defcfun ("CGAffineTransformConcat" cg-affine-transform-concat)
             (:struct cg-affine-transform)
             (t1 (:struct cg-affine-transform))
             (t2 (:struct cg-affine-transform))))

    ;; CGPointApplyAffineTransform(point, t) -> CGPoint
    (eval '(defcfun ("CGPointApplyAffineTransform" cg-point-apply-affine-transform)
             (:struct cg-point)
             (point (:struct cg-point))
             (transform (:struct cg-affine-transform))))

    ;; CGRectApplyAffineTransform(rect, t) -> CGRect
    (eval '(defcfun ("CGRectApplyAffineTransform" cg-rect-apply-affine-transform)
             (:struct cg-rect)
             (rect (:struct cg-rect))
             (transform (:struct cg-affine-transform)))))

  (defun make-test-cg-rect (x y w h)
    "Create a test CGRect plist."
    (list 'origin (list 'x (float x 1.0d0) 'y (float y 1.0d0))
          'size (list 'width (float w 1.0d0) 'height (float h 1.0d0))))

  (defun make-test-cg-point (x y)
    "Create a test CGPoint plist."
    (list 'x (float x 1.0d0) 'y (float y 1.0d0)))

  (defun bench-cg-rect-inset ()
    "Benchmark: CGRectInset (32B in, 32B out)."
    (let ((rect (make-test-cg-rect 0.0d0 0.0d0 100.0d0 100.0d0)))
      (benchmark "CGRectInset (32B)" *benchmark-iterations*
        (cg-rect-inset rect 10.0d0 10.0d0))))

  (defun bench-cg-rect-union ()
    "Benchmark: CGRectUnion (32B+32B in, 32B out)."
    (let ((r1 (make-test-cg-rect 0.0d0 0.0d0 50.0d0 50.0d0))
          (r2 (make-test-cg-rect 25.0d0 25.0d0 50.0d0 50.0d0)))
      (benchmark "CGRectUnion (32B)" *benchmark-iterations*
        (cg-rect-union r1 r2))))

  (defun bench-cg-rect-intersection ()
    "Benchmark: CGRectIntersection (32B+32B in, 32B out)."
    (let ((r1 (make-test-cg-rect 0.0d0 0.0d0 50.0d0 50.0d0))
          (r2 (make-test-cg-rect 25.0d0 25.0d0 50.0d0 50.0d0)))
      (benchmark "CGRectIntersection (32B)" *benchmark-iterations*
        (cg-rect-intersection r1 r2))))

  (defun bench-cg-affine-transform-rotation ()
    "Benchmark: CGAffineTransformMakeRotation (48B out)."
    (benchmark "CGAffineTransformMakeRotation (48B)" *benchmark-iterations*
      (cg-affine-transform-make-rotation 0.785398d0)))  ; 45 degrees

  (defun bench-cg-affine-transform-concat ()
    "Benchmark: CGAffineTransformConcat (48B+48B in, 48B out)."
    (let ((t1 (cg-affine-transform-make-rotation 0.785398d0))
          (t2 (cg-affine-transform-make-scale 2.0d0 2.0d0)))
      (benchmark "CGAffineTransformConcat (48B)" *benchmark-iterations*
        (cg-affine-transform-concat t1 t2))))

  (defun bench-cg-point-apply-transform ()
    "Benchmark: CGPointApplyAffineTransform (16B+48B in, 16B out)."
    (let ((point (make-test-cg-point 10.0d0 20.0d0))
          (transform (cg-affine-transform-make-rotation 0.785398d0)))
      (benchmark "CGPointApplyAffineTransform (16B)" *benchmark-iterations*
        (cg-point-apply-affine-transform point transform))))

  (defun bench-cg-rect-apply-transform ()
    "Benchmark: CGRectApplyAffineTransform (32B+48B in, 32B out)."
    (let ((rect (make-test-cg-rect 0.0d0 0.0d0 100.0d0 100.0d0))
          (transform (cg-affine-transform-make-rotation 0.785398d0)))
      (benchmark "CGRectApplyAffineTransform (32B)" *benchmark-iterations*
        (cg-rect-apply-affine-transform rect transform)))))

#+darwin
(defun run-cocoa-benchmarks ()
  "Run Cocoa/CoreFoundation benchmarks."
  (unless *cocoa-available*
    (format t "~&Cocoa frameworks not available, skipping.~%")
    (return-from run-cocoa-benchmarks nil))

  (format t "~&~%=== Cocoa/CoreGraphics Benchmarks ===~%")
  (define-cocoa-functions)
  (run-with-both-implementations #'bench-cg-rect-inset "CGRectInset")
  (run-with-both-implementations #'bench-cg-rect-union "CGRectUnion")
  (run-with-both-implementations #'bench-cg-rect-intersection "CGRectIntersection")
  (run-with-both-implementations #'bench-cg-affine-transform-rotation "CGAffineTransformMakeRotation")
  (run-with-both-implementations #'bench-cg-affine-transform-concat "CGAffineTransformConcat")
  (run-with-both-implementations #'bench-cg-point-apply-transform "CGPointApplyAffineTransform")
  (run-with-both-implementations #'bench-cg-rect-apply-transform "CGRectApplyAffineTransform"))

#-darwin
(defun run-cocoa-benchmarks ()
  "Cocoa is only available on macOS."
  (format t "~&Cocoa benchmarks only available on macOS, skipping.~%"))

;;;============================================================================
;;; BLAS Bindings and Benchmarks (Complex Numbers)
;;;============================================================================

;;; BLAS uses complex numbers which are effectively structs
;;; zdotc returns complex double (16 bytes)

;; Complex double (16 bytes)
(defcstruct complex-double
  "Complex double (16 bytes)."
  (real :double)
  (imag :double))

;; Complex float (8 bytes)
(defcstruct complex-float
  "Complex float (8 bytes)."
  (real :float)
  (imag :float))

(defun define-blas-functions ()
  "Define BLAS foreign functions for complex operations."
  ;; Note: BLAS naming conventions vary by implementation
  ;; Some use zdotc_, some use cblas_zdotc_sub, etc.

  ;; For reference BLAS (returns via hidden first argument):
  ;; void zdotc_(complex *result, int *n, complex *x, int *incx, complex *y, int *incy)

  ;; For CBLAS (Apple Accelerate uses this on newer versions):
  ;; void cblas_zdotc_sub(int n, void *x, int incx, void *y, int incy, void *result)

  ;; Unfortunately, most BLAS implementations don't return complex by value
  ;; They use a hidden pointer parameter. So we'll simulate with our own lib.
  t)

(defun run-blas-benchmarks ()
  "Run BLAS benchmarks."
  ;; BLAS complex return semantics vary widely, so we skip this for now
  ;; Our custom libbench already covers the same struct sizes
  (format t "~&~%=== BLAS Benchmarks ===~%")
  (format t "Note: Most BLAS implementations use hidden pointer returns for complex.~%")
  (format t "The core benchmarks cover equivalent struct sizes (complex-double = 16B).~%"))

;;;============================================================================
;;; Main runner for real-world benchmarks
;;;============================================================================

(defun run-real-world-benchmarks ()
  "Run all real-world library benchmarks."
  (check-library-availability)
  (run-clang-benchmarks)
  (run-cocoa-benchmarks)
  (run-blas-benchmarks))
