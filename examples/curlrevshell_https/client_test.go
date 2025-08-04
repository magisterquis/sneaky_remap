package main

/*
 * client.go
 * Tests for client.go
 * By J. Stuart McMurray
 * Created 20250802
 * Last Modified 20250802
 */

import (
	"encoding/base64"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestNewClient(t *testing.T) {
	/* HTTPS server. */
	rBody := "kittens"
	svr := httptest.NewTLSServer(http.HandlerFunc(func(
		w http.ResponseWriter,
		r *http.Request,
	) {
		io.WriteString(w, rBody)
	}))
	defer svr.Close()

	/* Get expected hash. */
	shash, err := getCertHash(svr.Certificate())
	if nil != err {
		t.Fatalf("Error hashing server certificate: %s", err)
	}
	b64h := base64.StdEncoding.EncodeToString(shash[:])

	/* GET / as a string. */
	get := func(c *http.Client) (string, error) {
		res, err := c.Get(svr.URL)
		if nil != err {
			return "", fmt.Errorf("making GET request: %w", err)
		}
		defer res.Body.Close()
		if http.StatusOK != res.StatusCode {
			return "", fmt.Errorf(
				"non-OK status code: %s",
				res.Status,
			)
		}
		b, err := io.ReadAll(res.Body)
		if nil != err {
			return "", fmt.Errorf("reading response body: %w", err)
		}

		return string(b), nil
	}

	/* Make a connection with the right hash, should work. */
	t.Run("correct_hash/no_prefix", func(t *testing.T) {
		if c, err := NewHTTPClient(b64h); nil != err {
			t.Fatalf(
				"Error creating HTTPS client: %s",
				err,
			)
		} else if s, err := get(c); nil != err {
			t.Errorf(
				"Error making HTTPS request: %s",
				err,
			)
		} else if got, want := s, rBody; got != want {
			t.Errorf(
				"Incorrect response to HTTPS request\n"+
					" got: %s\n"+
					"want: %s",
				got,
				want,
			)
		}
	})

	/* Right hash again, but with sha256// in front of it. */
	t.Run("correct_hash/with_prefix", func(t *testing.T) {
		if c, err := NewHTTPClient(sha256Prefix + b64h); nil != err {
			t.Fatalf(
				"Error creating HTTPS client: %s",
				err,
			)
		} else if s, err := get(c); nil != err {
			t.Errorf(
				"Error making HTTPS request: %s",
				err,
			)
		} else if got, want := s, rBody; got != want {
			t.Errorf(
				"Incorrect response to HTTPS request\n"+
					" got: %s\n"+
					"want: %s",
				got,
				want,
			)
		}
	})

	/* Make a new connection with the wrong hash, shouldn't work. */
	t.Run("incorrect_hash", func(t *testing.T) {
		whash := []byte(b64h)
		copy(whash, []byte("wrong"))
		var ife IncorrectFingerprintError
		if c, err := NewHTTPClient(string(whash)); nil != err {
			t.Fatalf(
				"Error creating HTTPS client: %s",
				err,
			)
		} else if s, err := get(c); nil == err {
			t.Fatalf(
				"HTTPS request unexpectedly succeeded, "+
					"got body %q",
				s,
			)
		} else if !errors.As(err, &ife) {
			t.Fatalf("Incorrect error (%T): %s", err, err)
		}
	})
}
