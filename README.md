OpenSSL backtrace patch
=======================

A patch to OpenSSL's `ERR_put_error()` using [backtrace() from glibc][glibc-backtrace] to make it append a stack trace to its error reports.

Developed to debug spikes of mysterious and impossible OpenSSL "shutdown while in init" errors seen in GitHub after an OS upgrade. The errors were reported in ruby exceptions coming from [Trilogy][trilogy], but the stack traces revealed they actually happened in [libcurl][libcurl], meaning they were left on OpenSSL's global error queue to be picked up by the next user.

Guided the following fix to Trilogy:
* https://github.com/trilogy-libraries/trilogy/pull/112

How it works
------------

The `backtrace()` function walks up the stack collecting stack pointers, and `backtrace_symbols()` resolves them into human-readable strings. Then the strings are concatenated and added to the SSL error with `ERR_add_error_data()`.

```c
#include <execinfo.h>

/* Add stack trace to the current error */
void add_backtrace()
{
	char buf[4096] = "";
	int buf_len = 0;

	/* this macro should prevent segfaults - tested with buf[100] */
#define BUF_PRINTF(...) \
	do { \
		if (buf_len < sizeof (buf) - 1) \
		{ \
			int n = snprintf(buf + buf_len, sizeof (buf) - buf_len, __VA_ARGS__); \
			if (n > 0) \
				buf_len += n; \
		} \
	} while (0)

	/* backtrace stuff */
	void* bt_array[1024];
	int bt_size;
	char** bt_strings;
	int i;

	bt_size = backtrace(bt_array, (sizeof (bt_array) / sizeof (bt_array[0])));
	bt_strings = backtrace_symbols(bt_array, bt_size);
	BUF_PRINTF(" Obtained %d stack frames:\n", bt_size);

	if (bt_strings != NULL)
		for (i = 0; i < bt_size; i++)
			BUF_PRINTF("%s\n", bt_strings[i]);
	else
		BUF_PRINTF("strings == NULL!\n");

	BUF_PRINTF("\n");
	ERR_add_error_data(1, buf);
	free(bt_strings);
#undef BUF_PRINTF
}
```

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
