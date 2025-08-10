/*
 * readme_theory.c
 * Load sneaky_remap
 * By J. Stuart McMurray
 * Created 20250810
 * Last Modified 20250810
 */

#include <dlfcn.h>
#include <err.h>
#include <stdlib.h>

#define LIB        "./readme_theory.so"
#define MAPS_AFTER "maps_after"

/* Save /proc/self/maps to files before and after loading LIB. */
int
main(void)
{
        int ret;

        /* Load our hidey library. */
        if (NULL == dlopen(LIB, RTLD_LAZY))
                errx(12, "dlopen: %s", dlerror());

        /* Grab our mapped memory before hiding the library. */
        switch (ret = system("cat </proc/$PPID/maps >" MAPS_AFTER)) {
                case 0: /* Good. */
                        break;
                case -1: /* Systemsy error. */
                        err(13, "system (after)");
                default: /* Command error. */
                        errx(13, "cat returned %d getting after maps", ret);
        }

        system("ls -lart /proc/$PPID/map_files/* >/tmp/t");
}
