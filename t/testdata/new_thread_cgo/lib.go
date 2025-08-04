package main

/*
 * lib.go
 * Note a thread is running.
 * By J. Stuart McMurray
 * Created 20250730
 * Last Modified 20250730
 */

import (
	"C"
	"context"
	_ "new_thread_cgo/pkg/sneaky_remap"
	"os"
	"sync"
	"unsafe"
)

var (
	wg     sync.WaitGroup
	ctx    context.Context
	cancel func()
)

// init adds one to wg and sets up ctx and cancel.
func init() {
	wg.Add(1)
	ctx, cancel = context.WithCancel(context.Background())
	swrite("In init\n")
}

// sowait cancels the context and blocks until wg is done.
//
//export sowait
func sowait() int {
	cancel()
	wg.Wait()
	swrite("Thread finished\n")
	return 0
}

// doit waits for the context to come done and then decrements wg.
//
//export doit
func doit(unsafe.Pointer) unsafe.Pointer {
	defer wg.Done()
	<-ctx.Done()
	swrite("Context done\n")
	return nil
}

// swrite writes s to stdout and then sync's stdout.
func swrite(s string) {
	os.Stdout.Write([]byte(s))
	os.Stdout.Sync()
}

func main() {}
