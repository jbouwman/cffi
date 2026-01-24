/* -*- Mode: C; tab-width: 4; indent-tabs-mode: nil -*-
 *
 * libbench.c --- C library for struct-return-by-value benchmarks
 *
 * This library provides functions that return structs of various sizes
 * and complexity levels to benchmark libffi vs direct struct returns.
 *
 * Copyright (C) 2026, Jesse Bouwman
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use, copy,
 * modify, merge, publish, distribute, sublicense, and/or sell copies
 * of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 */

#ifdef WIN32
#define DLLEXPORT __declspec(dllexport)
#else
#define DLLEXPORT
#endif

#include <stdint.h>
#include <string.h>
#include <math.h>

/*============================================================================
 * Small Structs (typically register-passable on many ABIs)
 *============================================================================*/

/* 8 bytes - two ints, fits in one 64-bit register */
struct point2i {
    int32_t x;
    int32_t y;
};

/* 8 bytes - two floats */
struct point2f {
    float x;
    float y;
};

/* 16 bytes - two doubles, may use SSE registers */
struct point2d {
    double x;
    double y;
};

/* 16 bytes - four floats, SIMD-friendly */
struct vec4f {
    float x, y, z, w;
};

/*============================================================================
 * Medium Structs (may require stack return on some ABIs)
 *============================================================================*/

/* 24 bytes - 3D point with double precision */
struct point3d {
    double x, y, z;
};

/* 32 bytes - 4x double, like CGRect */
struct rect {
    double x, y, width, height;
};

/* 32 bytes - 4x4 float matrix row */
struct mat4_row {
    float m[4];
};

/* 48 bytes - 3x3 double matrix */
struct mat3d {
    double m[9];
};

/*============================================================================
 * Large Structs (always stack-returned)
 *============================================================================*/

/* 64 bytes - 4x4 float matrix */
struct mat4f {
    float m[16];
};

/* 128 bytes - 4x4 double matrix */
struct mat4d {
    double m[16];
};

/* 256 bytes - large buffer */
struct buffer256 {
    uint8_t data[256];
};

/*============================================================================
 * Nested Structs (tests struct composition)
 *============================================================================*/

struct line2d {
    struct point2d start;
    struct point2d end;
};

struct triangle2d {
    struct point2d a, b, c;
};

struct bounds3d {
    struct point3d min;
    struct point3d max;
};

/*============================================================================
 * Mixed-type Structs (tests alignment handling)
 *============================================================================*/

struct mixed1 {
    char c;
    double d;
    int i;
};

struct mixed2 {
    int32_t i;
    char c1;
    int16_t s;
    char c2;
    double d;
};

struct mixed3 {
    uint8_t a;
    uint16_t b;
    uint32_t c;
    uint64_t d;
    float f;
    double g;
};

/*============================================================================
 * Functions returning small structs (8-16 bytes)
 *============================================================================*/

DLLEXPORT
struct point2i make_point2i(int32_t x, int32_t y) {
    struct point2i p = {x, y};
    return p;
}

DLLEXPORT
struct point2i add_point2i(struct point2i a, struct point2i b) {
    struct point2i r = {a.x + b.x, a.y + b.y};
    return r;
}

DLLEXPORT
struct point2f make_point2f(float x, float y) {
    struct point2f p = {x, y};
    return p;
}

DLLEXPORT
struct point2f add_point2f(struct point2f a, struct point2f b) {
    struct point2f r = {a.x + b.x, a.y + b.y};
    return r;
}

DLLEXPORT
struct point2d make_point2d(double x, double y) {
    struct point2d p = {x, y};
    return p;
}

DLLEXPORT
struct point2d add_point2d(struct point2d a, struct point2d b) {
    struct point2d r = {a.x + b.x, a.y + b.y};
    return r;
}

DLLEXPORT
struct vec4f make_vec4f(float x, float y, float z, float w) {
    struct vec4f v = {x, y, z, w};
    return v;
}

DLLEXPORT
struct vec4f add_vec4f(struct vec4f a, struct vec4f b) {
    struct vec4f r = {a.x + b.x, a.y + b.y, a.z + b.z, a.w + b.w};
    return r;
}

DLLEXPORT
float dot_vec4f(struct vec4f a, struct vec4f b) {
    return a.x*b.x + a.y*b.y + a.z*b.z + a.w*b.w;
}

/*============================================================================
 * Functions returning medium structs (24-48 bytes)
 *============================================================================*/

DLLEXPORT
struct point3d make_point3d(double x, double y, double z) {
    struct point3d p = {x, y, z};
    return p;
}

DLLEXPORT
struct point3d add_point3d(struct point3d a, struct point3d b) {
    struct point3d r = {a.x + b.x, a.y + b.y, a.z + b.z};
    return r;
}

DLLEXPORT
struct point3d cross_point3d(struct point3d a, struct point3d b) {
    struct point3d r = {
        a.y * b.z - a.z * b.y,
        a.z * b.x - a.x * b.z,
        a.x * b.y - a.y * b.x
    };
    return r;
}

DLLEXPORT
struct rect make_rect(double x, double y, double w, double h) {
    struct rect r = {x, y, w, h};
    return r;
}

DLLEXPORT
struct rect union_rect(struct rect a, struct rect b) {
    double min_x = a.x < b.x ? a.x : b.x;
    double min_y = a.y < b.y ? a.y : b.y;
    double max_x1 = a.x + a.width;
    double max_x2 = b.x + b.width;
    double max_y1 = a.y + a.height;
    double max_y2 = b.y + b.height;
    double max_x = max_x1 > max_x2 ? max_x1 : max_x2;
    double max_y = max_y1 > max_y2 ? max_y1 : max_y2;
    struct rect r = {min_x, min_y, max_x - min_x, max_y - min_y};
    return r;
}

