/*
 * sneaky_remap.h
 * Sneakily remap this shared object file to avoid being seen in /proc/pid/maps
 * By J. Stuart McMurray
 * Created 20250725
 * Last Modified 20250730
 */

#ifndef HAVE_SNEAKY_REMAP_H
#define HAVE_SNEAKY_REMAP_H

/* SREM_MAX_MAPS is the maximum number of memory maps we read from
 * /proc/self/maps.  It may be increased if SREM_RET_TOOMANYMAPS is
 * returned. */
#ifndef SREM_MAX_MAPS
#define SREM_MAX_MAPS 1024
#endif /* #ifndef SREM_MAX_MAPS */

/* Flags for sneaky_remap_start. */
#define SREM_SRS_DLOPEN (1<<0) /* dlopen(3) ourselves. */
#define SREM_SRS_UNLINK (1<<1) /* unlink(2) ourselves. */

/* Return values. */
#define SREM_RET_OK          0 /* All went well. */
#define SREM_RET_ERRNO       1 /* errno will be set, user warn/err/etc. */
#define SREM_RET_EPARSEMAPS  2 /* Error parsing /proc/self/maps. */
#define SREM_RET_TOOMANYMAPS 3 /* /proc/self/maps was too large. */
#define SREM_RET_NOPATH      4 /* Couldn't find our own file's path. */
#define SREM_RET_EDLOPEN     5 /* Couldn't dlopen ourselves. */
#define SREM_RET_EMPTYPATH   6 /* Our own path was empty. */
#define SREM_RET_BIGPATH     7 /* A path in /proc/self/maps was too long. */

/* sneaky_remap_start shuffles memory around to remove this shared object
 * file's path from /proc/self/maps and then starts start_routine in its own
 * thread. */
int sneaky_remap_start(void *(start_routine)(void *), void *arg, int flags);

#endif /* #ifndef HAVE_SNEAKY_REMAP_H */
