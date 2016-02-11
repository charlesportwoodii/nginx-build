# Build Scripts for Nginx
This package contains scripts necessary to automatically build Nginx on your system.

## Non-Apt dependencies

This package is depedant upon luajit and libbrotli. Build and packaging instructions can be found at:

https://github.com/charlesportwoodii/luajit
https://github.com/charlesportwoodii/libbrotli

## Dependencies
```
	apt-get install make automake g++ autoconf build-essential zlib1g-dev libpcre3 libpcre3-dev libluajit-5.1-common luajit libgeoip-dev geoip-database libluajit-5.1-dev luajit unzip git checkinstall libgmp-dev libunbound-dev m4 python2.7 python-dev
```

## Building
```
	cd /tmp
	git clone https://github.com/charlesportwoodii/nginx-build
	cd nginx-build
	sudo make build VERSION=<nginx_version>
```

Where ```<version>``` corresponds to the Nginx build version you want build

## STABLE vs MAINLINE

This package builds two different version of nginx, STABLE and MAINLINE, and is dependant upon the version specified in the ```<version>``` tag. 
