package main

/*
 * maps.go
 * Dump the memory maps
 * By J. Stuart McMurray
 * Created 20250810
 * Last Modified 20250811
 */

import (
	"fmt"
	"log"
	"os"

	_ "github.com/magisterquis/sneaky_remap_preview"
)

// init copies /proc/self/maps to stdout.
func init() {
	b, err := os.ReadFile("/proc/self/maps")
	if nil != err {
		log.Fatalf("Error reading /proc/self/maps: %s", err)
		return
	}
	fmt.Printf("Post-Hiding Mapped Memory\n")
	fmt.Printf("-------------------------\n")
	if _, err := os.Stdout.Write(b); nil != err {
		log.Fatalf("Error writing to stdout: %s", err)
		return
	}

	os.NewFile(4, "fd4").Close()
}
