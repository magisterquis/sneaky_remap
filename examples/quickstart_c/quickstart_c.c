/*
 * quickstart_c.c
 * Quickly start using sneaky_remap with C
 * By J. Stuart McMurray
 * Created 20250816
 * Last Modified 20250816
 */

#include <err.h>
#include <stddef.h>

#include "sneaky_remap.h"

static void __attribute__((constructor))
ctor(void)
{
        int ret;

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
