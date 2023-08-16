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

COPY openssl-backtrace.patch .
RUN patch -p1 < openssl-backtrace.patch
RUN CFLAGS=-rdynamic dpkg-buildpackage -b -uc -us 

WORKDIR /build
USER root
RUN dpkg -i *.deb
USER build

COPY test-backtrace.c .
RUN gcc -o test-backtrace test-backtrace.c -lssl -lcrypto -rdynamic

#CMD /bin/bash
CMD ./test-backtrace
