FROM ubuntu:focal
ENV DEBIAN_FRONTEND=noninteractive

RUN cat > /etc/apt/sources.list <<'EOF'
deb http://archive.ubuntu.com/ubuntu/ focal main restricted
deb-src http://archive.ubuntu.com/ubuntu/ focal main restricted
deb http://archive.ubuntu.com/ubuntu/ focal-updates main restricted
deb-src http://archive.ubuntu.com/ubuntu/ focal-updates main restricted
deb http://security.ubuntu.com/ubuntu/ focal-security main restricted
deb-src http://security.ubuntu.com/ubuntu/ focal-security main restricted
EOF

RUN apt-get update && apt-get install -y \
	tzdata \
	build-essential \
	fakeroot \
	devscripts \
	pkg-config \
	wget \
	curl \
	bash \
	vim

RUN apt-get build-dep -y openssl

WORKDIR /build
RUN chmod 777 .
RUN useradd -ms /bin/bash build
USER build

RUN apt-get source openssl
WORKDIR /build/openssl-1.1.1f

ENV DEB_BUILD_OPTIONS='nostrip debug'

RUN patch -p1 <<'EOF'
diff --git a/crypto/err/err.c b/crypto/err/err.c
index 1372d52f80..91087855db 100644
--- a/crypto/err/err.c
+++ b/crypto/err/err.c
@@ -23,6 +23,58 @@
 #include "internal/constant_time.h"
 #include "e_os.h"
 
+#include <execinfo.h>
+
+/* Add stack trace to the current error
+ *
+ * Example output from ERR_print_errors_fp()
+ *
+ * 140406773351040:error:140A90C4:SSL routines:func(169):reason(196):../ssl/ssl_lib.c:2974:Obtained 6 stack frames:
+ * /lib/x86_64-linux-gnu/libcrypto.so.1.1(+0x1a6329) [0x7fb30015a329]
+ * /lib/x86_64-linux-gnu/libcrypto.so.1.1(ERR_put_error+0x1bb) [0x7fb30015ad8f]
+ * /lib/x86_64-linux-gnu/libssl.so.1.1(SSL_CTX_new+0x4f) [0x7fb30036564f]
+ * ./test-backtrace(main+0x1d) [0x55dffc17f186]
+ * /lib/x86_64-linux-gnu/libc.so.6(__libc_start_main+0xf3) [0x7fb2ffde6083]
+ * ./test-backtrace(_start+0x2e) [0x55dffc17f0ae]
+ */
+void add_backtrace()
+{
+	char buf[4096] = "";
+	int buf_len = 0;
+
+	/* this macro should prevent segfaults - tested with buf[100] */
+#define BUF_PRINTF(...) \
+	do { \
+		if (buf_len < sizeof (buf) - 1) \
+		{ \
+			int n = snprintf(buf + buf_len, sizeof (buf) - buf_len, __VA_ARGS__); \
+			if (n > 0) \
+				buf_len += n; \
+		} \
+	} while (0)
+
+	/* backtrace stuff */
+	void* bt_array[1024];
+	int bt_size;
+	char** bt_strings;
+	int i;
+
+	bt_size = backtrace(bt_array, (sizeof (bt_array) / sizeof (bt_array[0])));
+	bt_strings = backtrace_symbols(bt_array, bt_size);
+	BUF_PRINTF(" Obtained %d stack frames:\n", bt_size);
+
+	if (bt_strings != NULL)
+		for (i = 0; i < bt_size; i++)
+			BUF_PRINTF("%s\n", bt_strings[i]);
+	else
+		BUF_PRINTF("strings == NULL!\n");
+
+	BUF_PRINTF("\n");
+	ERR_add_error_data(1, buf);
+	free(bt_strings);
+#undef BUF_PRINTF
+}
+
 static int err_load_strings(const ERR_STRING_DATA *str);
 
 static void ERR_STATE_free(ERR_STATE *s);
@@ -435,6 +487,8 @@ void ERR_put_error(int lib, int func, int reason, const char *file, int line)
     es->err_file[es->top] = file;
     es->err_line[es->top] = line;
     err_clear_data(es, es->top);
+
+    add_backtrace();
 }
 
 void ERR_clear_error(void)
EOF

RUN CFLAGS=-rdynamic dpkg-buildpackage -b -uc -us 

WORKDIR /build
USER root
RUN dpkg -i *.deb
USER build

COPY test-backtrace.c .
RUN gcc -o test-backtrace test-backtrace.c -lssl -lcrypto -rdynamic

#CMD /bin/bash
CMD ./test-backtrace
