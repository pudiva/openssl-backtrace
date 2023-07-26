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

RUN apt-get update
RUN apt-get install -y \
	# tzdata because focal \
	tzdata \
	# libnettle6 is buggy on stretch \
	#libnettle6=3.3-1+b2 \
	build-essential \
	fakeroot \
	devscripts \
	pkg-config \
	#libssl-dev \
	#wget \
	#curl \
	#bash \
	#vim

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
index 1372d52f80..615e1a9120 100644
--- a/crypto/err/err.c
+++ b/crypto/err/err.c
@@ -23,6 +23,48 @@
 #include "internal/constant_time.h"
 #include "e_os.h"

+#include <execinfo.h>
+
+void add_backtrace()
+{
+        void *array[10];
+        int size;
+        char** strings;
+
+       size = backtrace(array, 10);
+       strings = backtrace_symbols(array, size);
+
+        if (strings != NULL)
+        {
+#if 0
+               /* when buf is not big enough, it just truncates like that:
+                *
+                * ```
+                * Obtained 6 stack frames:
+                * ./a(add_backtrace+0x1c) [0x55a8298961a5]
+                * ./a(dummy_function+0x45) [0x55a82
+                * ```
+                */
+               char buf[100] = "";
+#else
+               char buf[4096] = "";
+#endif
+               int len = 0;
+               int i;
+
+               len = snprintf(buf, sizeof (buf), "Obtained %d stack frames:\n", size);
+
+                for (i = 0; i < size && len < sizeof (buf); i++)
+                        len += snprintf(buf + len, sizeof (buf) - len, "%s\n", strings[i]);
+
+               len += snprintf(buf + len, sizeof (buf) - len, "\n");
+
+               ERR_add_error_data(1, buf);
+        }
+
+        free(strings);
+}
+
 static int err_load_strings(const ERR_STRING_DATA *str);

 static void ERR_STATE_free(ERR_STATE *s);
@@ -435,6 +477,8 @@ void ERR_put_error(int lib, int func, int reason, const char *file, int line)
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
