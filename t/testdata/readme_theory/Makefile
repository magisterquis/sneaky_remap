# Makefile
# Build the README Theory section example
# By J. Stuart McMurray
# Created 20250809
# Last Modified 20250809

COMPILE=${CC} --pedantic -O2 -Wall -Werror -Wextra -fPIC

ALL=maps_before_and_after readme_theory.so

all: ${ALL}
.PHONY: all

maps_before_and_after: maps_before_and_after.c
	${COMPILE} -o $@ $>

readme_theory.so: readme_theory.c sneaky_remap_plus_during.c sneaky_remap.h
	${COMPILE} -shared -o $@ ${>:M*.c}

sneaky_remap_plus_during.c: sneaky_remap.c plus_during.patch
	patch -o $@ ${>:N*.patch} ${>:M*.patch}

clean:
	rm -f ${ALL}
.PHONY: clean
