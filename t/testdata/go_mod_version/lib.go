package main

/*
 * lib.go
 * Tester of sneaky_remap's version number's okayness
 * By J. Stuart McMurray
 * Created 20251005
 * Last Modified 20251005
 */

import (
	"C"
	"os"

	_ "go_mod_version/pkg/sneaky_remap"
)

//export sowait
func sowait() {
	os.Stdout.Write([]byte("In sowait\n"))
	os.Stdout.Sync()
}

func main() {}
