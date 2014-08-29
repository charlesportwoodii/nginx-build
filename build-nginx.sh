#!/bin/bash
# Build Nginx Package Mainline

# Get the current script path
SCRIPTPATH=`pwd -P`
PCREVERSION=8.35
VERSION=$1
# Build the package in tmp
cd /tmp
rm -rf /tmp/nginx* /tmp/ngx*
wget http://nginx.org/download/nginx-$VERSION.tar.gz
$(which tar) -xf /tmp/nginx-$VERSION.tar.gz

## Let Nginx build PCRE
cd /tmp
wget ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-8.35.tar.gz
tar -xf pcre-8.35.tar.gz

# Install the latest version of OpenSSL rather than using the libaries provided with the host OS
cd /tmp/nginx-$VERSION
wget https://www.openssl.org/source/openssl-1.0.1i.tar.gz
tar -xf openssl-1.0.1i.tar.gz

## Add the necessary modules
mkdir -p /tmp/nginx-$VERSION/modules
cd /tmp/nginx-$VERSION/modules

# Nginx Lua Module
git clone https://github.com/chaoslawful/lua-nginx-module
cd lua-nginx-module
git checkout v0.9.10 
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
wget https://github.com/pagespeed/ngx_pagespeed/archive/v1.8.31.4-beta.zip
unzip v1.8.31.4-beta.zip
cd ngx_pagespeed-1.8.31.4-beta/
wget https://dl.google.com/dl/page-speed/psol/1.8.31.4.tar.gz
tar -xzvf 1.8.31.4.tar.gz
cd ..

# Nginx Length Hiding (BREACH ATTACK Mitigation)
wget https://github.com/nulab/nginx-length-hiding-filter-module/archive/master.zip
unzip master.zip

# TCP Proxy
#git clone https://github.com/yaoweibin/nginx_tcp_proxy_module

#cd /tmp/nginx-$VERSION
#patch -p1 < /tmp/nginx-$VERSION/modules/nginx_tcp_proxy_module/tcp.patch

## Configure

cd /tmp/nginx-$VERSION/
./configure --with-http_geoip_module --with-http_ssl_module --with-http_gzip_static_module --with-http_stub_status_module --with-http_spdy_module --prefix=/etc/nginx --error-log-path=/var/log/nginx/error.log --pid-path=/var/run/nginx.pid --http-log-path=/var/log/nginx/access.log --with-ipv6 --with-http_realip_module --with-http_mp4_module --with-http_addition_module --add-module=modules/ngx_http_enhanced_memcached_module --add-module=modules/redis2-nginx-module --add-module=modules/ngx_pagespeed-1.8.31.4-beta --add-module=modules/ngx_devel_kit --add-module=modules/lua-nginx-module --add-module=modules/nginx-length-hiding-filter-module-master --with-pcre=/tmp/pcre-$PCREVERSION --with-openssl=openssl-1.0.1i --with-openssl-opt="enable-ec_nistp_64_gcc_128"

## Copy Files
cp $SCRIPTPATH/*-pak .
cp -R $SCRIPTPATH/conf .
cp $SCRIPTPATH/init-nginx .
cp $SCRIPTPATH/setup .

## Make
make -j2
sudo make install
# sudo checkinstall sh /tmp/nginx-$VERSION/setup
# libluajit-5.1-common, luajit, pcre, libgeoip-dev, geoip-database, libluajit-5.1-dev, luajit
#bzr dh-make nginx-1.5.11 nginx-1.5.11.tar.gz
