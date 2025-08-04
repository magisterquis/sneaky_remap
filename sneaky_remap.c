/*
 * sneaky_remap.c
 * Sneakily remap this shared object file to avoid being seen in /proc/pid/maps
 * By J. Stuart McMurray
 * Created 20250725
 * Last Modified 20250730
 */

#define _GNU_SOURCE

#include <sys/mman.h>

#include <dlfcn.h>
#include <errno.h>
#include <limits.h>
#include <pthread.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <unistd.h>

#include "sneaky_remap.h"

/* MAPS_FILE is where we read the currently-mapped memory pages. */
#define MAPS_FILE "/proc/self/maps"

/* VOIDP converts its argument to a void*, for %p. */
#define VOIDP(x) ((void *)(uintptr_t)(x))

/* C is a silly thing. */
#define xstr(s) str(s)
#define str(s) #s

/* Debug-only printing. */
#ifdef SREM_DEBUG
#include <err.h>
#define DPRINTF(...) do {                             \
        fprintf(stderr, __VA_ARGS__); fflush(stderr); \
} while (0)
#define DWARN(...)  warn(__VA_ARGS__)
#define DWARNX(...) warnx(__VA_ARGS__)
#define D_RET_ERRNO(...) do { \
        int saved_errno;      \
        saved_errno = errno;  \
        DWARN(__VA_ARGS__);   \
        errno = saved_errno;  \
        return SREM_RET_ERRNO;   \
} while (0)

#else /* #ifdef SREM_DEBUG */
#define DPRINTF(...)     do {} while (0)
#define DWARN(...)       do {} while (0)
#define DWARNX(...)      do {} while (0)
#define D_RET_ERRNO(...) return SREM_RET_ERRNO
#endif /* #ifdef SREM_DEBUG */

/* struct map holds relevant info about mapped memory. */
struct map {
        char      path[PATH_MAX+1];
        int       prot;
        size_t    length;
        uintptr_t start;
};

static int filter_mapped_files(struct map *maps, int *nmaps, char *path);
static int find_our_path(      struct map *maps, int  nmaps, struct map *pmap);
static int overmap_files(      struct map *maps, int *nmaps);
static int read_mapped_files(  struct map *maps, int *nmaps);

/* sneaky_remap_start shuffles memory around to remove this shared object
 * file's path from /proc/self/maps and then starts start_routine in its own
 * thread. */
int
sneaky_remap_start(void *(start_routine)(void *), void *arg, int flags)
{
        int ret, nmaps;
        struct map maps[SREM_MAX_MAPS];
        struct map pmap;
        pthread_t tid;
        pthread_attr_t attr;

        /* Get a list of mapped files. */
        bzero(maps, sizeof(maps));
        nmaps = 0;
        if (SREM_RET_OK != (ret = read_mapped_files(maps, &nmaps)))
                return ret;

        /* Find our own path. */
        if (SREM_RET_OK != (ret = find_our_path(maps, nmaps, &pmap)))
                return ret;

        /* Filter to the ones which contain us. */
        if (SREM_RET_OK != (ret = filter_mapped_files(maps, &nmaps,
                                        pmap.path)))
                return ret;

        /* Copy the mapped sections to somewhere else, then remap them back. */
        if (SREM_RET_OK != (ret = overmap_files(maps, &nmaps)))
                return ret;

        /* Increase the count of things which have us open, to keep bash from
         * unloading us. */
        if (flags & SREM_SRS_DLOPEN) {
                if (NULL == dlopen(pmap.path, RTLD_NOW)) {
                        DWARNX("dlopen %s: %s", pmap.path, dlerror());
                        return SREM_RET_EDLOPEN;
                } else
                        DPRINTF("dlopen success\n");
        }

        /* Save a potential call to rm(1). */
        if (flags & SREM_SRS_UNLINK) {
                if (-1 == unlink(pmap.path))
                        D_RET_ERRNO("unlink %s", pmap.path);
                else
                        DPRINTF("unlink success (%s)\n", pmap.path);
        }

        DPRINTF("Invisibility cloak active!!!\n");

        /* Start the thread going. */
        if (NULL != start_routine) {
                if (-1 == pthread_attr_init(&attr))
                        D_RET_ERRNO("pthread_attr_init");
                if (-1 == pthread_attr_setdetachstate(&attr,
                                        PTHREAD_CREATE_DETACHED))
                        D_RET_ERRNO("pthread_attr_setdetachstate");
                if (-1 == (ret = pthread_create(&tid, &attr, start_routine,
                                                arg))) {
                        errno = ret;
                        D_RET_ERRNO("pthread_create");
                }
        }

        return SREM_RET_OK;
}

