# cython: language_level=3

import cython
from cpython.pycapsule cimport PyCapsule_New

from libc.stdint cimport int64_t
from libc.math cimport NAN


@cython.cdivision(True)
cdef void _tdma_cython_double(int64_t n, double* a, double* b, double* c, double* d, double* cp, double* out) nogil:
    cdef:
        int64_t i
        double denom

    cp[0] = c[0] / b[0]
    out[0] = d[0] / b[0]

    for i in range(1, n):
        denom = 1. / (b[i] - a[i] * cp[i - 1])
        cp[i] = c[i] * denom
        out[i] = (d[i] - a[i] * out[i - 1]) * denom

    for i in range(n - 2, -1, -1):
        out[i] -= cp[i] * out[i + 1]


@cython.cdivision(True)
cdef void _tdma_cython_float(int64_t n, float* a, float* b, float* c, float* d, float* cp, float* out) nogil:
    cdef:
        int64_t i
        float denom

    cp[0] = c[0] / b[0]
    out[0] = d[0] / b[0]

    for i in range(1, n):
        denom = 1. / (b[i] - a[i] * cp[i - 1])
        cp[i] = c[i] * denom
        out[i] = (d[i] - a[i] * out[i - 1]) * denom

    for i in range(n - 2, -1, -1):
        out[i] -= cp[i] * out[i + 1]


cdef void tdma_cython_double(void* out_ptr, void** data_ptr) nogil:
    cdef:
        int64_t i, j, system_depth, system_start
        int64_t ii = 0

        # decode inputs
        double* a = (<double*>data_ptr[0])
        double* b = (<double*>data_ptr[1])
        double* c = (<double*>data_ptr[2])
        double* d = (<double*>data_ptr[3])
        int64_t* system_depths = (<int64_t*>data_ptr[4])
        int64_t num_systems = (<int64_t*>data_ptr[5])[0]
        int64_t stride = (<int64_t*>data_ptr[6])[0]
        double* cp = (<double*>data_ptr[7])
        double* out = (<double*>out_ptr)

    for i in range(num_systems):
        system_depth = system_depths[i]
        system_start = stride - system_depth

        for j in range(system_start):
            out[ii + j] = NAN

        _tdma_cython_double(
            system_depth,
            &a[ii + system_start],
            &b[ii + system_start],
            &c[ii + system_start],
            &d[ii + system_start],
            cp,
            &out[ii + system_start],
        )

        ii += stride


cdef void tdma_cython_float(void* out_ptr, void** data_ptr) nogil:
    cdef:
        int64_t i, j, system_depth, system_start
        int64_t ii = 0

        # decode inputs
        float* a = (<float*>data_ptr[0])
        float* b = (<float*>data_ptr[1])
        float* c = (<float*>data_ptr[2])
        float* d = (<float*>data_ptr[3])
        int64_t* system_depths = (<int64_t*>data_ptr[4])
        int64_t num_systems = (<int64_t*>data_ptr[5])[0]
        int64_t stride = (<int64_t*>data_ptr[6])[0]
        float* cp = (<float*>data_ptr[7])
        float* out = (<float*>out_ptr)

    for i in range(num_systems):
        system_depth = system_depths[i]
        system_start = stride - system_depth

        for j in range(system_start):
            out[ii + j] = NAN

        _tdma_cython_float(
            system_depth,
            &a[ii + system_start],
            &b[ii + system_start],
            &c[ii + system_start],
            &d[ii + system_start],
            cp,
            &out[ii + system_start],
        )

        ii += stride


cpu_custom_call_targets = {}

cdef register_custom_call_target(fn_name, void* fn):
    cdef const char* name = 'xla._CUSTOM_CALL_TARGET'
    cpu_custom_call_targets[fn_name] = PyCapsule_New(fn, name, NULL)

register_custom_call_target(b'tdma_cython_double', <void*>(tdma_cython_double))
register_custom_call_target(b'tdma_cython_float', <void*>(tdma_cython_float))
