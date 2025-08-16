# Makefile
# Build sneaky_remap
# By J. Stuart McMurray
# Created 20250725
# Last Modified 20250804

BINNAME       != basename $$(pwd)
MAKEDIRS      != find * -mindepth 1 -name Makefile -exec dirname {} \;
GOBUILDFLAGS   = -trimpath -ldflags "-w -s"
GOTESTFLAGS   += -timeout 3s
SHMORESUBR     = t/shmore.subr
SHMOREURL      = https://raw.githubusercontent.com/magisterquis/shmore/refs/heads/master/shmore.subr

test: gotest provetest ## Run ALL the tests (default)
.PHONY: test

gotest: ## Run go-specific tests
	go test ${GOBUILDFLAGS} ${GOTESTFLAGS} ./...
	go vet ${GOBUILDFLAGS} ./...
	staticcheck ./...
.PHONY: gotest

provetest: ## Run tests with prove(1)
	prove -It --directives t/ examples/*/t
.PHONY: provetest

update: ## Fetch the latest Shmore and up-to-date Go things
	curl\
		--fail\
		--show-error\
		--silent\
		--output ${SHMORESUBR}.new\
		${SHMOREURL}
	diff -q ${SHMORESUBR} ${SHMORESUBR}.new >/dev/null &&\
		rm ${SHMORESUBR}.new ||\
		mv ${SHMORESUBR}.new ${SHMORESUBR}
	go get -t -u go ./...
	go mod tidy
.PHONY: update

help: .NOTMAIN ## This help
	@perl -ne '/^(\S+?):+.*?##\s*(.*)/&&print"$$1\t-\t$$2\n"' \
		${MAKEFILE_LIST} | column -ts "$$(printf "\t")"
.PHONY: help

clean:
.for MD in ${MAKEDIRS}
	${MAKE} -C ${MD} clean
.endfor
