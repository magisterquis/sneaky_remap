# Makefile
# Build and use the C quickstart
# By J. Stuart McMurray
# Created 20250810
# Last Modified 20250810

# Quick library-loading example.
run: quickstart_c.so
	@echo "Loading the library and printing mapped files:";
	bash -c 'enable ./$>; cat /proc/$$$$/maps' 2>/dev/null |\
		awk '$$6{print $$6}' | sort -u;
	@echo "Note the lack of $> :)"
.PHONY: run

# Building the library is pretty trivial
quickstart_c.so: quickstart_c.c sneaky_remap.c sneaky_remap.h
	${CC} \
		--pedantic\
		-O2\
		-Wall\
		-Werror\
		-Wextra\
		-fPIC\
		-o $@\
		-shared\
		${>:M*.c}

sneaky_remap.c sneaky_remap.h: ../../$@
	cp $> $@

clean:
	rm -f quickstart_c.so sneaky_remap.c sneaky_remap.h
.PHONY: clean

