# Makefile
# Build a very simple self-hiding Go library, without go get
# By J. Stuart McMurray
# Created 20250730
# Last Modified 20250816

lib.so: lib.go sneaky_remap.c sneaky_remap.h
	@# This should be there, but we don't really want it.
	@rm sneaky_remap.go
	go build -buildmode=c-shared -o $@

# Nothing to clean
clean:
.PHONY: clean
