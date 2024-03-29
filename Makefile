SHELL := /bin/sh

include .envs
export

# Dependency Versions
PCREVERSION?=8.45
OPENSSLVERSION?=3.2.1
VERSION?=
RELEASEVER?=1

# Module versions
MODULE_LUA_VERSION="master"
MODULE_DEVELKIT_VERSION="v0.3.1"
MODULE_REDIS2_VERSION="v0.15"
MODULE_BROTLI_VERSION="v0.1.2"
MODULE_HEADERSMORE_VERSION="master"
MODULE_HTTPSUBS_VERSION="master"
MODULE_LENGTHHIDING_VERSION="1.1.1"
MODULE_SETMISC_VERSION="v0.32"
MODULE_RTMP_VERSION="dev"

# Bash data
SCRIPTPATH=$(shell pwd -P)
CORES?=$(shell grep -c ^processor /proc/cpuinfo)
RELEASE=$(shell lsb_release --codename | cut -f2)
ARCH=$(shell arch)
IS_ALPINE=$(shell if [ -f /etc/alpine-release ]; then echo 1; else echo 0; fi)

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
	wget -qO-  --no-check-certificate http://nginx.org/download/nginx-$(VERSION).tar.gz | tar -xz

pcre:
	mkdir -p /tmp/nginx-$(VERSION)

	rm -rf /tmp/nginx-$(VERSION)/pcre-$(PCREVERSION).tar.gz
	rm -rf /tmp/nginx-$(VERSION)/pcre-$(PCREVERSION)*

	# Download PCRE
	cd /tmp/nginx-$(VERSION) && \
	wget --no-check-certificate https://versaweb.dl.sourceforge.net/project/pcre/pcre/$(PCREVERSION)/pcre-$(PCREVERSION).tar.gz && \
	tar -xzf /tmp/nginx-$(VERSION)/pcre-$(PCREVERSION).tar.gz

openssl:
	mkdir -p /tmp/nginx-$(VERSION)
	rm -rf /tmp/nginx-$(VERSION)/openssl-$(OPENSSLVERSION).tar.gz
	rm -rf /tmp/nginx-$(VERSION)/openssl-$(OPENSSLVERSION)

	# Download OpenSSL
	cd /tmp/nginx-$(VERSION) && \
	wget --no-check-certificate https://www.openssl.org/source/openssl-$(OPENSSLVERSION).tar.gz && \
	tar -xf openssl-$(OPENSSLVERSION).tar.gz

