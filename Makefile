SHELL := /bin/bash

# Dependency Versions
PCREVERSION?=8.38
OPENSSLVERSION?=1.0.2e
PAGESPEED_VERSION=v1.9.32.10-beta
PSOLVERSION?=1.9.32.10
RELEASEVER?=1

# Bash data
SCRIPTPATH=$(shell pwd -P)
CORES=$(shell grep -c ^processor /proc/cpuinfo)
RELEASE=$(shell lsb_release --codename | cut -f2)

major=$(shell echo $(VERSION) | cut -d. -f1)
minor=$(shell echo $(VERSION) | cut -d. -f2)
micro=$(shell echo $(VERSION) | cut -d. -f3)

# Prefixes and constants
OPENSSL_PATH=/opt/openssl
PCRE_PATH=/opt/pcre
CURL_PREFIX=/opt/curl

# Calculate the Release name for packaging
MODULO=$(shell echo $(minor)%2 | bc)
ifeq ($(MODULO),0)
RELEASENAME="nginx"
else
RELEASENAME="nginx-mainline"
endif

nginx:
	# Remove Previous Nginx builds
	rm -rf /tmp/nginx*
	mkdir -p /tmp/nginx-$(VERSION)

	# Download Nginx
	cd /tmp && \
	wget -qO- http://nginx.org/download/nginx-$(VERSION).tar.gz | tar -xz
	
	# Download PCRE
	cd /tmp/nginx-$(VERSION) && \
	wget ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-$(PCREVERSION).tar.gz && \
	tar -xzf /tmp/pcre-$(PCREVERSION).tar.gz

	# Download OpenSSL
	cd /tmp/nginx-$(VERSION) &&\
	wget https://www.openssl.org/source/openssl-$(OPENSSLVERSION).tar.gz && \
	tar -xf openssl-$(OPENSSLVERSION).tar.gz

	# Apply Cloudflare Chacha20-Poly1305 patch to OpenSSL
	cd /tmp/nginx-$(VERSION)/openssl-$(OPENSSLVERSION)  && \
	git clone https://github.com/cloudflare/sslconfig && \
	cp sslconfig/patches/openssl__chacha20_poly1305_cf.patch . && \
	patch -p1 < openssl__chacha20_poly1305_cf.patch

	cd /tmp/nginx-$(VERSION)/openssl-$(OPENSSLVERSION)  && \
	./config --prefix=/tmp/nginx-$(VERSION)/openssl-$(OPENSSLVERSION).openssl no-shared enable-ec_nistp_64_gcc_128 enable-tlsext no-ssl2 no-ssl3 && \
	make depend

	# Download Nginx Modules
	mkdir -p /tmp/nginx-$(VERSION)/modules

	# Nginx Lua Module
	cd /tmp/nginx-$(VERSION)/modules && \
	git clone https://github.com/openresty/lua-nginx-module

	# Nginx Devel Kit
	cd /tmp/nginx-$(VERSION)/modules && \
	git clone https://github.com/simpl/ngx_devel_kit && \
	cd ngx_devel_kit && \
	git checkout v0.2.19

	# Enhanced Memcached
	cd /tmp/nginx-$(VERSION)/modules && \
	git clone https://github.com/bpaquet/ngx_http_enhanced_memcached_module

	# Redis2
	cd /tmp/nginx-$(VERSION)/modules && \
	git clone https://github.com/openresty/redis2-nginx-module

	# Openresty Echo Module
	cd /tmp/nginx-$(VERSION)/modules && \
	git clone "https://github.com/openresty/echo-nginx-module"

	# OpenResty Headers More
	cd /tmp/nginx-$(VERSION)/modules && \
	git clone "https://github.com/openresty/headers-more-nginx-module"

	# HTTP Subs module
	cd /tmp/nginx-$(VERSION)/modules && \
	git clone "https://github.com/yaoweibin/ngx_http_substitutions_filter_module"

	# Nginx Pagespeed
	mkdir -p /tmp/nginx-$(VERSION)/modules/ngx_pagespeed
	git clone --depth=1 -b $(PAGESPEED_VERSION) "https://github.com/pagespeed/ngx_pagespeed" /tmp/nginx-$(VERSION)/modules/ngx_pagespeed && \
	cd /tmp/nginx-$(VERSION)/modules/ngx_pagespeed && \
	wget https://dl.google.com/dl/page-speed/psol/$(PSOLVERSION).tar.gz && \
	tar -xzvf $(PSOLVERSION).tar.gz

	# Length Hiding Modules
	cd /tmp/nginx-$(VERSION)/modules && \
	git clone https://github.com/nulab/nginx-length-hiding-filter-module

	# Nginx Cache Purge Module
	cd /tmp/nginx-$(VERSION)/modules && \
	git clone --depth=1 -b 2.3 https://github.com/FRiCKLE/ngx_cache_purge

	# Configure
	cd /tmp/nginx-$(VERSION) && \
	./configure \
		--with-http_geoip_module \
		--with-http_realip_module \
		--with-http_ssl_module \
		--with-http_gunzip_module \
		--with-http_addition_module \
		--with-http_auth_request_module \
		--with-http_gzip_static_module \
		--with-http_stub_status_module \
		--with-http_v2_module \
		--with-http_sub_module \
		--with-ipv6 \
		--with-http_mp4_module \
		--with-mail \
		--with-mail_ssl_module \
		--prefix=/etc/nginx \
		--sbin-path=/usr/bin/nginx \
		--error-log-path=/var/log/nginx/error.log \
		--pid-path=/var/run/nginx.pid \
		--http-log-path=/var/log/nginx/access.log \
		--add-module=modules/ngx_http_enhanced_memcached_module \
		--add-module=modules/redis2-nginx-module \
		--add-module=modules/ngx_devel_kit \
		--add-module=modules/lua-nginx-module \
		--add-module=modules/echo-nginx-module \
		--add-module=modules/headers-more-nginx-module \
		--add-module=modules/nginx-length-hiding-filter-module \
		--add-module=modules/ngx_cache_purge \
		--add-module=modules/ngx_pagespeed \
		--add-module=modules/ngx_http_substitutions_filter_module \
		--with-pcre=pcre-"$(PCREVERSION)" \
		--with-openssl=openssl-"$(OPENSSLVERSION)" \
		--with-openssl-opt="enable-ec_nistp_64_gcc_128 enable-tlsext no-ssl2 no-ssl3"

	# Make
	cd /tmp/nginx-$(VERSION) && \
	make -j$(CORES) && \
	make install

package:
	# Copy Packaging tools
	cp -R $(SCRIPTPATH)/*-pak /tmp/nginx-$(VERSION)
	cp -R $(SCRIPTPATH)/conf /tmp/nginx-$(VERSION)
	cp $(SCRIPTPATH)/init-nginx /tmp/nginx-$(VERSION)
	cp $(SCRIPTPATH)/setup /tmp/nginx-$(VERSION)

	cd /tmp/nginx-$(VERSION) && \
	checkinstall \
		-D \
		--fstrans \
		-pkgname $(RELEASENAME) \
		-pkgrelease "$(RELEASEVER)"~"$(RELEASE)" \
		-pkglicense BSD \
		-pkggroup HTTP \
		-maintainer charlesportwoodii@ethreal.net \
		-provides "$(RELEASENAME), nginx-$(major).$(minor)" \
		-requires "luajit, libluajit-5.1-common, libluajit-5.1-2, geoip-database" \
		-pakdir /tmp \
		-y \
		sh /tmp/nginx-$(VERSION)/setup
