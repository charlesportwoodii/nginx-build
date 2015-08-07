# Build Scripts for Nginx
This package contains scripts necessary to automatically build Nginx on your system.

## APT dependencies
```
	apt-get install make automake g++ autoconf build-essential zlib1g-dev libpcre3 libpcre3-dev libluajit-5.1-common luajit libgeoip-dev geoip-database libluajit-5.1-dev luajit unzip git checkinstall libcurl4-openssl-dev libgmp-dev libunbound-dev m4
```

## Building
```
	cd /tmp
	git clone https://github.com/charlesportwoodii/nginx-build
	cd nginx-build
	sudo sh build-nginx.sh <version>
```

Where ```<version>``` corresponds to the Nginx build version you want build

## STABLE vs MAINLINE

This package builds two different version of nginx, STABLE and MAINLINE, and is dependant upon the version specified in the ```<version>``` tag. 
