package main

/*
 * lib.go
 * Importer for the sneaky_remap Go package
 * By J. Stuart McMurray
 * Created 20250730
 * Last Modified 20250730
 */

import (
	"C"
	"os"

	_ "go_get/pkg/sneaky_remap"
)

func init() {
	swrite("In init\n")
}

//export sowait
func sowait() int {
	swrite("In sowait\n")
	return 0
}

// swrite writes s to stdout and then sync's stdout.
func swrite(s string) {
	os.Stdout.Write([]byte(s))
	os.Stdout.Sync()
}

func main() {}
