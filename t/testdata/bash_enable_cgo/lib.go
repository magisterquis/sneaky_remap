package main

/*
 * lib.go
 * Update a file every tenth-second
 * By J. Stuart McMurray
 * Created 20250730
 * Last Modified 20250730
 */

import (
	"log"
	"os"
	"strconv"
	"time"

	_ "bash_enable_cgo/pkg/sneaky_remap"
)

const (
	counterFile     = "counter"
	counterFileTmp  = "counter.tmp"
	counterInterval = time.Second / 10
)

// init kicks off doit.
func init() { go doit() }

// doit writes a counter to counterFile at counterInterval intervals.
// The file is created and then moved into place, to avoid partial reads.
func doit() {
	counter := 0
	for {
		counter++
		/* Make a temporary counter file. */
		if err := os.WriteFile(
			counterFileTmp,
			[]byte(strconv.Itoa(counter)),
			0600,
		); nil != err {
			log.Fatalf(
				"Error writing counter %d to %s: %s",
				counter,
				counterFileTmp,
				err,
			)
		}
		/* Atomic move it over the old one. */
		if err := os.Rename(counterFileTmp, counterFile); nil != err {
			log.Fatalf(
				"Error renaming %s to %s: %s",
				counterFileTmp,
				counterFile,
				err,
			)
		}
		/* Wait a bit. */
		time.Sleep(counterInterval)
	}
}

func main() {}
