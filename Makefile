.POSIX:

all: run

build:
	docker build -t openssl-backtrace --progress=plain .

run: build
	docker run openssl-backtrace
