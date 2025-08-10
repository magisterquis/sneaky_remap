/*
 * readme_theory.c
 * Load sneaky_remap
 * By J. Stuart McMurray
 * Created 20250810
 * Last Modified 20250810
 */

#include <err.h>
#include <stdlib.h>

#include "sneaky_remap.h"

#define MAPS_BEFORE "maps_before"

static void __attribute__((constructor))
ctor(void)
{
        int ret;

        /* Grab our mapped memory before hiding the library. */
        switch (ret = system("cat </proc/$PPID/maps >" MAPS_BEFORE)) {
                case 0: /* Good. */
                        break;
                case -1: /* Systemsy error. */
                        err(10, "system (before)");
                default: /* Command error. */
                        errx(11, "cat returned %d getting before maps", ret);
        }

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
