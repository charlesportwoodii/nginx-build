SHELL := /bin/sh

# Dependency Versions
PCREVERSION?=8.42
OPENSSLVERSION?=1.1.1
RELEASEVER?=1

# Module versions
MODULE_LUA_VERSION="v0.10.13"
MODULE_DEVELKIT_VERSION="v0.3.0"
MODULE_REDIS2_VERSION="v0.15"
MODULE_BROTLI_VERSION="v0.1.2"
MODULE_HEADERSMORE_VERSION="v0.33"
MODULE_HTTPSUBS_VERSION="master"
MODULE_LENGTHHIDING_VERSION="1.1.1"
MODULE_SETMISC_VERSION="v0.32"

# Bash data
SCRIPTPATH=$(shell pwd -P)
CORES?=$(shell grep -c ^processor /proc/cpuinfo)
RELEASE=$(shell lsb_release --codename | cut -f2)
ARCH=$(shell arch)
IS_ARM=$(shell if [[ "$(ARCH)" == "arm"* ]]; then echo 1; else echo 0; fi)
IS_ALPINE=$(shell if [ -f /etc/alpine-release ]; then echo 1; else echo 0; fi)

ifeq ($(IS_ARM), 1)
EXTRA_ARGS="--with-openssl-opt='no-ssl3 enable-tls1_3'"
else
EXTRA_ARGS='--with-openssl-opt=enable-ec_nistp_64_gcc_128 no-ssl3 enable-tls1_3'
endif

description=$(shell cat debian/description-pak)
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
	wget https://ftp.pcre.org/pub/pcre/pcre-$(PCREVERSION).tar.gz && \
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
		./config --prefix=$(OPENSSL_PATH) no-shared no-ssl3; \
	else \
		cd /tmp/nginx-$(VERSION)/openssl-$(OPENSSLVERSION) && \
		./config --prefix=$(OPENSSL_PATH) no-shared enable-ec_nistp_64_gcc_128  no-ssl3; \
	fi 

	cd /tmp/nginx-$(VERSION)/openssl-$(OPENSSLVERSION)  && \
	make depend

nginx:
	# Download Nginx Modules
	mkdir -p /tmp/nginx-$(VERSION)/modules

	# Nginx Lua Module
	cd /tmp/nginx-$(VERSION)/modules && \
	git clone https://github.com/openresty/lua-nginx-module -b $(MODULE_LUA_VERSION) && \
	cd lua-nginx-module

	# Nginx Devel Kit
	cd /tmp/nginx-$(VERSION)/modules && \
	git clone https://github.com/simpl/ngx_devel_kit && \
	cd ngx_devel_kit && \
	git checkout $(MODULE_DEVELKIT_VERSION)

	# Redis2
	cd /tmp/nginx-$(VERSION)/modules && \
	git clone https://github.com/openresty/redis2-nginx-module -b $(MODULE_REDIS2_VERSION)

	# Google Brotli
	cd /tmp/nginx-$(VERSION)/modules && \
	git clone https://github.com/eustas/ngx_brotli -b $(MODULE_BROTLI_VERSION) --recursive

	# OpenResty Headers More
	cd /tmp/nginx-$(VERSION)/modules && \
	git clone "https://github.com/openresty/headers-more-nginx-module" -b $(MODULE_HEADERSMORE_VERSION)

	# HTTP Subs module
	cd /tmp/nginx-$(VERSION)/modules && \
	git clone https://github.com/yaoweibin/ngx_http_substitutions_filter_module -b $(MODULE_HTTPSUBS_VERSION)
	
	# Length Hiding Modules
	cd /tmp/nginx-$(VERSION)/modules && \
	git clone https://github.com/nulab/nginx-length-hiding-filter-module -b $(MODULE_LENGTHHIDING_VERSION)

	cd /tmp/nginx-$(VERSION)/modules && \
	git clone https://github.com/openresty/set-misc-nginx-module -b $(MODULE_SETMISC_VERSION)

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
		--pid-path=/var/run/nginx.pid \
		--error-log-path=/var/log/nginx/error.log \
		--http-log-path=/var/log/nginx/access.log \
		--add-module=modules/ngx_devel_kit \
		--add-dynamic-module=modules/redis2-nginx-module \
		--add-dynamic-module=modules/headers-more-nginx-module \
		--add-dynamic-module=modules/nginx-length-hiding-filter-module \
		--add-dynamic-module=modules/ngx_http_substitutions_filter_module \
		--add-dynamic-module=modules/ngx_brotli \
		--add-dynamic-module=modules/set-misc-nginx-module \
		--add-module=modules/lua-nginx-module \
		--with-pcre=pcre-"$(PCREVERSION)" \
		--with-openssl=openssl-"$(OPENSSLVERSION)" \
		$(EXTRA_ARGS)

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
	cp $(SCRIPTPATH)/conf/security-headers.conf /tmp/nginx-$(VERSION)-install/etc/nginx/conf/security-headers.conf
	cp $(SCRIPTPATH)/conf/fastcgi.conf /tmp/nginx-$(VERSION)-install/etc/nginx/conf/fastcgi.conf.default
	cp $(SCRIPTPATH)/conf/fastcgi_params /tmp/nginx-$(VERSION)-install/etc/nginx/conf/fastcgi_params.default
	cp $(SCRIPTPATH)/conf/koi-utf /tmp/nginx-$(VERSION)-install/etc/nginx/conf
	cp $(SCRIPTPATH)/conf/koi-win /tmp/nginx-$(VERSION)-install/etc/nginx/conf
	cp $(SCRIPTPATH)/conf/mime.types /tmp/nginx-$(VERSION)-install/etc/nginx/conf
	cp $(SCRIPTPATH)/conf/nginx.conf /tmp/nginx-$(VERSION)-install/etc/nginx/conf/nginx.conf.default
	cp $(SCRIPTPATH)/conf/scgi_params /tmp/nginx-$(VERSION)-install/etc/nginx/conf
	cp $(SCRIPTPATH)/conf/uwsgi_params /tmp/nginx-$(VERSION)-install/etc/nginx/conf
	cp $(SCRIPTPATH)/conf/win-utf /tmp/nginx-$(VERSION)-install/etc/nginx/conf
	cp $(SCRIPTPATH)/conf/modules.conf /tmp/nginx-$(VERSION)-install/etc/nginx/conf/modules.conf

	# Copy the LICENSE file
	mkdir -p /tmp/nginx-$(VERSION)-install/usr/share/doc/$(RELEASENAME)
	cp /tmp/nginx-$(VERSION)/LICENSE /tmp/nginx-$(VERSION)-install/usr/share/doc/$(RELEASENAME)/LICENSE
	cp /tmp/nginx-$(VERSION)/README /tmp/nginx-$(VERSION)-install/usr/share/doc/$(RELEASENAME)/README
	cp /tmp/nginx-$(VERSION)/CHANGES /tmp/nginx-$(VERSION)-install/usr/share/doc/$(RELEASENAME)/CHANGES

	# Move the modules to /usr/lib/nginx instead of /etc/
	mkdir -p /tmp/nginx-$(VERSION)-install/usr/lib/nginx
	mv /tmp/nginx-$(VERSION)-install/etc/nginx/modules /tmp/nginx-$(VERSION)-install/usr/lib/nginx/
	# Copy systemd file
	

