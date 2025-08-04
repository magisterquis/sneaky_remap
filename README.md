`sneaky_remap`
==============
Sneakily remap an injected shared object file to hide in `/proc/pid/maps` on
Linux.

For Go usage, see https://pkg.go.dev/github.com/magisterquis/sneaky_remap and
[`sneaky_remap.go`](./sneaky_remap.go).

For legal use only.

Quickstart (C)
--------------
1. Copy [`sneaky_remap.c`](./sneaky_remap.c) and
   [`sneaky_remap.h`](./sneaky_remap.h) somewhere where they'll be built.
2. Call `sneaky_remap_start` before multiple threads will do anything with the
   loaded library.  A constructor is an excellent place.  Something like the
   following should do it:
   ```c
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
   ```
3. Test thoroughly.  Make sure to look at `/proc/pid/maps` before and after
   loading.

Theory
------
1. Libraries loaded with `dlopen(3)` are visible as mapped memory in
   `/proc/self/maps`.  This isn't great for stealth.
2. We copy the pages from our library's file to new anonymous pages, keeping
   the same permissions.
3. Very quickly, we atomically `mremap(2)` the copies back over the pages from
   the shared object file, unmapping the file in the process.
3. Our library now shows up as anonymous memory in `/proc/pid/maps`.

### Caveats
1. If other threads are running, all of this is a bit dicey.
2. The library is still visible for a short amount of time; if anything's
   watching calls to `open(2)` or `mmap(2)` they'll see us, though we may well
   win a race between being noticed and forensic data being collected.
3. The mapped pages still have the ELF magic number in the beginning.  This may
   be fixable with an as-yet unimplemented `SREM_SRS_RMELF`.

API
---
The API consists of one function and a handful of preprocessor macros.

### The Function
```c
int
sneaky_remap_start(
    void *(start_routine)(void *),
    void *arg,
    int flags
)
```
Works a bit like `pthread_create(3)`, but before doing anything else it does
the memory-hidey trick described in the [Theory section](#Theory).

After all of the hiding happens, if not `NULL`, `start_routine` is started in a
detached thread.

Returns one of the `SREM_RET_*` constants in
[`sneaky_remap.h`](./sneaky_remap.h).  Of note, if `SREM_RET_ERRNO` is
returned, `errno` may be used to determine the underlying error.

#### Arguments
1. `start_routine` and `arg`- Passed to `pthread_create(3)`.
2. `flags` - One of the [`SREM_SRS_* Constants`](#SREM_SRS_-Constants).

### `SREM_SRS_*` Constants
- `SREM_SRS_DLOPEN` - Calls `dlopen(3)` on the library with `RTLD_NOW` to
  prevent unwanted unloads (e.g. when using Bash's `enable`).
- `SREM_SRS_UNLINK` - `unlink(2)`s the shared object file after hiding it.

### `SREM_DEBUG`
If defined, debug messages are printed to stderr, especially helpful during
development.

When not defined, the debug strings are not present in the compiled object code
for a bit less fingerprintability.

Testing
-------
Have a look in [`t/`](./t/) and [`examples/`](./examples/) for ideas for
testing libraries which use `sneaky_remap`.

Testing `sneaky_remap` itself requires quite a few dependencies:
- bmake
  - ...because I still haven't learned how to GNU Make
- cc
- go
- ksh
- prove
- staticcheck

They can often be installed with one of the below:
```sh
apt install ...
yum install ...
```

Run `bmake` to start the tests.  They'll probably take quite a bit of time to
run the first time.
