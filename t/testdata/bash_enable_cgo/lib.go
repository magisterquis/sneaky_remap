package main

/*
 * lib.go
 * Update a file every tenth-second
 * By J. Stuart McMurray
 * Created 20250730
 * Last Modified 20250816
 */

import (
	"fmt"
	"log"
	"os"
	"syscall"
	"time"

	_ "bash_enable_cgo/pkg/sneaky_remap"
)

const (
	doneFD          = 5
	msgVar          = "MSG"
	readyFD         = 4
	counterFile     = "counter"
	counterFileTmp  = "counter.tmp"
	counterInterval = time.Second / 10
	counterMax      = 10
)

// init kicks off doit.
func init() { go doit() }

// doit closes a file descriptor readyFD, writes a couple of times to
// counterFile, and then closes doneFD before returning.
func doit() {
	if err := syscall.Close(readyFD); nil != err {
		log.Fatalf("Error closing FD %d: %s", readyFD, err)
	}
	defer func() {
		if err := syscall.Close(doneFD); nil != err {
			log.Fatalf("Error closing FD %d: %s", doneFD, err)
		}
	}()

	for i := 0; i < counterMax; i++ {
		/* Make a temporary counter file. */
		if err := os.WriteFile(
			counterFileTmp,
			[]byte(fmt.Sprintf("%s %d\n", os.Getenv(msgVar), i)),
			0600,
		); nil != err {
			log.Fatalf(
				"Error writing counter %d to %s: %s",
				i,
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
