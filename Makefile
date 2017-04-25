SHELL := /bin/bash

# Dependency Versions
PCREVERSION?=8.40
OPENSSLVERSION?=1.0.2k
NPS_VERSION?=1.12.34.2
RELEASEVER?=1

# Bash data
SCRIPTPATH=$(shell pwd -P)
CORES=$(shell grep -c ^processor /proc/cpuinfo)
RELEASE=$(shell lsb_release --codename | cut -f2)
ARCH=$(shell arch)
IS_ARM=$(shell if [[ "$(ARCH)" == "arm"* ]]; then echo 1; else echo 0; fi)

ifeq ($(IS_ARM), 1)
EXTRA_ARGS="--with-openssl-opt='enable-tlsext no-ssl2 no-ssl3'"
else
EXTRA_ARGS='--add-dynamic-module=modules/ngx_pagespeed' '--with-openssl-opt=enable-ec_nistp_64_gcc_128 enable-tlsext no-ssl2 no-ssl3'
endif

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

build: clean base pcre openssl nginx

clean:
	rm -rf /tmp/nginx*
	# Remove Previous Nginx builds
	mkdir -p /tmp/nginx-$(VERSION)

base:
	mkdir -p /tmp/nginx-$(VERSION)

	# Download Nginx
	cd /tmp && \
	wget -qO- http://nginx.org/download/nginx-$(VERSION).tar.gz | tar -xz

pcre: 
	mkdir -p /tmp/nginx-$(VERSION)

	rm -rf /tmp/nginx-$(VERSION)/pcre-$(PCREVERSION).tar.gz
	rm -rf /tmp/nginx-$(VERSION)/pcre-$(PCREVERSION)*

	# Download PCRE
	cd /tmp/nginx-$(VERSION) && \
	wget ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-$(PCREVERSION).tar.gz && \
	tar -xzf /tmp/nginx-$(VERSION)/pcre-$(PCREVERSION).tar.gz

openssl:
	mkdir -p /tmp/nginx-$(VERSION)
	rm -rf /tmp/nginx-$(VERSION)/openssl-$(OPENSSLVERSION).tar.gz
	rm -rf /tmp/nginx-$(VERSION)/openssl-$(OPENSSLVERSION)

	# Download OpenSSL
	cd /tmp/nginx-$(VERSION) && \
	wget https://www.openssl.org/source/openssl-$(OPENSSLVERSION).tar.gz && \
	tar -xf openssl-$(OPENSSLVERSION).tar.gz
	
	if [[ "$(ARCH)" == "arm"* ]]; then \
		cd /tmp/nginx-$(VERSION)/openssl-$(OPENSSLVERSION) && \
		./config --prefix=$(OPENSSL_PATH) no-shared enable-tlsext no-ssl2 no-ssl3; \
	else \
		cd /tmp/nginx-$(VERSION)/openssl-$(OPENSSLVERSION) && \
		wget https://raw.githubusercontent.com/cloudflare/sslconfig/master/patches/openssl__chacha20_poly1305_draft_and_rfc_ossl102g.patch && \
		patch -p1 < openssl__chacha20_poly1305_draft_and_rfc_ossl102g.patch 2>/dev/null; true && \
		wget https://gist.githubusercontent.com/charlesportwoodii/9e95c6a4ecde31ea23c17f6823bdb320/raw/a02fac917fc30f4767fb60a9563bad69dc1c054d/chacha.patch && \
		patch < chacha.patch 2>/dev/null; true && \
		./config --prefix=$(OPENSSL_PATH) no-shared enable-ec_nistp_64_gcc_128 enable-tlsext no-ssl2 no-ssl3; \
	fi 

	cd /tmp/nginx-$(VERSION)/openssl-$(OPENSSLVERSION)  && \
	make depend

