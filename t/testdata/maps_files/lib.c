/*
 * lib.c
 * Make copies of several files before and after hiding
 * By J. Stuart McMurray
 * Created 20250801
 * Last Modified 20250801
 */

#define _GNU_SOURCE
#include <sys/types.h>

#include <dirent.h>
#include <err.h>
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <unistd.h>

#include "sneaky_remap.h"

#define BUFLEN     1024
#define MAP_FILES "map_files"

/* File suffixes. */
#define AFTER  "after"
#define BEFORE "before"

static void copy_file(const char *, const char *, const char *);
static void save_map_files(const char *, const char *);

/* files is the list of files in /proc/self we'll inspect for traces of us. */
char *copy_pairs[] = {
        "maps_inlib", "/proc/self/maps",
        "numa_maps",  "/proc/self/numa_maps",
        "smaps",      "/proc/self/smaps",
        NULL,
};

/* ctor is run on library load.  It copies /proc/self/maps to BEFORE, hides
 * itself with sneaky_remap and makes sure the thread is running after
 * sneaky_remap returns, then copies /proc/self/maps to AFTER. */
static void __attribute__((constructor))
ctor(void)
{
        int  i, ret; 

        /* Copy files and such in /proc/self.  We should be visible.  We don't
         * actually use these in testing, but they're helpful for debugging. */
        for (i = 0; NULL != copy_pairs[i]; i += 2)
                copy_file(copy_pairs[i], BEFORE, copy_pairs[i+1]);
        save_map_files(MAP_FILES, BEFORE);

        /* Hide ourselves and dump the memory map. */
        switch (ret = sneaky_remap_start(NULL, NULL, 0)) {
                case SREM_RET_OK: /* Good. */
                        break;
                case SREM_RET_ERRNO: /* Not our fault, at least? */
                        err(20, "sneaky_remap_start");
                        break;
                default:
                        errx(21, "sneaky_remap error %d", ret);
                        break;
        }

        /* Copy files and such in /proc/self.  We should be invisible. */
        for (i = 0; NULL != copy_pairs[i]; i += 2)
                copy_file(copy_pairs[i], AFTER, copy_pairs[i+1]);
        save_map_files(MAP_FILES, AFTER);
}

/* copy_file copies the file named src to the file named dst, to which _suffix
 * will be appended. */
static void
copy_file(const char *dst, const char *suffix, const char *src)
{
        char     buf[BUFLEN];
        char    *sdst;
        int      sfd, dfd;
        ssize_t  nw, nr, off;

        sfd = dfd = -1;
        sdst = NULL;

        /* Make the destination filename. */
        if (-1 == asprintf(&sdst, "%s_%s", dst, suffix))
                err(22, "asprintf");

        /* Open the source and destination files. */
        if (-1 == (dfd = open(sdst, O_WRONLY|O_CREAT|O_TRUNC, 0600)))
                err(23, "open dst %s", dst);
        if (-1 == (sfd = open(src, O_RDONLY)))
                err(24, "open src %s", src);

        /* Copy ALL the bytes! */
        bzero(buf, sizeof(buf));
        while (-1 != (nr = read(sfd, buf, sizeof(buf))) && 0 != nr)
                for (off = 0; off < nr; off += nw)
                        if (0 == (nw = write(dfd, buf + off, nr - off))
                                        || -1 == nw)
                                err(25, "write");
        if (-1 == nr)
                err(26, "read");

        /* Cleanup. */
        if (-1   != dfd)  close(dfd);
        if (-1   != sfd)  close(sfd);
        if (NULL != sdst) free(sdst);
}

/* save_map_files saves the targets of the symlinks from /proc/self/map_files
 * in the file named dst, to which _suffix will be appended. */
static void
save_map_files(__attribute__((unused)) const char *dst, __attribute__((unused)) const char *suffix)
{
        DIR    *mfd;
        FILE   *d;
        char    buf[PATH_MAX];
        char   *sdst;
        struct  dirent *dp;

        d    = NULL;
        mfd  = NULL;
        sdst = NULL;

        /* Make the destination filename. */
        if (-1 == asprintf(&sdst, "%s_%s", dst, suffix))
                err(27, "asprintf");

        /* Open our output file. */
        if (NULL == (d = fopen(sdst, "wa")))
                err(28, "fopen");

        /* Open the map_files directory, in which we'll find symlinks. */
        if (NULL == (mfd = opendir("/proc/self/map_files")))
                err(29, "opendir");

        /* Grab ALL the symlinks. */
        errno = 0;
        for (;;) {
                /* Get the next directory entry. */
                errno = 0;
                if (NULL == (dp = readdir(mfd))) {
                        if (0 != errno)
                                err(30, "readdir");
                        break;
                }
                /* Ignore . and .. */
                if (0 == strcmp(".", dp->d_name) ||
                                0 == strcmp("..", dp->d_name))
                        continue;

                /* Should be a symlink, dereference. */
                bzero(buf, sizeof(buf));
                if (DT_LNK != dp->d_type)
                        errx(31, "unexpected type %d for %s",
                                        dp->d_type, dp->d_name);
                if (-1 == readlinkat(dirfd(mfd), dp->d_name, buf, PATH_MAX))
                        err(32, "readlinkat %s", dp->d_name);
                if ('\0' != buf[PATH_MAX-1])
                        errx(33, "map_files/%s target too long", dp->d_name);

                /* All is good, save it. */
                if (0 > fprintf(d, "%s\n", buf))
                        err(34, "fprintf");
        }


        if (NULL != mfd)  closedir(mfd);
        if (NULL != d)    fclose(d);
        if (NULL != sdst) free(sdst);
}
