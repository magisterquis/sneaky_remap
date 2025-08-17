# Makefile
# Build and inject a CGO library
# By J. Stuart McMurray
# Created 20250811
# Last Modified 20250816

# Compile-time configuration.
CGO_CFLAGS = -DSREM_CGO_START_FLAGS=SREM_SRS_UNLINK\
	     -DSREM_CGO_START_ROUTINE=HelloAndCloseFour\
	     -DSREM_DEBUG

# The library we'll configure with CGO_FLAGS
LIB=cgo_compile_time_config.so

# Quick library-building example.  We redirect stderr to attempt to prevent
# interleaved output.
run: ${LIB}
	bash -c 'exec 2>&1;\
		echo Before loading: $$(ls -l $>);\
		exec 4<> <(:); enable ./$>; $$(</dev/fd/4);\
		echo After loading: $$(ls -l $>);\
		echo Done.'
.PHONY: run

# Building the library is pretty not hard, though passing CFLAGS is a bit odd.
${LIB}: cgo_compile_time_config.go
	CGO_CFLAGS=${CGO_CFLAGS:Q} go build -buildmode c-shared -o $@

clean:
	rm -f ${LIB} cgo_compile_time_config.h
.PHONY: clean

