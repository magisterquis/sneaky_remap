/*
 * sneaky_remap.h
 * Sneakily remap this shared object file to avoid being seen in /proc/pid/maps
 * By J. Stuart McMurray
 * Created 20250725
 * Last Modified 20250810
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
#define SREM_SRS_UNLINK (1<<2) /* unlink(2) ourselves. */

/* Unimplemented flags for sneaky_remap_start. */
#define SREM_SRS_RMELF  (1<<1) /* Clear \x7fELF from mapped ELF headers. */

/* Return values. */
#define SREM_RET_OK          0 /* All went well. */
#define SREM_RET_ERRNO       1 /* errno will be set, use warn(3)/err(3)/etc. */
#define SREM_RET_EPARSEMAPS  2 /* Error parsing /proc/self/maps. */
#define SREM_RET_TOOMANYMAPS 3 /* /proc/self/maps was too large. */
#define SREM_RET_NOPATH      4 /* Couldn't find our own file's path. */
#define SREM_RET_EDLOPEN     5 /* Couldn't dlopen ourselves. */
#define SREM_RET_EMPTYPATH   6 /* Our own path was empty. */
#define SREM_RET_BIGPATH     7 /* A path in /proc/self/maps was too long. */

/*
 * Additionally, the following macro may be set at compile-time:
 *
 * SREM_DEBUG - Enable debug messages.
 */

__BEGIN_DECLS

/*
 * sneaky_remap_start shuffles memory around to remove this shared object
 * file's path from /proc/self/maps and the like.
 *
 * If start_routine isn't NULL, it is started in its own detached thread via
 * pthread_create(3).
 *
 * The flags specified are a bitwise OR of the SREM_SRS_* values.
 */
int sneaky_remap_start(void *(start_routine)(void *), void *arg, int flags);

__END_DECLS

#endif /* #ifndef HAVE_SNEAKY_REMAP_H */
