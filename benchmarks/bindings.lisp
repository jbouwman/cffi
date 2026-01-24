;;;; -*- Mode: lisp; indent-tabs-mode: nil -*-
;;;
;;; bindings.lisp --- CFFI bindings for benchmark library.
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

;;; Load the benchmark library

(define-foreign-library libbench
  (:unix (:or "libbench.so" "./libbench.so"))
  (:darwin (:or "libbench.dylib" "./libbench.dylib"))
  (:windows "libbench.dll")
  (t (:default "libbench")))

(defun load-benchmark-library ()
  "Load the benchmark C library."
  (let ((lib-path (asdf:system-relative-pathname
                   "cffi-benchmarks" "benchmarks/libbench")))
    (unless (foreign-library-loaded-p 'libbench)
      (load-foreign-library
       (make-pathname :defaults lib-path
                      :type #+darwin "dylib"
                            #+windows "dll"
                            #-(or darwin windows) "so")))))

;; Try to load at compile/load time
(eval-when (:compile-toplevel :load-toplevel :execute)
  (ignore-errors (load-benchmark-library)))

;;;============================================================================
;;; Small Structs (8-16 bytes)
;;;============================================================================

(defcstruct point2i
  "2D point with integer coordinates (8 bytes)"
  (x :int32)
  (y :int32))

(defcstruct point2f
  "2D point with float coordinates (8 bytes)"
  (x :float)
  (y :float))

(defcstruct point2d
  "2D point with double coordinates (16 bytes)"
  (x :double)
  (y :double))

(defcstruct vec4f
  "4D vector with float components (16 bytes)"
  (x :float)
  (y :float)
  (z :float)
  (w :float))

;;;============================================================================
;;; Medium Structs (24-48 bytes)
;;;============================================================================

(defcstruct point3d
  "3D point with double coordinates (24 bytes)"
  (x :double)
  (y :double)
  (z :double))

(defcstruct rect
  "Rectangle with double coordinates (32 bytes)"
  (x :double)
  (y :double)
  (width :double)
  (height :double))

(defcstruct mat4-row
  "Single row of a 4x4 float matrix (16 bytes)"
  (m :float :count 4))

(defcstruct mat3d
  "3x3 double matrix (72 bytes)"
  (m :double :count 9))

;;;============================================================================
;;; Large Structs (64+ bytes)
;;;============================================================================

(defcstruct mat4f
  "4x4 float matrix (64 bytes)"
  (m :float :count 16))

(defcstruct mat4d
  "4x4 double matrix (128 bytes)"
  (m :double :count 16))

(defcstruct buffer256
  "256-byte buffer"
  (data :uint8 :count 256))

;;;============================================================================
;;; Nested Structs
;;;============================================================================

(defcstruct line2d
  "2D line segment (32 bytes)"
  (start (:struct point2d))
  (end (:struct point2d)))

(defcstruct triangle2d
  "2D triangle (48 bytes)"
  (a (:struct point2d))
  (b (:struct point2d))
  (c (:struct point2d)))

(defcstruct bounds3d
  "3D axis-aligned bounding box (48 bytes)"
  (min (:struct point3d))
  (max (:struct point3d)))

;;;============================================================================
;;; Mixed-type Structs
;;;============================================================================

(defcstruct mixed1
  "Mixed types with alignment padding"
  (c :char)
  (d :double)
  (i :int))

(defcstruct mixed2
  "Complex mixed types"
  (i :int32)
  (c1 :char)
  (s :int16)
  (c2 :char)
  (d :double))

(defcstruct mixed3
  "All primitive sizes"
  (a :uint8)
  (b :uint16)
  (c :uint32)
  (d :uint64)
  (f :float)
  (g :double))

;;;============================================================================
;;; Foreign Function Definitions - Small Structs
;;;============================================================================

(defcfun "make_point2i" (:struct point2i)
  (x :int32)
  (y :int32))

(defcfun "add_point2i" (:struct point2i)
  (a (:struct point2i))
  (b (:struct point2i)))

(defcfun "make_point2f" (:struct point2f)
  (x :float)
  (y :float))

(defcfun "add_point2f" (:struct point2f)
  (a (:struct point2f))
  (b (:struct point2f)))

(defcfun "make_point2d" (:struct point2d)
  (x :double)
  (y :double))

(defcfun "add_point2d" (:struct point2d)
  (a (:struct point2d))
  (b (:struct point2d)))

(defcfun "make_vec4f" (:struct vec4f)
  (x :float)
  (y :float)
  (z :float)
  (w :float))

(defcfun "add_vec4f" (:struct vec4f)
  (a (:struct vec4f))
  (b (:struct vec4f)))

(defcfun "dot_vec4f" :float
  (a (:struct vec4f))
  (b (:struct vec4f)))

;;;============================================================================
;;; Foreign Function Definitions - Medium Structs
;;;============================================================================

(defcfun "make_point3d" (:struct point3d)
  (x :double)
  (y :double)
  (z :double))

(defcfun "add_point3d" (:struct point3d)
  (a (:struct point3d))
  (b (:struct point3d)))

(defcfun "cross_point3d" (:struct point3d)
  (a (:struct point3d))
  (b (:struct point3d)))

(defcfun "make_rect" (:struct rect)
  (x :double)
  (y :double)
  (w :double)
  (h :double))

(defcfun "union_rect" (:struct rect)
  (a (:struct rect))
  (b (:struct rect)))

(defcfun "intersect_rect" (:struct rect)
  (a (:struct rect))
  (b (:struct rect)))

;;;============================================================================
;;; Foreign Function Definitions - Large Structs
;;;============================================================================

(defcfun "identity_mat4f" (:struct mat4f))

(defcfun "scale_mat4f" (:struct mat4f)
  (sx :float)
  (sy :float)
  (sz :float))

(defcfun "mul_mat4f" (:struct mat4f)
  (a (:struct mat4f))
  (b (:struct mat4f)))

(defcfun "identity_mat4d" (:struct mat4d))

(defcfun "mul_mat4d" (:struct mat4d)
  (a (:struct mat4d))
  (b (:struct mat4d)))

;;;============================================================================
;;; Foreign Function Definitions - Nested Structs
;;;============================================================================

(defcfun "make_line2d" (:struct line2d)
  (x1 :double)
  (y1 :double)
  (x2 :double)
  (y2 :double))

(defcfun "make_triangle2d" (:struct triangle2d)
  (ax :double)
  (ay :double)
  (bx :double)
  (by :double)
  (cx :double)
  (cy :double))

(defcfun "make_bounds3d" (:struct bounds3d)
  (minx :double)
  (miny :double)
  (minz :double)
  (maxx :double)
  (maxy :double)
  (maxz :double))

(defcfun "expand_bounds3d" (:struct bounds3d)
  (b (:struct bounds3d))
  (p (:struct point3d)))

;;;============================================================================
;;; Foreign Function Definitions - Mixed Types
;;;============================================================================

(defcfun "make_mixed1" (:struct mixed1)
  (c :char)
  (d :double)
  (i :int))

(defcfun "make_mixed2" (:struct mixed2)
  (i :int32)
  (c1 :char)
  (s :int16)
  (c2 :char)
  (d :double))

(defcfun "make_mixed3" (:struct mixed3)
  (a :uint8)
  (b :uint16)
  (c :uint32)
  (d :uint64)
  (f :float)
  (g :double))

;;;============================================================================
;;; Baseline Functions
;;;============================================================================

(defcfun "noop_int" :int)
(defcfun "noop_double" :double)
(defcfun "noop_void" :void)

;;;============================================================================
;;; Accumulator Functions
;;;============================================================================

(defcfun "accumulate_point2d" (:struct point2d)
  (acc (:struct point2d))
  (n :int))

(defcfun "normalize_vec4f" (:struct vec4f)
  (v (:struct vec4f)))

(defcfun "transpose_mat4f" (:struct mat4f)
  (m (:struct mat4f)))

;;;============================================================================
;;; Helper functions for creating test data
;;;============================================================================

(defun make-test-point2i (x y)
  "Create a plist representing a point2i."
  (list 'x x 'y y))

(defun make-test-point2f (x y)
  "Create a plist representing a point2f."
  (list 'x (float x) 'y (float y)))

(defun make-test-point2d (x y)
  "Create a plist representing a point2d."
  (list 'x (float x 1.0d0) 'y (float y 1.0d0)))

(defun make-test-vec4f (x y z w)
  "Create a plist representing a vec4f."
  (list 'x (float x) 'y (float y) 'z (float z) 'w (float w)))

(defun make-test-point3d (x y z)
  "Create a plist representing a point3d."
  (list 'x (float x 1.0d0) 'y (float y 1.0d0) 'z (float z 1.0d0)))

(defun make-test-rect (x y w h)
  "Create a plist representing a rect."
  (list 'x (float x 1.0d0)
        'y (float y 1.0d0)
        'width (float w 1.0d0)
        'height (float h 1.0d0)))