/* read_mapped_files reads the list of mapped files from /proc/self/maps.  maps
 * must have space for at least SREM_MAX_MAPS maps.  The number of maps is
 * returned in nmaps. */
static int
read_mapped_files(struct map *maps, int *nmaps) {
        FILE      *psm;
        char       mode[2], prot[4];
        char      *line;
        int        ret, saved_errno, sret;
        size_t     linesize, pathlen;
        ssize_t    linelen;
        uintptr_t  end;

        ret = SREM_RET_OK;
        saved_errno = 0;

        /* Get hold of /proc/self/maps. */
        mode[0] = 'r';
        mode[1] = 0;
        if (NULL == (psm = fopen(MAPS_FILE, mode)))
                D_RET_ERRNO("open %s", MAPS_FILE);

        /* Read ALL the (file) maps. */
        *nmaps   = -1;
        line     = NULL;
        linesize = 0;
        while (-1 != (linelen = getline(&line, &linesize, psm))) {
                /* Make sure we still have space. */
                if (SREM_MAX_MAPS <= ++(*nmaps)) {
                        DWARNX("%s too big", MAPS_FILE);
                        ret = SREM_RET_TOOMANYMAPS;
                        goto out;
                }
                /* Get the important bits. */
                bzero(&maps[*nmaps], sizeof(maps[*nmaps]));
                sret = sscanf(line,
                                "%lx-%lx %4c %*s %*s %*s %"xstr(PATH_MAX)"[\x01-\xff]",
                                &maps[*nmaps].start,
                                &end,
                                prot,
                                maps[*nmaps].path);
                switch (sret) {
                        case 3: /* Anonymous mapping, don't care. */
                                (*nmaps)--;
                                continue;
                        case 4: /* Good. */
                                break;
                        default: /* Bad line. */
                                DWARNX("invalid maps line: %s", line);
                                ret = SREM_RET_EPARSEMAPS;
                                goto out;
                }
                /* Paths won't end in a newline, so if we don't have one it
                 * means we didn't have enough space for the path. */
                pathlen = strnlen(maps[*nmaps].path, PATH_MAX);
                if (0 == pathlen) {
                        DWARNX("maps line had empty path: %s", line);
                        ret = SREM_RET_EMPTYPATH;
                        goto out;
                } else if ('\n' != maps[*nmaps].path[pathlen-1]) {
                        DWARNX("maps line had path >%d bytes: %s", PATH_MAX,
                                        line);
                        ret = SREM_RET_BIGPATH;
                        goto out;
                }
                maps[*nmaps].path[pathlen-1] = '\0'; /* chomp */

                /* Parse the parts of the line we couldn't just read. */
                maps[*nmaps].prot =
                        (prot[0] == 'r' ? PROT_READ  : 0) |
                        (prot[1] == 'w' ? PROT_WRITE : 0) |
                        (prot[2] == 'x' ? PROT_EXEC  : 0) ;
                maps[*nmaps].length = end - maps[*nmaps].start;
                /* Left commented-out for future debugging. */
                /*
                DPRINTF("Found mapped file: start:%p len:0x%lx prot:0x%x "
                                "path:%s\n",
                                VOIDP(maps[*nmaps].start),
                                maps[*nmaps].length,
                                maps[*nmaps].prot,
                                maps[*nmaps].path);
                */
        }
        if (ferror(psm)) {
                saved_errno = errno;
                DWARN("getline (%s)", MAPS_FILE);
                ret = SREM_RET_ERRNO;
        }

out:
        if (NULL != line) {
                free(line);
                line = NULL;
        }
        if (NULL != psm) {
                fclose(psm);
                psm = NULL;
        }
        errno = saved_errno;
        return ret;
}

