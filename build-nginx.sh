#!/bin/bash
# Build Nginx Package Mainline

# Get the current script path
SCRIPTPATH=`pwd -P`
PCREVERSION=8.36
OPENSSLVERSION=1.0.1m
VERSION=$1
if [ -z "$2" ]
then
	RELEASE_VER=1;
else
	RELEASE_VER=$2;
fi
PAGESPEED_VERSION=1.9.32.3
RELEASE=$(lsb_release --codename | cut -f2)

# Build the package in tmp
cd /tmp
rm -rf /tmp/nginx* /tmp/ngx*
wget http://nginx.org/download/nginx-$VERSION.tar.gz
$(which tar) -xf /tmp/nginx-$VERSION.tar.gz

## Let Nginx build PCRE
cd /tmp
wget ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-$PCREVERSION.tar.gz
tar -xf pcre-$PCREVERSION.tar.gz

# Install the latest version of OpenSSL rather than using the libaries provided with the host OS
cd /tmp/nginx-$VERSION
wget https://www.openssl.org/source/openssl-$OPENSSLVERSION.tar.gz
tar -xf openssl-$OPENSSLVERSION.tar.gz

## Add the necessary modules
mkdir -p /tmp/nginx-$VERSION/modules
cd /tmp/nginx-$VERSION/modules

# Nginx Lua Module
git clone https://github.com/chaoslawful/lua-nginx-module
cd lua-nginx-module
git checkout master 
cd ..

# Nginx Devel Kit
git clone https://github.com/simpl/ngx_devel_kit
cd ngx_devel_kit
git checkout v0.2.19
cd ..

# Enhanced Memcached
git clone https://github.com/bpaquet/ngx_http_enhanced_memcached_module

# Redis2
git clone https://github.com/agentzh/redis2-nginx-module

# Pagespeed
wget https://github.com/pagespeed/ngx_pagespeed/archive/v$PAGESPEED_VERSION-beta.zip
unzip v$PAGESPEED_VERSION-beta.zip
cd ngx_pagespeed-$PAGESPEED_VERSION-beta/
wget https://dl.google.com/dl/page-speed/psol/$PAGESPEED_VERSION.tar.gz
tar -xzvf $PAGESPEED_VERSION.tar.gz
cd ..

# Nginx Length Hiding (BREACH ATTACK Mitigation)
wget https://github.com/nulab/nginx-length-hiding-filter-module/archive/master.zip
unzip master.zip

## Configure

cd /tmp/nginx-$VERSION/
./configure --with-http_geoip_module --with-http_ssl_module --with-http_gzip_static_module --with-http_stub_status_module --with-http_spdy_module --prefix=/etc/nginx --error-log-path=/var/log/nginx/error.log --pid-path=/var/run/nginx.pid --http-log-path=/var/log/nginx/access.log --with-ipv6 --with-http_realip_module --with-http_mp4_module --with-http_addition_module --add-module=modules/ngx_http_enhanced_memcached_module --add-module=modules/redis2-nginx-module --add-module=modules/ngx_pagespeed-$PAGESPEED_VERSION-beta --add-module=modules/ngx_devel_kit --add-module=modules/lua-nginx-module --add-module=modules/nginx-length-hiding-filter-module-master --with-pcre=/tmp/pcre-$PCREVERSION --with-openssl=openssl-$OPENSSLVERSION --with-openssl-opt="enable-ec_nistp_64_gcc_128"

## Copy Files
cp $SCRIPTPATH/*-pak .
cp -R $SCRIPTPATH/conf .
cp $SCRIPTPATH/init-nginx .
cp $SCRIPTPATH/setup .

## Make
make -j2
sudo make install

# Check Install autobuild

cd /tmp/nginx-$VERSION
sudo checkinstall -D -pkgname nginx-mainline -pkgrelease $RELEASE_VER -pkglicense BSD -pkggroup HTTP -maintainer charlesportwoodii@ethreal.net -provides "nginx-mainline, nginx-1.7"  -requires "libluajit-5.1-common, luajit, pcre, libgeoip-dev, geoip-database, libluajit-5.1-dev, luajit" -pakdir /tmp/ -y sh /tmp/nginx-$VERSION/setup
mv /tmp/nginx-mainline_$VERSION-{$RELEASE_VER}_amd64.deb /tmp/nginx-mainline_$VERSION-{$RELEASE_VER}_amd64_$RELEASE.deb
