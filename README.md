OpenSSL backtrace patch
=======================

A patch using [backtrace() from glibc][glibc-backtrace] to make OpenSSL append a stack trace to its error reports.

Developed to debug spikes of mysterious and impossible OpenSSL "shutdown while in init" errors seen in GitHub after an OS upgrade. The errors were reported in ruby exceptions coming from [Trilogy][trilogy], but the stack traces revealed they actually happened in [libcurl][libcurl], meaning they were left on OpenSSL's global error queue to be picked up by the next user.

Guided the following fixes to Trilogy:
* https://github.com/trilogy-libraries/trilogy/pull/112

🐋 Docker warning
-----------------

Watch out if you're heredoc'ing the patch in a Dockerfile. Make sure your Docker version supports it, or the patch might end up being silently truncated to nothing with no error message ~ I've been there. 🫠

Example output
--------------

Example output from `ERR_print_errors_fp()`:

```
140406773351040:error:140A90C4:SSL routines:func(169):reason(196):../ssl/ssl_lib.c:2974:Obtained 6 stack frames:
/lib/x86_64-linux-gnu/libcrypto.so.1.1(+0x1a6329) [0x7fb30015a329]
/lib/x86_64-linux-gnu/libcrypto.so.1.1(ERR_put_error+0x1bb) [0x7fb30015ad8f]
/lib/x86_64-linux-gnu/libssl.so.1.1(SSL_CTX_new+0x4f) [0x7fb30036564f]
./test-backtrace(main+0x1d) [0x55dffc17f186]
/lib/x86_64-linux-gnu/libc.so.6(__libc_start_main+0xf3) [0x7fb2ffde6083]
./test-backtrace(_start+0x2e) [0x55dffc17f0ae]
```

Build and run
-------------

Clone and type `make`.

[glibc-backtrace]: https://www.gnu.org/software/libc/manual/html_node/Backtraces.html "Backtraces (The GNU C Library)"
[trilogy]: https://github.com/trilogy-libraries/trilogy "trilogy-libraries/trilogy: Trilogy is a client library for MySQL-compatible database servers, designed for performance, flexibility, and ease of embedding."
[libcurl]: https://curl.se/libcurl/ "libcurl - the multiprotocol file transfer library"