nginx:
	# Download Nginx Modules
	mkdir -p /tmp/nginx-$(VERSION)/modules

	# Nginx Lua Module
	cd /tmp/nginx-$(VERSION)/modules && \
	git clone https://github.com/openresty/lua-nginx-module -b master && \
	cd lua-nginx-module

	# Nginx Devel Kit
	cd /tmp/nginx-$(VERSION)/modules && \
	git clone https://github.com/simpl/ngx_devel_kit && \
	cd ngx_devel_kit && \
	git checkout v0.3.0

	# Enhanced Memcached
	cd /tmp/nginx-$(VERSION)/modules && \
	git clone https://github.com/bpaquet/ngx_http_enhanced_memcached_module

	# Redis2
	cd /tmp/nginx-$(VERSION)/modules && \
	git clone https://github.com/openresty/redis2-nginx-module -b v0.14

	# Google Brotli
	cd /tmp/nginx-$(VERSION)/modules && \
	git clone "https://github.com/google/ngx_brotli" --recursive

	# Openresty Echo Module
	cd /tmp/nginx-$(VERSION)/modules && \
	git clone "https://github.com/defanator/echo-nginx-module" -b master

	# OpenResty Headers More
	cd /tmp/nginx-$(VERSION)/modules && \
	git clone "https://github.com/openresty/headers-more-nginx-module" -b v0.32

	# HTTP Subs module
	cd /tmp/nginx-$(VERSION)/modules && \
	git clone "https://github.com/yaoweibin/ngx_http_substitutions_filter_module"

	# Nginx Pagespeed
	if [[ "$(ARCH)" == "arm"* ]]; then \
		echo "Pagespeed not supported on ARM"; \
	else \
		cd /tmp/nginx-$(VERSION)/modules && \
		git clone --depth=1 https://github.com/pagespeed/ngx_pagespeed && \
		cd /tmp/nginx-$(VERSION)/modules/ngx_pagespeed && \
		git fetch --tags && \
		git checkout v$(NPS_VERSION)-beta && \
		wget https://dl.google.com/dl/page-speed/psol/$(NPS_VERSION)-x64.tar.gz && \
		tar -xzvf $(NPS_VERSION)-x64.tar.gz; \
	fi 
	
	# Length Hiding Modules
	cd /tmp/nginx-$(VERSION)/modules && \
	git clone https://github.com/nulab/nginx-length-hiding-filter-module -b 1.1.0

	# Nginx Cache Purge Module
	cd /tmp/nginx-$(VERSION)/modules && \
	git clone --depth=1 -b 2.3 https://github.com/FRiCKLE/ngx_cache_purge

	# Configure
	cd /tmp/nginx-$(VERSION) && \
	export LUAJIT_LIB=/usr/local/lib && \
 	export LUAJIT_INC=/usr/local/include/luajit-2.0 && \
	export NGX_BROTLI_STATIC_MODULE_ONLY=1 && \
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
		--add-dynamic-module=modules/ngx_http_enhanced_memcached_module \
		--add-dynamic-module=modules/redis2-nginx-module \
		--add-dynamic-module=modules/headers-more-nginx-module \
		--add-dynamic-module=modules/nginx-length-hiding-filter-module \
		--add-dynamic-module=modules/ngx_cache_purge \
		--add-dynamic-module=modules/ngx_http_substitutions_filter_module \
		--add-dynamic-module=modules/ngx_brotli \
		--add-dynamic-module=modules/ngx_devel_kit \
		--add-dynamic-module=modules/lua-nginx-module \
		--with-pcre=pcre-"$(PCREVERSION)" \
		--with-openssl=openssl-"$(OPENSSLVERSION)" \
		$(EXTRA_ARGS)

	#--add-module=modules/echo-nginx-module
	# Make
	cd /tmp/nginx-$(VERSION) && \
	make -j$(CORES)