DLLEXPORT
struct rect intersect_rect(struct rect a, struct rect b) {
    double x1 = a.x > b.x ? a.x : b.x;
    double y1 = a.y > b.y ? a.y : b.y;
    double x2a = a.x + a.width;
    double x2b = b.x + b.width;
    double y2a = a.y + a.height;
    double y2b = b.y + b.height;
    double x2 = x2a < x2b ? x2a : x2b;
    double y2 = y2a < y2b ? y2a : y2b;
    double w = x2 - x1;
    double h = y2 - y1;
    if (w < 0) w = 0;
    if (h < 0) h = 0;
    struct rect r = {x1, y1, w, h};
    return r;
}

/*============================================================================
 * Functions returning large structs (64+ bytes)
 *============================================================================*/

DLLEXPORT
struct mat4f identity_mat4f(void) {
    struct mat4f m = {{
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1
    }};
    return m;
}

DLLEXPORT
struct mat4f scale_mat4f(float sx, float sy, float sz) {
    struct mat4f m = {{
        sx, 0, 0, 0,
        0, sy, 0, 0,
        0, 0, sz, 0,
        0, 0, 0, 1
    }};
    return m;
}

DLLEXPORT
struct mat4f mul_mat4f(struct mat4f a, struct mat4f b) {
    struct mat4f r;
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
            r.m[i*4+j] = 0;
            for (int k = 0; k < 4; k++) {
                r.m[i*4+j] += a.m[i*4+k] * b.m[k*4+j];
            }
        }
    }
    return r;
}

DLLEXPORT
struct mat4d identity_mat4d(void) {
    struct mat4d m = {{
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1
    }};
    return m;
}

DLLEXPORT
struct mat4d mul_mat4d(struct mat4d a, struct mat4d b) {
    struct mat4d r;
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
            r.m[i*4+j] = 0;
            for (int k = 0; k < 4; k++) {
                r.m[i*4+j] += a.m[i*4+k] * b.m[k*4+j];
            }
        }
    }
    return r;
}

/*============================================================================
 * Functions with nested struct returns
 *============================================================================*/

DLLEXPORT
struct line2d make_line2d(double x1, double y1, double x2, double y2) {
    struct line2d l;
    l.start.x = x1;
    l.start.y = y1;
    l.end.x = x2;
    l.end.y = y2;
    return l;
}

DLLEXPORT
struct triangle2d make_triangle2d(double ax, double ay,
                                   double bx, double by,
                                   double cx, double cy) {
    struct triangle2d t;
    t.a.x = ax; t.a.y = ay;
    t.b.x = bx; t.b.y = by;
    t.c.x = cx; t.c.y = cy;
    return t;
}

DLLEXPORT
struct bounds3d make_bounds3d(double minx, double miny, double minz,
                               double maxx, double maxy, double maxz) {
    struct bounds3d b;
    b.min.x = minx; b.min.y = miny; b.min.z = minz;
    b.max.x = maxx; b.max.y = maxy; b.max.z = maxz;
    return b;
}

DLLEXPORT
struct bounds3d expand_bounds3d(struct bounds3d b, struct point3d p) {
    if (p.x < b.min.x) b.min.x = p.x;
    if (p.y < b.min.y) b.min.y = p.y;
    if (p.z < b.min.z) b.min.z = p.z;
    if (p.x > b.max.x) b.max.x = p.x;
    if (p.y > b.max.y) b.max.y = p.y;
    if (p.z > b.max.z) b.max.z = p.z;
    return b;
}

/*============================================================================
 * Functions with mixed-type struct returns
 *============================================================================*/

DLLEXPORT
struct mixed1 make_mixed1(char c, double d, int i) {
    struct mixed1 m = {c, d, i};
    return m;
}

DLLEXPORT
struct mixed2 make_mixed2(int32_t i, char c1, int16_t s, char c2, double d) {
    struct mixed2 m = {i, c1, s, c2, d};
    return m;
}

DLLEXPORT
struct mixed3 make_mixed3(uint8_t a, uint16_t b, uint32_t c, uint64_t d,
                           float f, double g) {
    struct mixed3 m = {a, b, c, d, f, g};
    return m;
}

/*============================================================================
 * No-op baseline functions for measuring call overhead
 *============================================================================*/

DLLEXPORT
int noop_int(void) {
    return 42;
}

DLLEXPORT
double noop_double(void) {
    return 3.14159;
}

DLLEXPORT
void noop_void(void) {
}

/*============================================================================
 * Functions for accumulator/loop benchmarks
 *============================================================================*/

DLLEXPORT
struct point2d accumulate_point2d(struct point2d acc, int n) {
    for (int i = 0; i < n; i++) {
        acc.x += 1.0;
        acc.y += 0.5;
    }
    return acc;
}

DLLEXPORT
struct vec4f normalize_vec4f(struct vec4f v) {
    float len = sqrtf(v.x*v.x + v.y*v.y + v.z*v.z + v.w*v.w);
    if (len > 0) {
        v.x /= len;
        v.y /= len;
        v.z /= len;
        v.w /= len;
    }
    return v;
}

DLLEXPORT
struct mat4f transpose_mat4f(struct mat4f m) {
    struct mat4f r;
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
            r.m[i*4+j] = m.m[j*4+i];
        }
    }
    return r;
}
