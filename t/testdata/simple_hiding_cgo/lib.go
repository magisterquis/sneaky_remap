package main

/*
 * lib.go
 * Importer for the sneaky_remap Go package
 * By J. Stuart McMurray
 * Created 20250730
 * Last Modified 20250730
 */

import (
	"os"
)

import "C"

func init() {
	swrite("In init\n")
}

//export sowait
func sowait() {
	swrite("In sowait\n")
}

// swrite writes s to stdout and then sync's stdout.
func swrite(s string) {
	os.Stdout.Write([]byte(s))
	os.Stdout.Sync()
}

func main() {}
