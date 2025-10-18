Quickstart (C)
===============
This is the code behind the the main README's
[C Quickstart](../README.md##quickstart-c).

It's a simple shared object file which prints the memory maps after
everything's hidden and then closes file descriptor 4 so bash doesn't exit
before C's threads have time to catch up.

Running
-------
Be in this directory and run `bmake`.

The output should look like
```
cp ../../sneaky_remap.c sneaky_remap.c
cp ../../sneaky_remap.h sneaky_remap.h
cc -pipe  --pedantic -O2 -Wall -Werror -Wextra -fPIC -o quickstart_c.so -shared quickstart_c.c sneaky_remap.c
Loading the library and printing mapped files:
bash -c 'enable ./quickstart_c.so; cat /proc/$$/maps' 2>/dev/null | awk '$6{print $6}' | sort -u;
[heap]
[stack]
/usr/bin/cat
/usr/lib/aarch64-linux-gnu/ld-linux-aarch64.so.1
/usr/lib/aarch64-linux-gnu/libc.so.6
/usr/lib/locale/locale-archive
[vdso]
[vvar]
Note the lack of quickstart_c.so :)
```
