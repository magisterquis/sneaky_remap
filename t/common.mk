# common.mk
# Variables and such common to all test makefiles
# By J. Stuart McMurray
# Created 20250728
# Last Modified 20251018

# Of course...
.if "-g" == ${CFLAGS}
CFLAGS=
.endif

SRPKG   =pkg/sneaky_remap
CFLAGS +=--pedantic -O2 -Wall -Werror -Wextra -fPIC -ggdb

.if exists(lib.go) # Building a Go library

# Turns sneaky_remap into a package
${SRPKG}/sneaky_remap.{c,h,go}:
.if ! exists(${SRPKG})
	mkdir -p ${@D}/
.endif
	mv ${@F} $@

lib.so: go.mod lib.go ${SRPKG}/sneaky_remap.{c,h,go}
	go vet ./...
	go test ./...
	staticcheck ./...
	go build -buildmode=c-shared -o $@


.else # Building a C library

lib.so: lib.c sneaky_remap.c
	${CC} ${CFLAGS} -fPIC -shared -o $@ $>
.endif
