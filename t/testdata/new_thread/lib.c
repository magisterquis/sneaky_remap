/*
 * lib.c
 * Hide a library which spawns a new thread
 * By J. Stuart McMurray
 * Created 20250725
 * Last Modified 20250730
 */

#include <err.h>
#include <stdio.h>
#include <unistd.h>

#include "sneaky_remap.h"

/* THREAD_MESSAGE is printed by the thread after we're remapped. */
#define THREAD_MESSAGE "In thread"

/* start_routine waits for a read on fd u (cast to an integer) to unblock, then
 * prints THREAD_MESSAGE. */
void *
start_routine(void *u)
{
        int *filedes;
        char buf;

        filedes = (int *)u;

        /* Wait for the remap to happen. */
        if (1 != read(filedes[0], &buf, 1))
                err(16, "read");

        /* Let everybody know the thread is still ok. */
        printf("%s\n", THREAD_MESSAGE);
        fflush(stdout);

        /* Let ctor know we're done. */
        if (1 != write(filedes[3], &buf, 1))
                err(17, "write");

        return NULL;
}

/* ctor is run on library load.  It copies /proc/self/maps to BEFORE, hides
 * itself with sneaky_remap and makes sure the thread is running after
 * sneaky_remap returns, then copies /proc/self/maps to AFTER. */
static void __attribute__((constructor))
ctor(void)
{
        char buf;
        int  filedes[4];
        int  ret;

        /* We'll use this pipe to signal to the thread to try to print after
         * memory has been remapped. */
        if (-1 == pipe(filedes))
                err(18, "pipe (to thread)");
        if (-1 == pipe(filedes + 2))
                err(19, "pipe (from thread)");

        /* Hide ourselves and dump the memory map. */
        switch (ret = sneaky_remap_start(start_routine, filedes, 0)) {
                case SREM_RET_OK: /* Good. */
                        break;
                case SREM_RET_ERRNO: /* Not our fault, at least? */
                        warn("sneaky_remap_start");
                        break;
                default:
                        warnx("sneaky_remap error %d", ret);
                        break;
        }

        /* Tell the thread to print. */
        buf = 'x';
        if (1 != write(filedes[1], &buf, 1))
                err(20, "write");

        /* Wait for the print to happen. */
        if (1 != read(filedes[2], &buf, 1))
                err(21, "read");
}
