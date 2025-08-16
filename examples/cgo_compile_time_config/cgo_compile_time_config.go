// Program cgo_compile_time_config demonstrates use of the SREM_CGO_* macros.
package main

/*
 * cgo_compile_time_config.go
 * Use the SREM_CGO_* macros
 * By J. Stuart McMurray
 * Created 20250811
 * Last Modified 20250811
 */

import (
	"C"
	"log"
	"os"

	_ "github.com/magisterquis/sneaky_remap_preview"
)

//export HelloAndCloseFour
func HelloAndCloseFour() {
	log.Printf("Hello, World!")
	os.NewFile(4, "fd4").Close()
}

func main() {}
