`sneaky_remap`
==============
Sneakily hide the name of a loaded shared object file (library) on Linux, with
a minimum of fuss.
Code works with [C](#quickstart-c), [Go](#quickstart-go), and likely any other
C-friendly language.

The general idea is the library to be hidden links in code from this
repository, calls [`sneaky_remap_start`](#the-function) shortly after being
loaded or injected, and anything nosing about `/proc/pid` has a bit of extra
difficulty working out what's going on.

Removes the filename from...
- `/proc/pid/map_files`
- `/proc/pid/maps`
- `/proc/pid/numa_maps`
- `/proc/pid/smaps`

Please also see the [Theory](#theory) section for details about how it works
under the hood,
copy/paste-friendly [examples](./examples),
and
https://pkg.go.dev/github.com/magisterquis/sneaky_remap and
[`sneaky_remap.go`](./sneaky_remap.go) for idiomatic(er) Go usage.

For legal use only.

Quickstart (C)
--------------
1. Copy [`sneaky_remap.c`](./sneaky_remap.c) and
   [`sneaky_remap.h`](./sneaky_remap.h) somewhere where they'll be built into
   the library to hide.
2. Call [`sneaky_remap_start`](#the-function) before any thread will do
   anything with the loaded library.
   Something along the lines the following should do it:
   ```c
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
   ```
3. Test thoroughly.
   Make sure to look at `/proc/pid/maps` and friends before and after the
   library is loaded.

Quickstart (Go)
---------------
1. Import [`github.com/magisterquis/sneaky_remap`](https://pkg.go.dev/github.com/magisterquis/sneaky_remap).
   ```go
   package main

   import (
   	_ "github.com/magisterquis/sneaky_remap_preview"
   )

   func main() {}
   ```
2. Test thoroughly.
   Make sure to look at `/proc/pid/maps` and friends before and after the
   library is loaded.

Theory
------
1. Libraries loaded with `dlopen(3)` are visible as mapped memory in
   `/proc/self/maps`.  This isn't great for stealth.  Looks like this:
   ```
   7dfeee7c5000-7dfeee7c6000 r--p 00000000 00:2c 146314                     /tmp/tmp.govmrv0jiG/readme_theory.so
   7dfeee7c6000-7dfeee7c7000 r-xp 00001000 00:2c 146314                     /tmp/tmp.govmrv0jiG/readme_theory.so
   7dfeee7c7000-7dfeee7c8000 r--p 00002000 00:2c 146314                     /tmp/tmp.govmrv0jiG/readme_theory.so
   7dfeee7c8000-7dfeee7c9000 r--p 00002000 00:2c 146314                     /tmp/tmp.govmrv0jiG/readme_theory.so
   7dfeee7c9000-7dfeee7ca000 rw-p 00003000 00:2c 146314                     /tmp/tmp.govmrv0jiG/readme_theory.so
   ```
2. We copy the readable pages from our library's file to new anonymous pages,
   keeping the same permissions.
   Each new range ends up with the same contents and permissions, but at a
   different address:
   ```
   7dfeee7c1000-7dfeee7c5000 rw-p 00000000 00:00 0
   ```
3. Very quickly, we `mremap(2)` the each copy back over the relevant pages from
   the shared object file, unmapping the file in the process.  Lather, rinse,
   repeat for every mapped range.
   ```c
   if (MAP_FAILED == (mremap(p, map->length, map->length,
                                   MREMAP_FIXED|MREMAP_MAYMOVE,
                                   map->start)))
           D_RET_ERRNO("mremap (%p)", VOIDP(map->start));
   ```
3. Our library now shows up as anonymous memory in `/proc/pid/maps`:
   ```
   ffffab430000-ffffab432000 r-xp 00000000 00:00 0
   ffffab432000-ffffab44f000 ---p 00000000 00:00 0
   ffffab44f000-ffffab450000 r--p 00000000 00:00 0
   ffffab450000-ffffab451000 rw-p 00000000 00:00 0
   ```
Caveats
-------
1. If other threads are running, all of this is a bit dicey.
2. The library is still visible for a short amount of time; if anything's
   watching calls to `open(2)` or `mmap(2)` they'll see us, though we may well
   win a race between being noticed and forensic data being collected.
3. When linked into a shared object file written in Go,
   [`sneaky_remap_start`](#the-function) must be called before the Go runtime
   starts.
   The easy way to do this is to use a constructor function with a lowish
   priority, e.g.
   ```c
   static void __attribute__((constructor (5000)))
   ctor(void)
   {
           /* Call sneaky_remap_start */
   }
   ```
   The [Go package](https://pkg.go.dev/github.com/magisterquis/sneaky_remap)
   does this for you.
4. Pages which were unreadable when the library was loaded (as happens on
   aarch64), will no longer cause a SIGBUS when read after hiding.

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

After all of the hiding happens, if `start_routine` is not `NULL`, it is
started in a detached thread.

[`sneaky_remap_start`](#the-function) returns one of the `SREM_RET_*` constants
in [`sneaky_remap.h`](./sneaky_remap.h).  Of note, if `SREM_RET_ERRNO` is
returned, `errno` may be used to determine the underlying error.

#### Arguments
1. `start_routine` and `arg`- Passed to `pthread_create(3)`.
2. `flags` - A bitwise OR of the following constants, defined in
   [`sneaky_remap.h`](./sneaky_remap.h).
    - `SREM_SRS_DLOPEN` - Calls `dlopen(3)` on the library with `RTLD_NODELETE`
      to prevent unwanted unloads (e.g. when using Bash's `enable`).
    - `SREM_SRS_RMELF`  - Zeros out the four-byte ELF magic at the start of
      the mapped library.
    - `SREM_SRS_UNLINK` - `unlink(2)`s the shared object file after hiding it.

#### Return Values
[`sneaky_remap_start`](#the-function) may return the following values, defined
in [`sneaky_remap.h`](./sneaky_remap.h).
Value                  | Description
-----------------------|------------
`SREM_RET_OK`          | All went well.
`SREM_RET_ERRNO`       | `errno` will be set, use `warn(3)`/`err(3)`/etc.
`SREM_RET_EPARSEMAPS`  | Error parsing `/proc/self/maps`.
`SREM_RET_TOOMANYMAPS` | `/proc/self/maps` was too large.
`SREM_RET_NOPATH`      | Couldn't find our own file's path.
`SREM_RET_EDLOPEN`     | Couldn't dlopen ourselves.
`SREM_RET_EMPTYPATH`   | Our own path was empty.
`SREM_RET_BIGPATH`     | A path in `/proc/self/maps` was too long.


### Compile-time configuration (C)
The following macros may be set at compile-time.

#### `SREM_DEBUG`
If defined, debug messages are printed to stderr, especially helpful during
development.

When not defined, the debug strings are not present in the compiled object code
for a bit less fingerprintability.

#### `SREM_MAX_MAPS`
The maximum number of file-backed memory mappings inspected in
`/proc/pid/maps`.
Increase this if [`sneaky_remap_start`](#the-function) returns
`SREM_RET_TOOMANYMAPS`.

### Compile-time configuration (Go)
When using
[`github.com/magisterquis/sneaky_remap`](https://pkg.go.dev/github.com/magisterquis/sneaky_remap)
in a Go library compile-time configuration requires another layer of
indirection and takes the form of setting the following with the `CGO_CFLAGS`
environment variable.

An example can be found in
[`examples/cgo_compile_time_config`](./examples/cgo_compile_time_config).
all of the above [C compile-time

#### `SREM_CGO_START_ROUTINE`
The name of a function to pass via [`sneaky_remap_start`](#the-function)'s
`start_routine` argument.  The `void *arg` argument is always nil.  Defaults
to `NULL`.

#### `SREM_CGO_START_FLAGS`
Flags passed via [`sneaky_remap_start`](#the-function)'s `flags` argument.
Defaults to `0`.

Testing
-------
Have a look in [`t/`](./t/) and [`examples/`](./examples/) for ideas for
testing libraries which use `sneaky_remap`.

While using `sneaky_remap` is as simple as adding a line to a Go `import` block
or adding a couple of files to a C project, testing `sneaky_remap` itself is
a bit more involved, but more or less boils down to making sure the right
dependencies are in place, running `bmake`, and going for a cup of tea.  It's
less slow the second time after Go caches things.

The dependencies:
- [bmake](https://www.crufty.net/help/sjg/bmake.html)
  (because I still haven't learned how to GNU Make)
- A C compiler
  ([`gcc`](https://gcc.gnu.org)/[`clang`](https://clang.llvm.org)/etc.)
- [Go](https://go.dev)
- [ksh](https://man.openbsd.org/ksh)
  ([ksh93](https://github.com/ksh93/ksh) is fine)
- [prove](https://perldoc.perl.org/prove)
- [Staticcheck](https://staticcheck.dev)

Most of the above can often be installed with one of the below
```sh
# Debianish Linux distributions
apt install bmake build-essential git ksh
# RedHatish Linux distributions
yum -y group install development-tools && yum -y install bmake perl ksh
```
Go can usually be installed via the package manager as well, but is sometimes
quite out of date.  YMMV.

Once Go is intalled, staticcheck can be installed with
```sh
go install honnef.co/go/tools/cmd/staticcheck@latest
```


Run `bmake` to start the tests.  They'll probably take quite a bit of time to
run the first time.
