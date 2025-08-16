Quickstart (Go)
===============
This is the code behind the the main README's
[Go Quickstart](../README.md##quickstart-go).

It's a simple shared object file which prints the memory maps after
everything's hidden and then closes file descriptor 4 so bash doesn't exit
before Go's threads have time to catch up.

Running
-------
Be in this directory and run `bmake`.

The output should look like
```
go build -buildmode c-shared -o quickstart_go.so
bash -c 'exec 4<> <(:); enable ./quickstart_go.so; $(</dev/fd/4)'
bash: line 1: enable: cannot find ./quickstart_go.so_struct in shared object ./quickstart_go.so: ./quickstart_go.so: undefined symbol: ./quickstart_go.so_struct
bash: line 1: enable: ./quickstart_go.so: not a shell builtin
Post-Hiding Mapped Memory
-------------------------
4000000000-4000400000 rw-p 00000000 00:00 0
4000400000-4004000000 ---p 00000000 00:00 0
aaaada270000-aaaada3a7000 r-xp 00000000 fe:02 1047976                    /usr/bin/bash
aaaada3bb000-aaaada3c0000 r--p 0013b000 fe:02 1047976                    /usr/bin/bash
aaaada3c0000-aaaada3c9000 rw-p 00140000 fe:02 1047976                    /usr/bin/bash
aaaada3c9000-aaaada3d4000 rw-p 00000000 00:00 0
aaaaf3ea1000-aaaaf3ec2000 rw-p 00000000 00:00 0                          [heap]
ffff4c000000-ffff4c021000 rw-p 00000000 00:00 0
ffff4c021000-ffff50000000 ---p 00000000 00:00 0
...lots more anonymous memory...
ffffaefcb000-ffffaeff5000 rw-p 00000000 00:00 0
ffffaf000000-ffffaf2e9000 r--p 00000000 fe:02 1047387                    /usr/lib/locale/locale-archive
ffffaf2ef000-ffffaf340000 rw-p 00000000 00:00 0
ffffaf340000-ffffaf4c7000 r-xp 00000000 fe:02 1046547                    /usr/lib/aarch64-linux-gnu/libc.so.6
ffffaf4c7000-ffffaf4dc000 ---p 00187000 fe:02 1046547                    /usr/lib/aarch64-linux-gnu/libc.so.6
ffffaf4dc000-ffffaf4e0000 r--p 0018c000 fe:02 1046547                    /usr/lib/aarch64-linux-gnu/libc.so.6
ffffaf4e0000-ffffaf4e2000 rw-p 00190000 fe:02 1046547                    /usr/lib/aarch64-linux-gnu/libc.so.6
ffffaf4e2000-ffffaf4ef000 rw-p 00000000 00:00 0
ffffaf4f0000-ffffaf51c000 r-xp 00000000 fe:02 1049869                    /usr/lib/aarch64-linux-gnu/libtinfo.so.6.4
ffffaf51c000-ffffaf52c000 ---p 0002c000 fe:02 1049869                    /usr/lib/aarch64-linux-gnu/libtinfo.so.6.4
ffffaf52c000-ffffaf530000 r--p 0002c000 fe:02 1049869                    /usr/lib/aarch64-linux-gnu/libtinfo.so.6.4
ffffaf530000-ffffaf531000 rw-p 00030000 fe:02 1049869                    /usr/lib/aarch64-linux-gnu/libtinfo.so.6.4
ffffaf53b000-ffffaf562000 r-xp 00000000 fe:02 1046543                    /usr/lib/aarch64-linux-gnu/ld-linux-aarch64.so.1
ffffaf566000-ffffaf56d000 r--s 00000000 fe:02 1049474                    /usr/lib/aarch64-linux-gnu/gconv/gconv-modules.cache
ffffaf56d000-ffffaf56f000 rw-p 00000000 00:00 0
ffffaf574000-ffffaf576000 rw-p 00000000 00:00 0
ffffaf576000-ffffaf578000 r--p 00000000 00:00 0                          [vvar]
ffffaf578000-ffffaf579000 r-xp 00000000 00:00 0                          [vdso]
ffffaf579000-ffffaf57b000 r--p 0002e000 fe:02 1046543                    /usr/lib/aarch64-linux-gnu/ld-linux-aarch64.so.1
ffffaf57b000-ffffaf57d000 rw-p 00030000 fe:02 1046543                    /usr/lib/aarch64-linux-gnu/ld-linux-aarch64.so.1
ffffd3874000-ffffd3c7e000 rw-p 00000000 00:00 0                          [stack]
```
