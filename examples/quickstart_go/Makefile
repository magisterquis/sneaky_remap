# Makefile
# Build and use the Go quickstart
# By J. Stuart McMurray
# Created 20250810
# Last Modified 20250810

# Quick library-loading example.
run: quickstart_go.so
	bash -c 'exec 4<> <(:); enable ./$>; $$(</dev/fd/4)'
.PHONY: run

# Building the library is pretty trivial
quickstart_go.so: quickstart_go.go maps.go
	go build -buildmode c-shared -o $@

clean:
	rm -f *.c *.so *.h
.PHONY: clean
