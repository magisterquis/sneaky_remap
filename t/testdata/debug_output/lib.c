/*
 * lib.c
 * Just hide a library
 * By J. Stuart McMurray
 * Created 20250728
 * Last Modified 20250730
 */

#include <err.h>
#include <stdlib.h>

#include "sneaky_remap.h"

/* ctor is run on library load.  It copies /proc/self/maps to BEFORE, hides
 * itself with sneaky_remap and makes sure the thread is running after
 * sneaky_remap returns, then copies /proc/self/maps to AFTER. */
static void __attribute__((constructor))
ctor(void)
{
        int ret; 

        /* Save a copy of the maps as they are now so we can check if our debug
         * output is correct. */
        if (0 != system("cat </proc/$PPID/maps >maps_loaded"))
                err(10, "system");

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
}

