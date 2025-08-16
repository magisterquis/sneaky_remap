CGO Compile-time Config
=======================
Examples of using the `SREM_CGO_*` macros to configure `sneaky_remap_start` at
compile-time.

The `CGO_FLAGS` in the [`Makefile`](./Makefile) set the configuration, and 
the `cgo_compile_time_config.so` target uses them.`

Running
-------
Be in this directory and run `bmake`.

The output should look like
```
CGO_CFLAGS=-DSREM_CGO_START_FLAGS=SREM_SRS_UNLINK\ -DSREM_CGO_START_ROUTINE=HelloAndCloseFour\ -DSREM_DEBUG go build -buildmode c-shared -o cgo_compile_time_config.so
bash -c 'exec 2>&1; echo Before loading: $(ls -l cgo_compile_time_config.so); exec 4<> <(:); enable ./cgo_compile_time_config.so; $(</dev/fd/4); echo After loading: $(ls -l cgo_compile_time_config.so); echo Done.'
Before loading: -rw-r--r-- 1 stuart stuart 2457336 Aug 16 20:09 cgo_compile_time_config.so
Map to hide: start:0xffffbd400000 len:0xf4000 prot:0x5 path:/home/stuart/b/examples/cgo_compile_time_config/cgo_compile_time_config.so
Map to hide: start:0xffffbd4f4000 len:0x19000 prot:0x0 path:/home/stuart/b/examples/cgo_compile_time_config/cgo_compile_time_config.so
Map to hide: start:0xffffbd50d000 len:0xa3000 prot:0x1 path:/home/stuart/b/examples/cgo_compile_time_config/cgo_compile_time_config.so
Map to hide: start:0xffffbd5b0000 len:0xb000 prot:0x3 path:/home/stuart/b/examples/cgo_compile_time_config/cgo_compile_time_config.so
Found ourselves in /home/stuart/b/examples/cgo_compile_time_config/cgo_compile_time_config.so in 4 maps
Remapping 0xf4000 bytes for 0xffffbd400000...ok :)
Remapping 0x19000 bytes for 0xffffbd4f4000...ok :)
Remapping 0xa3000 bytes for 0xffffbd50d000...ok :)
Remapping 0xb000 bytes for 0xffffbd5b0000...ok :)
unlink success (/home/stuart/b/examples/cgo_compile_time_config/cgo_compile_time_config.so)
Invisibility cloak active!!!
bash: line 1: enable: cannot find ./cgo_compile_time_config.so_struct in shared object ./cgo_compile_time_config.so: ./cgo_compile_time_config.so: undefined symbol: ./cgo_compile_time_config.so_struct
bash: line 1: enable: ./cgo_compile_time_config.so: not a shell builtin
2025/08/16 20:09:33 Hello, World!
ls: cannot access 'cgo_compile_time_config.so': No such file or directory
After loading:
Done.
```
