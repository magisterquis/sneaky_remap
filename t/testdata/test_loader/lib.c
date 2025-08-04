/*
 * lib.c
 * Just hide the library
 * By J. Stuart McMurray
 * Created 20250728
 * Last Modified 20250730
 */

#include <err.h>
#include <stddef.h>

#include "sneaky_remap.h"

/* Compile-time settable sneaky_remap_start flags. */
#ifndef SRSFLAGS
#define SRSFLAGS 0
#endif /* #ifndef SRSFLAGS */

/* ctor is run on library load.  It copies /proc/self/maps to BEFORE, hides
 * itself with sneaky_remap and makes sure the thread is running after
 * sneaky_remap returns, then copies /proc/self/maps to AFTER. */
static void __attribute__((constructor))
ctor(void)
{
        int ret; 

        /* Hide ourselves and dump the memory map. */
        switch (ret = sneaky_remap_start(NULL, NULL, SRSFLAGS)) {
                case SREM_RET_OK: /* Good. */
                        break;
                case SREM_RET_ERRNO: /* Not our fault, at least? */
                        warn("sneaky_remap_start");
                        break;
                default:
                        warnx("sneaky_remap error %d", ret);
                        break;
        }
}
