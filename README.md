OpenSSL backtrace patch
-----------------------

Makes OpenSSL append a stack trace to its error reports.

Warning: watch out if you're heredoc'ing the patch in a Dockerfile: if your Docker version doesn't support it, the patch will be silently truncated.
