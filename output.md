Without -rdynamic:
```
140011340771968:error:140A90C4:SSL routines:func(169):reason(196):../ssl/ssl_lib.c:2974:Obtained 5 stack frames:
/lib/x86_64-linux-gnu/libcrypto.so.1.1(+0x158591) [0x7f56ee727591]
/lib/x86_64-linux-gnu/libssl.so.1.1(SSL_CTX_new+0x361) [0x7f56ee8e07e1]
./test-backtrace(+0x1186) [0x555614c54186]
/lib/x86_64-linux-gnu/libc.so.6(__libc_start_main+0xf3) [0x7f56ee401083]
./test-backtrace(+0x10ae) [0x555614c540ae]
```

With CFLAGS=-rdynamic:
```
140641193837184:error:140A90C4:SSL routines:func(169):reason(196):../ssl/ssl_lib.c:2974:Obtained 6 stack frames:
/lib/x86_64-linux-gnu/libcrypto.so.1.1(+0x1a6329) [0x7fe994a26329]
/lib/x86_64-linux-gnu/libcrypto.so.1.1(ERR_put_error+0x1bb) [0x7fe994a26d4c]
/lib/x86_64-linux-gnu/libssl.so.1.1(SSL_CTX_new+0x4f) [0x7fe994c3164f]
./test-backtrace(main+0x1d) [0x55a26a584186]
/lib/x86_64-linux-gnu/libc.so.6(__libc_start_main+0xf3) [0x7fe9946b2083]
./test-backtrace(_start+0x2e) [0x55a26a5840ae]
```

Overflow test with buf[100]:
```
Obtained 6 stack frames:
./a(add_backtrace+0x1c) [0x55a8298961a5]
./a(dummy_function+0x45) [0x55a82
```
