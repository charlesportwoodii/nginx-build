#!/bin/bash
# Build Nginx Package Mainline

# Get the current script path
SCRIPTPATH=`pwd -P`
PCREVERSION=8.37
OPENSSLVERSION=1.0.2e
PAGESPEED_VERSION=v1.9.32.6-beta
VERSION=$1
if [ -z "$2" ]
then
	RELEASEVER=1;
else
	RELEASEVER=$2;
fi
RELEASE=$(lsb_release --codename | cut -f2)

version=$(echo $VERSION | grep -o '[^-]*$')
major=$(echo $version | cut -d. -f1)
minor=$(echo $version | cut -d. -f2)
micro=$(echo $version | cut -d. -f3)

if [ $((minor%2)) -eq 0 ];
then
    RELEASENAME="nginx"
else
    RELEASENAME="nginx-mainline"
fi

# Build the package in tmp
cd /tmp
rm -rf /tmp/nginx* /tmp/ngx*
wget http://nginx.org/download/nginx-$VERSION.tar.gz
$(which tar) -xf /tmp/nginx-$VERSION.tar.gz

## Let Nginx build PCRE
cd /tmp/nginx-$VERSION
wget ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-$PCREVERSION.tar.gz
tar -xf pcre-$PCREVERSION.tar.gz

# Install the latest version of OpenSSL rather than using the libaries provided with the host OS
cd /tmp/nginx-$VERSION
wget https://www.openssl.org/source/openssl-$OPENSSLVERSION.tar.gz
tar -xf openssl-$OPENSSLVERSION.tar.gz

# Apply Cloudflare Chacha20-Poly1305 patch to OpenSSL
cd openssl-$OPENSSLVERSION
git clone https://github.com/cloudflare/sslconfig
cp sslconfig/patches/openssl__chacha20_poly1305_cf.patch .
patch -p1 < openssl__chacha20_poly1305_cf.patch

./config --prefix=/tmp/nginx\-$VERSION/openssl\-$OPENSSLVERSION/.openssl no-shared enable-ec_nistp_64_gcc_128 enable-tlsext
make depend
cd ..

## Add the necessary modules
mkdir -p /tmp/nginx-$VERSION/modules
cd /tmp/nginx-$VERSION/modules

# Nginx Lua Module
git clone https://github.com/openresty/lua-nginx-module

# Nginx Devel Kit
git clone https://github.com/simpl/ngx_devel_kit
cd ngx_devel_kit
git checkout v0.2.19
cd ..

# Enhanced Memcached
git clone https://github.com/bpaquet/ngx_http_enhanced_memcached_module

# Redis2
git clone https://github.com/openresty/redis2-nginx-module

git clone "https://github.com/openresty/echo-nginx-module"

git clone "https://github.com/openresty/headers-more-nginx-module"

git clone "https://github.com/yaoweibin/ngx_http_substitutions_filter_module"

# Nginx Pagespeed
git clone --depth=1 -b $PAGESPEED_VERSION "https://github.com/pagespeed/ngx_pagespeed" ngx_pagespeed

# PSOL
cd ngx_pagespeed
wget https://dl.google.com/dl/page-speed/psol/1.9.32.6.tar.gz
tar -xzvf 1.9.32.6.tar.gz

cd ..
git clone https://github.com/nulab/nginx-length-hiding-filter-module

# Nginx Cache Purge Module
git clone --depth=1 -b 2.3 https://github.com/FRiCKLE/ngx_cache_purge

## Configure
cd /tmp/nginx-$VERSION/ 
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
		--with-pcre=pcre-"$PCREVERSION" \
		--with-openssl=openssl-"$OPENSSLVERSION" \
		--with-openssl-opt="enable-ec_nistp_64_gcc_128 enable-tlsext"

## Copy Files
cp $SCRIPTPATH/*-pak .
cp -R $SCRIPTPATH/conf .
cp $SCRIPTPATH/init-nginx .
cp $SCRIPTPATH/setup .

## Make
make -j2
make install

# Check Install autobuild

cd /tmp/nginx-$VERSION
sudo checkinstall \
	-D \
	--fstrans \
	-pkgname $RELEASENAME \
	-pkgrelease "$RELEASEVER"~"$RELEASE" \
	-pkglicense BSD \
	-pkggroup HTTP \
	-maintainer charlesportwoodii@ethreal.net \
	-provides "$RELEASENAME, nginx-$major.$minor" \
	-requires "luajit, libluajit-5.1-common, libluajit-5.1-2, geoip-database" \
	-pakdir /tmp \
	-y \
	sh /tmp/nginx-$VERSION/setup
