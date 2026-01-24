;;;; -*- Mode: lisp; indent-tabs-mode: nil -*-
;;;
;;; package.lisp --- Package definition for CFFI struct-return benchmarks.
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

(defpackage #:cffi-benchmarks
  (:use #:cl #:cffi)
  (:export
   ;; Benchmark running
   #:run-all-benchmarks
   #:run-benchmark
   #:run-comparison

   ;; Individual benchmark suites
   #:run-small-struct-benchmarks
   #:run-medium-struct-benchmarks
   #:run-large-struct-benchmarks
   #:run-nested-struct-benchmarks
   #:run-mixed-struct-benchmarks

   ;; Real-world library benchmarks
   #:run-blas-benchmarks
   #:run-clang-benchmarks
   #:run-cocoa-benchmarks

   ;; Utilities
   #:benchmark
   #:with-timing
   #:format-results
   #:compare-implementations

   ;; Configuration
   #:*benchmark-iterations*
   #:*warmup-iterations*
   #:*use-libffi*
   #:*verbose*))