nginx:
	# Download Nginx Modules
	mkdir -p /tmp/nginx-$(VERSION)/modules

	# Nginx Lua Module
	cd /tmp/nginx-$(VERSION)/modules && \
	git clone https://github.com/openresty/lua-nginx-module -b $(MODULE_LUA_VERSION) --depth=5

	# Nginx Devel Kit
	cd /tmp/nginx-$(VERSION)/modules && \
	git clone https://github.com/simpl/ngx_devel_kit -b $(MODULE_DEVELKIT_VERSION) --depth=5

	# Redis2
	cd /tmp/nginx-$(VERSION)/modules && \
	git clone https://github.com/openresty/redis2-nginx-module -b $(MODULE_REDIS2_VERSION) --depth=5

	# Google Brotli
	cd /tmp/nginx-$(VERSION)/modules && \
	git clone https://github.com/eustas/ngx_brotli -b $(MODULE_BROTLI_VERSION) --depth=5 --recursive

	# OpenResty Headers More
	cd /tmp/nginx-$(VERSION)/modules && \
	git clone "https://github.com/openresty/headers-more-nginx-module" -b $(MODULE_HEADERSMORE_VERSION) --depth=5

	# HTTP Subs module
	cd /tmp/nginx-$(VERSION)/modules && \
	git clone https://github.com/yaoweibin/ngx_http_substitutions_filter_module -b $(MODULE_HTTPSUBS_VERSION) --depth=5

	# Length Hiding Modules
	cd /tmp/nginx-$(VERSION)/modules && \
	git clone https://github.com/nulab/nginx-length-hiding-filter-module -b $(MODULE_LENGTHHIDING_VERSION) --depth=5

	cd /tmp/nginx-$(VERSION)/modules && \
	git clone https://github.com/openresty/set-misc-nginx-module -b $(MODULE_SETMISC_VERSION) --depth=5

	cd /tmp/nginx-$(VERSION)/modules && \
	git clone https://github.com/sergey-dryabzhinsky/nginx-rtmp-module -b $(MODULE_RTMP_VERSION) --depth=5

	# Configure
	cd /tmp/nginx-$(VERSION) && \
	export LUAJIT_LIB=/usr/local/lib && \
 	export LUAJIT_INC=/usr/local/include/luajit-2.1 && \
	export NGX_BROTLI_STATIC_MODULE_ONLY=1 && \
	export CLFAGS=""  && \
	./configure \
		--with-cc-opt='-g -O2 -fstack-protector-strong -Wformat -Wp,-D_FORTIFY_SOURCE=2 -fPIC' \
		--with-ld-opt='-Wl,-Bsymbolic-functions -Wl,-z,relro -Wl,-z,now -Wl,--as-needed -pie' \
		--with-compat \
		--with-cpu-opt=generic \
		--with-http_geoip_module \
		--with-http_realip_module \
		--with-http_ssl_module \
		--with-http_gunzip_module \
		--with-http_addition_module \
		--with-http_v2_module \
                --with-http_v3_module \
		--with-http_sub_module \
		--with-http_mp4_module \
		--with-stream \
		--with-stream_ssl_module \
		--with-stream_realip_module \
		--with-stream_geoip_module \
		--with-stream_ssl_preread_module \
		--with-http_auth_request_module \
		--with-http_gzip_static_module \
		--with-http_stub_status_module \
		--with-ipv6 \
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
		--add-dynamic-module=modules/nginx-rtmp-module \
		--add-module=modules/lua-nginx-module \
		--with-threads \
		--with-pcre=pcre-$(PCREVERSION) \
		--with-openssl=openssl-$(OPENSSLVERSION) \
		--with-openssl-opt='enable-tls1_3 enable-ktls -fPIE -fPIC --release'

	# Make
	cd /tmp/nginx-$(VERSION) && \
	make -j1

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

	# Install RestyCore Lua FFI
	rm -rf /tmp/lua-resty-core

	git clone https://github.com/openresty/lua-resty-core -b v0.1.22 /tmp/lua-resty-core && \
	cd /tmp/lua-resty-core && \
	make install DESTDIR=/tmp/nginx-$(VERSION)-install LUA_VERSION=5.1

	rm -rf /tmp/lua-resty-lrucache

	git clone https://github.com/openresty/lua-resty-lrucache -b v0.11 /tmp/lua-resty-lrucache && \
	cd /tmp/lua-resty-lrucache && \
	make install DESTDIR=/tmp/nginx-$(VERSION)-install LUA_VERSION=5.1

	mkdir -p /tmp/nginx-$(VERSION)-install/usr/local/share/lua/
	mv /tmp/nginx-$(VERSION)-install/usr/local/lib/lua/5.1 /tmp/nginx-$(VERSION)-install/usr/local/share/lua/

	# Wait until ngx-lua gets a version bump then we can remove this
	sed -i '22d' /tmp/nginx-$(VERSION)-install/usr/local/share/lua/5.1/resty/core/base.lua

	mkdir -p /tmp/nginx-$(VERSION)-install/etc/nginx/conf/ssl
	openssl dhparam -out /tmp/nginx-$(VERSION)-install/etc/nginx/conf/ssl/dhparams.pem 2048

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
		--depends "luajit-2.1 > 0" \
		--depends "geoip-database > 0" \
		--depends "libbrotli > 0" \
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
		--depends "luajit-2.1 > 0" \
		--depends "GeoIP > 0" \
		--depends "libbrotli > 0" \
		--rpm-digest sha384 \
		--rpm-compression gzip \
		--template-scripts \
		--force \
		--before-install $(SCRIPTPATH)/rpm/preinstall \
		--after-install $(SCRIPTPATH)/rpm/postinstall \
		--before-remove $(SCRIPTPATH)/rpm/preremove

fpm_alpine: pre_package
	fpm -s dir \
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
		--depends "luajit-2.1" \
		--depends "geoip" \
		--depends "bash" \
		--depends "openrc" \
		--depends "openssl" \
		--depends "libbrotli" \
		--force \
		-a $(shell uname -m) \
		--before-install $(SCRIPTPATH)/alpine/pre-install \
		--after-install $(SCRIPTPATH)/alpine/post-install \
		--before-remove $(SCRIPTPATH)/alpine/pre-deinstall