pre_package:
	# Clean the old build directory
	rm -rf /tmp/nginx-$(VERSION)-install

	# Install Nginx to nginx-<version>-install for fpm
	cd /tmp/nginx-$(VERSION) && \
	make install DESTDIR=/tmp/nginx-$(VERSION)-install

	rm -rf /tmp/nginx-$(VERSION)-install/etc/nginx/conf/nginx.conf
	
	# Create the working build directory
	mkdir -p /tmp/nginx-$(VERSION)-install/etc/nginx/client_body_temp 
	mkdir -p /tmp/nginx-$(VERSION)-install/etc/nginx/conf/conf.d
	mkdir -p /tmp/nginx-$(VERSION)-install/etc/nginx/fastcgi_temp
	mkdir -p /tmp/nginx-$(VERSION)-install/etc/nginx/proxy_temp
	mkdir -p /tmp/nginx-$(VERSION)-install/etc/nginx/scgi_temp
	mkdir -p /tmp/nginx-$(VERSION)-install/etc/nginx/uwsgi_temp
	mkdir -p /tmp/nginx-$(VERSION)-install/var/log/nginx

	# Copy local configuration files
	cp $(SCRIPTPATH)/conf/ssl.conf /tmp/nginx-$(VERSION)-install/etc/nginx/conf/ssl.conf
	cp $(SCRIPTPATH)/conf/fastcgi.conf /tmp/nginx-$(VERSION)-install/etc/nginx/conf/fastcgi.conf.default
	cp $(SCRIPTPATH)/conf/fastcgi_params /tmp/nginx-$(VERSION)-install/etc/nginx/conf/fastcgi_params.default
	cp $(SCRIPTPATH)/conf/koi-utf /tmp/nginx-$(VERSION)-install/etc/nginx/conf
	cp $(SCRIPTPATH)/conf/koi-win /tmp/nginx-$(VERSION)-install/etc/nginx/conf
	cp $(SCRIPTPATH)/conf/mime.types /tmp/nginx-$(VERSION)-install/etc/nginx/conf
	cp $(SCRIPTPATH)/conf/nginx.conf /tmp/nginx-$(VERSION)-install/etc/nginx/conf/nginx.conf.default
	cp $(SCRIPTPATH)/conf/scgi_params /tmp/nginx-$(VERSION)-install/etc/nginx/conf
	cp $(SCRIPTPATH)/conf/uwsgi_params /tmp/nginx-$(VERSION)-install/etc/nginx/conf
	cp $(SCRIPTPATH)/conf/win-utf /tmp/nginx-$(VERSION)-install/etc/nginx/conf

	# Copy the LICENSE file
	mkdir -p /tmp/nginx-$(VERSION)-install/usr/share/doc/$(RELEASENAME)
	cp /tmp/nginx-$(VERSION)/LICENSE /tmp/nginx-$(VERSION)-install/usr/share/doc/$(RELEASENAME)/LICENSE
	cp /tmp/nginx-$(VERSION)/README /tmp/nginx-$(VERSION)-install/usr/share/doc/$(RELEASENAME)/README
	cp /tmp/nginx-$(VERSION)/CHANGES /tmp/nginx-$(VERSION)-install/usr/share/doc/$(RELEASENAME)/CHANGES

	# Copy systemd file
	mkdir -p /tmp//nginx-$(VERSION)-install/lib/systemd/system
	cp $(SCRIPTPATH)/nginx.service /tmp/nginx-$(VERSION)-install/lib/systemd/system/nginx.service

fpm_debian: pre_package
	echo "Packaging Nginx for Debian"

	# Copy init.d for non systemd systems
	mkdir -p /tmp/nginx-$(VERSION)-install/etc/init.d
	cp $(SCRIPTPATH)/debian/init-nginx /tmp/nginx-$(VERSION)-install/etc/init.d/nginx

	fpm -s dir \
		-t deb \
		-n $(RELEASENAME) \
		-v $(VERSION)-$(RELEASEVER)~$(shell lsb_release --codename | cut -f2) \
		-C /tmp/nginx-$(VERSION)-install \
		-p $(RELEASENAME)_$(VERSION)-$(RELEASEVER)~$(shell lsb_release --codename | cut -f2)_$(shell arch).deb \
		-m "charlesportwoodii@erianna.com" \
		--license "BSD" \
		--url https://github.com/charlesportwoodii/nginx-build \
		--description "$(RELEASENAME), $(VERSION)" \
		--vendor "Charles R. Portwood II" \
		--depends "luajit > 0" \
		--depends "libluajit-5.1-common > 0" \
		--depends "libluajit-5.1-2 > 0" \
		--depends "libbrotli > 0" \
		--depends "luajit-2.0 > 0" \
		--depends "geoip-database > 0" \
		--deb-systemd-restart-after-upgrade \
		--template-scripts \
		--force \
		--no-deb-auto-config-files \
		--before-install $(SCRIPTPATH)/debian/preinstall-pak \
		--after-install $(SCRIPTPATH)/debian/postinstall-pak \
		--before-remove $(SCRIPTPATH)/debian/preremove-pak 

fpm_rpm: pre_package
	echo "Packaging Nginx for RPM"

	fpm -s dir \
		-t rpm \
		-n $(RELEASENAME) \
		-v $(VERSION)_$(RELEASEVER) \
		-C /tmp/nginx-$(VERSION)-install \
		-p $(RELEASENAME)_$(VERSION)-$(RELEASEVER)_$(shell arch).rpm \
		-m "charlesportwoodii@erianna.com" \
		--license "BSD" \
		--url https://github.com/charlesportwoodii/nginx-build \
		--description "$(RELEASENAME), $(VERSION)" \
		--vendor "Charles R. Portwood II" \
		--depends "luajit > 0" \
		--depends "libbrotli > 0" \
		--depends "luajit-2.0 > 0" \
		--depends "GeoIP > 0" \
		--rpm-digest sha384 \
		--rpm-compression gzip \
		--template-scripts \
		--force \
		--before-install $(SCRIPTPATH)/rpm/preinstall \
		--after-install $(SCRIPTPATH)/rpm/postinstall \
		--before-remove $(SCRIPTPATH)/rpm/preremove 
