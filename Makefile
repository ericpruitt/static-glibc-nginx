# Author: Eric Pruitt (http://www.codevat.com)
# License: 2-Clause BSD (http://opensource.org/licenses/BSD-2-Clause)
# Description: This Makefile is designed to create a statically linked nginx
#       binary without any dependencies on the host system's version of glibc.

# URL of nginx source tarball
NGINX_SOURCE=http://nginx.org/download/nginx-1.9.2.tar.gz
# URL of OpenSSL source tarball
OPENSSL_SOURCE=http://www.openssl.org/source/openssl-1.0.1p.tar.gz
# URL of PCRE source tarball
PCRE_SOURCE=http://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-8.39.tar.gz

all: nginx/nginx

amroot:
	@if [ "$$(id -u)" -ne 0 ]; then \
		echo "Must be root to install dependencies."; \
		exit 1; \
	fi

ifeq (/etc/debian_version, $(wildcard /etc/debian_version))
deps: amroot
	apt-get install libxslt1-dev libxml2-dev zlib1g-dev libbz2-dev
else ifeq (/etc/redhat-release, $(wildcard /etc/redhat-release))
deps: amroot
	yum -y install gcc gcc-c++ make zlib-devel
else
deps:
	echo "Linux distribution not supported; install dependencies manually."
	exit 1
endif

clean:
	rm -rf .*-patched src pcre openssl nginx

cleaner: clean
	rm -f nginx.tar.gz pcre.tar.gz openssl.tar.gz

nginx.tar.gz:
	wget -O $@ $(NGINX_SOURCE)

src: nginx.tar.gz
	tar xf $<
	mv nginx-*/ $@
	touch $@

.nginx-patched: src/src/core/nginx.c
	cd src && patch -p1 < ../static-nginx.patch
	touch $@

src/src/core/nginx.c: src

pcre.tar.gz:
	wget -O $@ $(PCRE_SOURCE)

pcre: pcre.tar.gz
	tar xf $<
	mv pcre*/ $@
	touch $@

openssl.tar.gz:
	wget -O $@ $(OPENSSL_SOURCE)

openssl: openssl.tar.gz
	tar xf $<
	mv openssl*/ $@
	touch $@

openssl/Makefile.org: openssl

# The documentation target is disabled because it is unneeded, and due to
# changes in pod2man, the target may fail to build. Refer to
# https://github.com/openssl/openssl/issues/57 for more information.
.openssl-patched: openssl/Makefile.org
	cd openssl && sed -i '/^install:/s/install_docs//' Makefile.org
	cd openssl && touch Makefile
	touch $@

nginx:
	mkdir -p $@

nginx/nginx: nginx pcre .nginx-patched .openssl-patched
	cd src && ./configure --with-cc-opt=-Bstatic --with-ld-opt=-Bstatic \
		--with-cpu-opt=generic --with-pcre=../pcre --with-mail \
		--with-ipv6 --with-poll_module --with-select_module \
		--with-select_module --with-poll_module --with-http_ssl_module \
		--with-http_spdy_module --with-http_realip_module \
		--with-http_addition_module --with-http_sub_module \
		--with-http_dav_module --with-http_flv_module \
		--with-http_mp4_module --with-http_gunzip_module \
		--with-http_gzip_static_module --with-http_auth_request_module \
		--with-http_random_index_module --with-http_secure_link_module \
		--with-http_degradation_module --with-http_stub_status_module \
		--with-mail --with-mail_ssl_module \
		--with-openssl=../openssl --conf-path=./nginx.conf \
		--pid-path=./nginx.pid --sbin-path=. --prefix=../nginx
	cd src && $(MAKE) -j1
	cd src && $(MAKE) install

.PHONY: all clean cleaner amroot deps
