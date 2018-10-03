# Author: Eric Pruitt (http://www.codevat.com)
# License: 2-Clause BSD (http://opensource.org/licenses/BSD-2-Clause)
# Description: This Makefile is designed to create a statically linked nginx
#       binary without any dependencies on the host system's version of glibc.
.POSIX:
.SILENT: amroot deps

# URL of nginx source tarball
NGINX_SOURCE=http://nginx.org/download/nginx-1.15.3.tar.gz
# URL of OpenSSL source tarball
OPENSSL_SOURCE=https://www.openssl.org/source/openssl-1.0.2p.tar.gz
# URL of PCRE source tarball
PCRE_SOURCE=https://ftp.pcre.org/pub/pcre/pcre-8.42.tar.gz

WGET = wget --no-use-server-timestamps

all: nginx/.FOLDER

amroot:
	if [ "$$(id -u)" -ne 0 ]; then \
		echo "Must be root to install dependencies."; \
		exit 1; \
	fi

deps: amroot
	if [ -e /etc/debian_version ]; then \
		apt-get install libxslt1-dev libxml2-dev zlib1g-dev libbz2-dev; \
	elif [ -e /etc/redhat-release ]; then \
		yum -y install gcc gcc-c++ make zlib-devel; \
	else \
		echo "Linux distribution not supported;" \
		     "install dependencies manually."; \
		exit 1; \
	fi

clean:
	rm -rf .*-patched src pcre openssl nginx

cleaner: clean
	rm -f nginx.tar.gz pcre.tar.gz openssl.tar.gz

nginx.tar.gz:
	$(WGET) -O $@ $(NGINX_SOURCE)

src: nginx.tar.gz
	tar xf $?
	mv nginx-*/ $@
	touch $@

src/.PATCHED: src/src/core/nginx.c
	(cd src && patch -p1 < ../static-glibc-nginx.patch)
	touch $@

src/src/core/nginx.c: src

pcre.tar.gz:
	$(WGET) -O $@ $(PCRE_SOURCE)

pcre/.FOLDER: pcre.tar.gz
	tar xf $?
	mv pcre*/ $(@D)
	touch $@

openssl.tar.gz:
	$(WGET) -O $@ $(OPENSSL_SOURCE)

openssl/.FOLDER: openssl.tar.gz
	tar xf $?
	mv openssl*/ $(@D)
	touch $@

openssl/Makefile.org: openssl/.FOLDER

src/Makefile: openssl/.FOLDER pcre/.FOLDER src/.PATCHED
	(cd src && \
	CFLAGS="$(CFLAGS) -DNGX_HAVE_DLOPEN=0" \
	./configure \
		--conf-path=nginx.conf \
		--pid-path=nginx.pid \
		--prefix=. \
		--sbin-path=. \
		--with-cc-opt=-static \
		--with-cpu-opt=generic \
		--with-http_addition_module \
		--with-http_auth_request_module \
		--with-http_dav_module \
		--with-http_degradation_module \
		--with-http_flv_module \
		--with-http_gunzip_module \
		--with-http_gzip_static_module \
		--with-http_mp4_module \
		--with-http_random_index_module \
		--with-http_realip_module \
		--with-http_secure_link_module \
		--with-http_ssl_module \
		--with-http_stub_status_module \
		--with-http_sub_module \
		--with-http_v2_module \
		--with-ipv6 \
		--with-ld-opt=-static \
		--with-mail \
		--with-mail_ssl_module \
		--with-openssl-opt="-UDSO_DLFCN" \
		--with-openssl=../openssl \
		--with-pcre=../pcre \
		--with-poll_module \
		--with-select_module \
	)

src/objs/nginx: src/Makefile
	(cd src && $(MAKE))

nginx/.FOLDER: src/objs/nginx
	mkdir -p $(@D)
	(cd src && $(MAKE) DESTDIR=$(PWD)/$(@D)/ install)
	(cd $(@D) && rm -f *.default koi-win koi-utf win-utf)
	touch $@
