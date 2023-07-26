#include <openssl/ssl.h>
#include <openssl/err.h>

int main(int argc, char* argv[])
{
	SSL_CTX* ssl_ctx = SSL_CTX_new(NULL);
	ERR_print_errors_fp(stderr);
	return 0;
}
