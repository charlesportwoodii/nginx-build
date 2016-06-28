# Build Scripts for Nginx

This package helps you quickly and easily build Nginx and Nginx Mainline on your system. This package bundles several commonly used Nginx and OpenResty modules, as well as the most up to date OpenSSL and PCRE versions. If this package doens't help you install or package Nginx, there's a bug in this package.

## Debian Builds
Tested on Ubuntu 12.04, Ubuntu 14.04, Ubuntu 16.04

### Dependencies

1. Install `luajit` and `libbrotli`.

These packages are available at the following locations, and come provided with a simple build system.

```bash
https://github.com/charlesportwoodii/luajit
https://github.com/charlesportwoodii/libbrotli
```

2. Install `apt` dependencies:
```bash
sudo apt-get install make automake g++ autoconf build-essential zlib1g-dev libpcre3 libpcre3-dev libluajit-5.1-common luajit libgeoip-dev geoip-database libluajit-5.1-dev luajit unzip git checkinstall libgmp-dev libunbound-dev m4 python2.7 python-dev
```

## Building

Nginx can be built using the following commands:
```bash
git clone https://github.com/charlesportwoodii/nginx-build
cd nginx-build
make build VERISON=<nginx_version>
```

Where ```<version>``` corresponds to the Nginx build version you want build

## Packaging

Packaging is performed through [FPM](https://github.com/jordansissel/fpm)

```bash
gem install fpm
```

Once FPM is installed, you can package your application either for debian or rpm by running the following commands, respectively

```bash
make fpm_debian VERSION=<nginx_version>
make fpm_rpm VERSION=<nginx_version>
```

### STABLE vs MAINLINE

This package builds two different version of nginx, `STABLE` and `MAINLINE`, and is dependant upon the version specified in the ```<version>``` tag. Nginx follows the convention of even numbered builds belonging to `STABLE` and odd number builds belonging to `MAINLINE`
