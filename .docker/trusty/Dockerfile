FROM ubuntu:14.04
ENV DEBIAN_FRONTEND noninteractive

# Install pre-dependencies
RUN apt-get update
RUN apt-get install wget m4 -y

# Install build tools
RUN apt-get update
RUN apt-get install make automake g++ autoconf build-essential zlib1g-dev libpcre3 libpcre3-dev libluajit-5.1-common libgeoip-dev geoip-database libluajit-5.1-dev luajit unzip git libgmp-dev libunbound-dev m4 python2.7 python-dev ruby ruby-dev apt-transport-https bc lsb-release gnutls-bin -y

RUN wget https://deb.erianna.com/amd64/trusty/libbrotli_0-1~trusty_amd64.deb
RUN wget https://deb.erianna.com/amd64/trusty/luajit-2.0_2.0-1~trusty_amd64.deb
RUN dpkg -i libbrotli_0-1~trusty_amd64.deb
RUN dpkg -i luajit-2.0_2.0-1~trusty_amd64.deb

# Install FPM
RUN gem install fpm