ifeq ($(IS_ALPINE), 1)
	mkdir -p /tmp/nginx-$(VERSION)-install/etc/init.d
	cp $(SCRIPTPATH)/alpine/nginx.rc /tmp/nginx-$(VERSION)-install/etc/init.d
else 
	mkdir -p /tmp/nginx-$(VERSION)-install/lib/systemd/system
	cp $(SCRIPTPATH)/nginx.service /tmp/nginx-$(VERSION)-install/lib/systemd/system/nginx.service
endif

fpm_debian: pre_package
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
		--depends "luajit-2.0 > 0" \
		--depends "geoip-database > 0" \
		--deb-systemd-restart-after-upgrade \
		--deb-compression gz \
		--template-scripts \
		--force \
		--no-deb-auto-config-files \
		--before-install $(SCRIPTPATH)/debian/preinstall-pak \
		--after-install $(SCRIPTPATH)/debian/postinstall-pak \
		--before-remove $(SCRIPTPATH)/debian/preremove-pak 

fpm_rpm: pre_package
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
		--depends "luajit-2.0 > 0" \
		--depends "GeoIP > 0" \
		--rpm-digest sha384 \
		--rpm-compression gzip \
		--template-scripts \
		--force \
		--before-install $(SCRIPTPATH)/rpm/preinstall \
		--after-install $(SCRIPTPATH)/rpm/postinstall \
		--before-remove $(SCRIPTPATH)/rpm/preremove 

fpm_alpine: pre_package
	/fpm/bin/fpm -s dir \
		-t apk \
		-n $(RELEASENAME) \
		-v $(VERSION)-$(RELEASEVER)~$(shell uname -m) \
		-C /tmp/nginx-$(VERSION)-install \
		-p $(RELEASENAME)-$(VERSION)-$(RELEASEVER)~$(shell uname -m).apk \
		-m "charlesportwoodii@erianna.com" \
		--license "BSD" \
		--url https://github.com/charlesportwoodii/nginx-build \
		--description "$(RELEASENAME), $(VERSION)" \
		--vendor "Charles R. Portwood II" \
		--depends "luajit" \
		--depends "luajit-dev" \
		--depends "luajit-2.0" \
		--depends "geoip" \
		--depends "bash" \
		--depends "openrc" \
		--depends "openssl" \
		--force \
		-a $(shell uname -m) \
		--before-install $(SCRIPTPATH)/alpine/pre-install \
		--after-install $(SCRIPTPATH)/alpine/post-install \
		--before-remove $(SCRIPTPATH)/alpine/pre-deinstall
