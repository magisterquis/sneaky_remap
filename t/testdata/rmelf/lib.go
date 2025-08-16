package main

/*
 * lib.go
 * See if we've correctly hidden ourselves
 * By J. Stuart McMurray
 * Created 20250730
 * Last Modified 20250730
 */

import (
	"bufio"
	"debug/elf"
	"fmt"
	"log"
	"os"
	"regexp"
	"slices"
	"strconv"

	_ "rmelf/pkg/sneaky_remap"
)

// #include <stdlib.h>
//
// /* ctor saves a copy of our maps after we're loaded but before we're
//  * hidden. */
// static void __attribute__((constructor (1000)))
// ctor(void)
// {
//         system("cat </proc/$PPID/maps >maps_during");
// }
import "C"

const (
	mapsBefore = "maps_before"
	mapsDuring = "maps_during"

	/* Device and inode numbe indicating a line's not a file. */
	nonFile = "00:00 0"
)

// mapRE extracts the range start, file offset, file device and inode number,
// and filename from a line in /proc/pid/maps.
var mapRE = regexp.MustCompile(
	`^([[:xdigit:]]+)-[[:xdigit:]]+ [r-][w-][x-][p-] ([[:xdigit:]]+) ` +
		`([[:xdigit:]]{2}:[[:xdigit:]]{2} \d+)\s*(\S.*)?`,
)

// Init finds the mapped regions from this library, based on maps_before and
// maps_with_unhidden_library, then checks if the maps starting at the
// beginning of the library don't have ELF headers.
func init() {
	/* Get the list of offsets from before and right after the library
	was loaded, but not after hiding. */
	before := fileMaps(mapsBefore)
	during := fileMaps(mapsDuring)
	/* Work out the new ones.  That's our library. */
	toCheck := slices.DeleteFunc(during, func(a int64) bool {
		/* O(n**2), but for a very small n. */
		return slices.Contains(before, a)
	})
	if 0 == len(toCheck) {
		fatalf(34, "Did not find our library")
	}

	/* See if the ELF header's in any of the mappings. */
	mem, err := os.Open("/proc/self/mem")
	if nil != err {
		fatalf(35, "Error opening /proc/self/mem: %s", err)
	}
	defer mem.Close()
	b := make([]byte, len(elf.ELFMAG))
	for _, a := range toCheck {
		if _, err := mem.ReadAt(b, a); nil != err {
			fatalf(35, "Error reading memory at 0x%x: %s", a, err)
		}
		if string(b) == elf.ELFMAG {
			fmt.Printf("Found an ELF header\n")
			return
		}
	}
	fmt.Printf("Found no ELF headers\n")
}

//export sowait
func sowait() int { return 0 }

// swrite writes s to stdout and then sync's stdout.
func swrite(s string) {
	os.Stdout.Write([]byte(s))
	os.Stdout.Sync()
}

// fatalf is like log.Fatalf but exits the program with the given status.
func fatalf(ret int, msg string, args ...any) {
	log.Printf(msg, args...)
	os.Exit(ret)
}

// fileMaps gets the memory addresses in fn which come from the start of
// a file.  The program is terminated on error.
func fileMaps(fn string) []int64 {
	ret := make([]int64, 0)
	/* Get the file, line-by-line. */
	f, err := os.Open(fn)
	if nil != err {
		fatalf(30, "Opening %s: %s", fn, err)
	}
	defer f.Close()
	scanner := bufio.NewScanner(f)
	for scanner.Scan() {
		line := scanner.Text()
		/* Extract the interesting bits. */
		ms := mapRE.FindStringSubmatch(line)
		if 5 != len(ms) {
			fatalf(31, "Invalid line: %q (%q)", line, ms)
		}
		/* Skip named anonymous parts. */
		if nonFile == ms[3] {
			continue
		}
		/* Skip offsets not zero. */
		if off, err := strconv.ParseUint(ms[2], 16, 0); nil != err {
			fatalf(
				32,
				"Invalid file offset %s in line %q: %s",
				ms[2],
				line,
				err,
			)
		} else if 0 != off {
			continue
		}
		/* Work out the memory offset. */
		start, err := strconv.ParseInt(ms[1], 16, 64)
		if nil != err {
			fatalf(
				33,
				"Invalid memory offset %s in line %q: %s",
				ms[1],
				line,
				err,
			)
		}
		ret = append(ret, start)
	}

	slices.Sort(ret)
	return ret
}

func main() {}
