/*
 * test_loader.c
 * Simple loader for test sneaky remappy libraries 
 * By J. Stuart McMurray
 * Created 20250726
 * Last Modified 20250801
 */

#include <dlfcn.h>
#include <err.h>
#include <fcntl.h>
#include <stdint.h>
#include <strings.h>
#include <unistd.h>

#define BUFLEN 1024 /* Buffer length. */

/* Files to which to save /proc/self/maps, before and after calling dlopen. */
#define BEFORE "maps_before"
#define AFTER  "maps_after"

/* Function to call to wait for the loaded library to get to a point where we
 * should inspect maps, such as a thread starting or finishing.  It should
 * return 0 on success. */
#define SOWAIT "sowait"

/* sowait func is the type of SOWAIT. */
typedef int (*sowait_func)(void);

static void save_maps(const char *);

/* load a shared object file, saving /proc/self/maps before and after. */
int
main(int argc, char **argv)
{
        int          ret;
        sowait_func  sowait;
        void        *lib;

        /* Make sure we have the requisite arguments. */
        if (2 != argc)
                errx(10, "usage: %s lib.so", argv[0]);

        /* Files mapped before we load our hidey library. */
        save_maps(BEFORE);

        /* Load the sneaky library. */
        if (NULL == (lib = dlopen(argv[1], RTLD_LAZY)))
                err(11, "dlopen: %s", dlerror());

        /* If the loaded library has a sowait function, call it to let a
         * thread finish, or similar. */
        if (NULL != (sowait = (sowait_func)(uintptr_t)dlsym(lib, SOWAIT)))
                if (0 != (ret = sowait()))
                        errx(12, "sowait returned %d", ret);

        /* Files mapped after we load our hidey library. */
        save_maps(AFTER);

        return 0;
}

/* save_maps saves /proc/self/maps to the file dest. */
static void
save_maps(const char *dest)
{
        char    buf[BUFLEN];
        int     sfd, dfd;
        ssize_t nw, nr, off;

        /* Open the source and destination files. */
        if (-1 == (dfd = open(dest, O_WRONLY|O_CREAT|O_TRUNC, 0600)))
                err(13, "open maps dest %s", dest);
        if (-1 == (sfd = open("/proc/self/maps", O_RDONLY)))
                err(14, "open /proc/self/maps");

        /* Copy ALL the bytes! */
        bzero(buf, sizeof(buf));
        while (-1 != (nr = read(sfd, buf, sizeof(buf))) && 0 != nr)
                for (off = 0; off < nr; off += nw)
                        if (0 == (nw = write(dfd, buf + off, nr - off))
                                        || -1 == nw)
                                err(15, "write");
        if (-1 == nr)
                err(16, "read");

        close(dfd);
        close(sfd);
}
