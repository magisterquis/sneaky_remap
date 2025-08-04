package main

/*
 * client.go
 * Curlrevshell-compatible HTTPS client
 * By J. Stuart McMurray
 * Created 20250802
 * Last Modified 20250802
 */

import (
	"crypto/sha256"
	"crypto/subtle"
	"crypto/tls"
	"crypto/x509"
	"encoding/base64"
	"errors"
	"fmt"
	"net/http"
	"strings"
)

// sha256Prefix is used in curl's --pinnedpubkey to indicate the argument is
// a SHA256 hash.  It's often easier to copy/paste the hash with it attached,
// so we use this to allow for both ways.
const sha256Prefix = "sha256//"

// IncorrectFingerprintError is used to indicate a TLS connection was attempted
// but the server pubkey hash was not the one passed to NewHTTPClient.
type IncorrectFingerprintError struct {
	Got  [sha256.Size]byte
	Want [sha256.Size]byte
}

// Error implements the error interface.
func (err IncorrectFingerprintError) Error() string {
	return fmt.Sprintf(
		"incorrect TLS fingerprint: got:%s want:%s",
		base64.StdEncoding.EncodeToString(err.Got[:]),
		base64.StdEncoding.EncodeToString(err.Want[:]),
	)
}

// NewHTTPClient returns an HTTPS client which checks if the server's TLS
// certificate matches the given base64-encoded pubkey hash, as used by curl's
// --pinnedpubkey.  The hash may start with sha256// but this is not required.
func NewHTTPClient(hash string) (*http.Client, error) {
	/* Decode our hash. */
	b, err := base64.StdEncoding.DecodeString(strings.TrimPrefix(
		hash,
		sha256Prefix,
	))
	if nil != err {
		return nil, fmt.Errorf("decoding hash: %w", err)
	}

	/* Turn into a hash-verifier. */
	var v verifier
	if got, want := len(b), len(v); got != want {
		return nil, fmt.Errorf(
			"incorrect decoded hash size: got %d, expected %d",
			got,
			want,
		)
	}
	copy(v[:], b)

	/* Set up server verification. */
	t := http.DefaultTransport.(*http.Transport).Clone()
	if nil == t.TLSClientConfig {
		t.TLSClientConfig = new(tls.Config)
	}
	t.TLSClientConfig.InsecureSkipVerify = true
	t.TLSClientConfig.VerifyConnection = v.checkCertHash

	return &http.Client{Transport: t}, nil
}

// verifier wraps a --pinnedpubkey hash (which must not have sha256//) to
// return a function which verifies a tls.ConnectionState, suitable for use in
// tls.Config.VerifyConnection.
type verifier [sha256.Size]byte

// checkCert checks that cs's cert's pubkey's hash matches v.
func (v verifier) checkCertHash(cs tls.ConnectionState) error {
	/* Make sure we actually got a cert. */
	if 0 == len(cs.PeerCertificates) {
		return errors.New("no peer certificates")
	}
	/* Get the server's cert's pubkey's hash. */
	h, err := getCertHash(cs.PeerCertificates[0])
	if nil != err {
		return fmt.Errorf("hashing certificate: %w", err)
	}

	/* Make sure it matches. */
	if 1 != subtle.ConstantTimeCompare(h[:], v[:]) {
		return IncorrectFingerprintError{
			Got:  h,
			Want: v,
		}
	}

	return nil
}

// getCertHash gets the sha256 hash of the first certificate in cs.  The cert
// must not be nil.
func getCertHash(cert *x509.Certificate) ([sha256.Size]byte, error) {
	/* Work out the certificate's hash.  */
	b, err := x509.MarshalPKIXPublicKey(cert.PublicKey)
	if nil != err {
		return [sha256.Size]byte{}, fmt.Errorf(
			"marshalling peer's cert's pubkey to DER: %w",
			err,
		)
	}

	return sha256.Sum256(b), nil
}
