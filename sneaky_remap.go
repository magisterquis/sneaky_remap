//go:build linux

// Package sneaky_remap uses CGO to hide its own shared object file from
// /proc/pid/maps on Linux.
//
// It does this reading /proc/self/maps to figure out where it's mapped,
// copying the mapped pages to newly-created pages with the same permissions,
// and using mremap(2) to pull a switcheroo before anybody notices.
//
// Please see https://github.com/magisterquis/sneaky_remap for more details.
//
// # Usage
//
// There is no exposed (Go) API.  It is sufficient to simply the package, e.g.:
//
//	import _ "github.com/magisterquis/sneaky_remap_preview"
//
// # Configuration
//
// Configuration is done via the following C Preprocessor macros, both of which
// are optional:
//   - SREM_CGO_START_ROUTINE - A function to start in its own thread after the
//     shared object file is hidden.
//     This can either be a C function of type void *f(void *) or a Go function
//     of type func(unsafe.Pointer) unsafe.Pointer.
//     NULL/nil will be passed to the function.
//   - SREM_CGO_START_FLAGS - Any combination of the SREM_SRS_* constants.
//
// These may be passed using the CGO_CFLAGS environment variable, e.g.
//
//	export CGO_CFLAGS="-DSREM_CGO_START_ROUTINE=doit \
//	        -DSREM_CGO_START_FLAGS=SREM_SRS_UNLINK"
package sneaky_remap

/*
 * sneaky_remap.go
 * Hide a shared object file from /proc/pid/maps
 * By J. Stuart McMurray
 * Created 20250730
 * Last Modified 20250816
 */

// #include <err.h>
//
// #include "sneaky_remap.h"
//
// #ifndef SREM_CGO_START_ROUTINE
// #define SREM_CGO_START_ROUTINE NULL
// #else
// extern void *SREM_CGO_START_ROUTINE(void *);
// #endif
//
// /* Flags to pass to sneaky_remap_start, any combination of the SREM_SRS_*
// constants. */
// #ifndef SREM_CGO_START_FLAGS
// #define SREM_CGO_START_FLAGS 0
// #endif
//
// /* sneaky_remap_start_ret is the value returned by sneaky_remap_start, one
// of the SREM_RET_* constants. */
// int sneaky_remap_start_ret;
//
// /* ctor calls the C code behind sneaky_remap.  We set the constructor
// priority so it runs when the process is (hopefully) still single-threaded,
// i.e. before the Go runtime starts. */
// static void __attribute__((constructor (5000)))
// ctor(void)
// {
//         sneaky_remap_start_ret = sneaky_remap_start(
//                         SREM_CGO_START_ROUTINE,
//                         NULL,
//                         SREM_CGO_START_FLAGS);
// }
import "C"

func main() {}
