# Makefile
# Build the test loader
# By J. Stuart McMurray
# Created 20250728
# Last Modified 20250816

.include "../../common.mk"

TEST_LOADER=test_loader

${TEST_LOADER}: test_loader.c
	${CC} ${CFLAGS} -o $@ ${>:M*c}

clean:
	rm -f ${TEST_LOADER}
