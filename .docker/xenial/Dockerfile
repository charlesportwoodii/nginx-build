FROM ubuntu:16.04
ENV DEBIAN_FRONTEND noninteractive

# Install pre-dependencies
RUN apt-get update
RUN apt-get install wget m4 -y

# Install build tools
RUN apt-get update
RUN apt-get install make automake g++ autoconf build-essential zlib1g-dev libpcre3 libpcre3-dev libluajit-5.1-common libgeoip-dev geoip-database libluajit-5.1-dev luajit unzip git libgmp-dev libunbound-dev m4 python2.7 python-dev ruby ruby-dev apt-transport-https bc -y

# Add our deb repository
RUN sh -c 'echo "deb https://deb.erianna.com trusty main" > /etc/apt/sources.list.d/deb.erianna.com.list'

# Install GNUPG2 for ECDSA key support
RUN apt-get --allow-unauthenticated update
RUN apt-get --allow-unauthenticated install gnupg2 -y
RUN gpg --version

RUN ldconfig

# Download ECC key from Keybase
RUN wget --quiet -O - https://keybase.io/charlesportwood/key.asc | apt-key add -
RUN apt-get update
RUN apt-get install libbrotli luajit-2.0 -y

# Install FPM
RUN gem install fpm
