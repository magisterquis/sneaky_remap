# common.mk
# Variables and such common to all test makefiles
# By J. Stuart McMurray
# Created 20250728
# Last Modified 20250730

# Of course...
.if "-g" == ${CFLAGS}
CFLAGS=
.endif

SRPKG   =pkg/sneaky_remap
CFLAGS +=--pedantic -O2 -Wall -Werror -Wextra -fPIC -ggdb

.if exists(lib.go) # Building a Go library

# If we haven't yet, turn sneaky_remap into a package
.BEGIN:
.if ! exists(${SRPKG})
	mkdir -p ${SRPKG}/
.endif
.for FN in sneaky_remap.c sneaky_remap.h sneaky_remap.go
.if exists(./${FN})
	mv ${FN} ${SRPKG}/
.endif
.endfor

lib.so: lib.go ${SRPKG}/sneaky_remap.{c,h,go}
	go vet ./...
	go test ./...
	staticcheck ./...
	go build -buildmode=c-shared -o $@


.else # Building a C library

lib.so: lib.c sneaky_remap.c
	${CC} ${CFLAGS} -fPIC -shared -o $@ $>
.endif