/* find_our_path finds the path of the current library which will be copied to
 * nmap.path. */
static int
find_our_path(struct map *maps, int nmaps, struct map *pmap)
{
        int       i;
        uintptr_t addr;

        /* We assume the address of this function is somewhere in one of the
         * pages mapped by the current library and use that to find out what
         * filepath is listed for that page. */
        addr = (uintptr_t)find_our_path;

        /* Search for that address. */
        bzero(pmap->path, sizeof(pmap->path));
        for (i = 0; i < nmaps; ++i) {
                if (maps[i].start <= addr && addr <=
                                (maps[i].start + maps[i].length)) {
                        /* Found it. */
                        strncpy(pmap->path, maps[i].path, sizeof(pmap->path));
                        break;
                }
        }
        if ('\0' == pmap->path[0]) { /* Didn't find it. */
                DWARNX("unable to find path to shared object");
                return SREM_RET_NOPATH;
        }

        return SREM_RET_OK;
}

/* filter_mapped_files removes elements of maps which don't have the given
 * path. */
static int
filter_mapped_files(struct map *maps, int *nmaps, char *path)
{
        int i, next;

        /* Filter down to just the ones with our file. */
        next = 0;
        for (i = 0; i < *nmaps; ++i) {
                /* Don't care if this isn't us. */
                if (0 != strcmp(maps[i].path, path))
                        continue;
                /* Found us.  Copy it to the next unused array element. */
                memmove(&maps[next], &maps[i], sizeof(maps[next]));
                DPRINTF("Map to hide: start:%p len:0x%lx prot:0x%x "
                                "path:%s\n",
                                VOIDP(maps[next].start),
                                maps[next].length,
                                maps[next].prot,
                                maps[next].path);
                /* Use the next one next time. */
                next++;
        }

        /* Update how many maps we care about. */
        *nmaps = next;
        DPRINTF("Found ourselves in %s in %d maps\n", path, *nmaps);

        return SREM_RET_OK;
}

/* overmap_files copies the nmaps maps from maps to another address, then
 * mremaps them back in place. */
static int
overmap_files(struct map *maps, int *nmaps)
{
        int   i;
        void *p;

        /* Remap ALL the maps! */
        for (i = 0; i < *nmaps; ++i) {
                DPRINTF("Remapping 0x%lx bytes for %p...", maps[i].length,
                                VOIDP(maps[i].start));

                /* Grab a chunk of memory. */
                if (MAP_FAILED == (p = mmap(NULL, maps[i].length, PROT_WRITE,
                                                MAP_PRIVATE|MAP_ANON,
                                                -1, 0)))
                        D_RET_ERRNO("mmap (0x%lx)", maps[i].length);

                /* Copy over this chunk, despite the name. */
                memmove(p, VOIDP(maps[i].start), maps[i].length);
                
                /* Set permissions to what they should be. */
                if (-1 == mprotect(p, maps[i].length, maps[i].prot))
                        D_RET_ERRNO("mprotect");

                /* Remap it back into place and release the old map. */
                if (MAP_FAILED == (mremap(p, maps[i].length, maps[i].length,
                                                MREMAP_MAYMOVE|MREMAP_FIXED,
                                                maps[i].start)))
                        D_RET_ERRNO("mremap (%p)", VOIDP(maps[i].start));
                if (-1 == munmap(p, maps[i].length))
                        D_RET_ERRNO("munmap (0x%lx)", maps[i].length);

                DPRINTF("ok :)\n");
        }

        return SREM_RET_OK;
}

