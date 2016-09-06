# Build Scripts for Nginx

[![Mainline Builds](https://img.shields.io/travis/charlesportwoodii/nginx-build.svg?style=flat-square&branch=mainline "TravisCI (Mainline Builds)")](https://travis-ci.org/charlesportwoodii/nginx-build)
[![Stable Builds](https://img.shields.io/travis/charlesportwoodii/nginx-build.svg?style=flat-square&branch=stable "TravisCI (Stable Builds)")](https://travis-ci.org/charlesportwoodii/nginx-build)

This package helps you quickly and easily build Nginx and Nginx Mainline on your system. This package bundles several commonly used Nginx and OpenResty modules, as well as the most up to date OpenSSL and PCRE versions. If this package doens't help you install or package Nginx, there's a bug in this package.


## Building & Packaging
> Tested on Ubuntu 14.04, Ubuntu 16.04, CentOS7

The preferred way of building PHP is to use build and package them within Docker, and then to install PHP from the packages it provides. This allows you to build PHP in an environment isolated from your own, and allows you to install PHP through your package manager, rather than through source. This approach requires both `Docker` and `docker-compose` to be installed. (see https://docs.docker.com/).

1. Install Docker (https://docs.docker.com/engine/installation/)
2. Install Docker Composer 1.8.0+ (https://docs.docker.com/compose/install/)
3. Create a source file that specifies the PHP version you want to build for. This file is called `.vs`
```
export VERSION=<NGINX_VERSION>
export RELEASEVER=1
```
3. Build PHP-FPM by running `docker-compose`, and specifying the platform you want to build for
```
docker-compose run <truty|xenial|centos7>
```

> Note all packages are build for x86_64. x86, armv6l, and armv7l images are not supported.

### STABLE vs MAINLINE

This package builds two different version of nginx, `STABLE` and `MAINLINE`, and is dependant upon the version specified in the ```<version>``` tag. Nginx follows the convention of even numbered builds belonging to `STABLE` and odd number builds belonging to `MAINLINE`
