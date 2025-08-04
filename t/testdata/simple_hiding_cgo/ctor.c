/*
 * ctor.c
 * Library constructor
 * By J. Stuart McMurray
 * Cretaed 20250730
 * Last Modified 20250730
 */

#include <stdio.h>
#include <err.h>

#include "sneaky_remap.h"

static void __attribute__((constructor (1000)))
ctor(void)
{
        int ret;

        /* Hide ourselves and dump the memory map. */
        switch (ret = sneaky_remap_start(NULL, NULL, 0)) {
                case SREM_RET_OK: /* Good. */
                        break;
                case SREM_RET_ERRNO: /* Not our fault, at least? */
                        warn("sneaky_remap_start");
                        break;
                default:
                        warnx("sneaky_remap error %d", ret);
                        break;
        }
        printf("In constructor\n"); fflush(stdout);
}
