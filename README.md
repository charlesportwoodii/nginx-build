# Build Scripts for Nginx
This package contains scripts necessary to automatically build Nginx on your system.

## Building

```
	cd ~
	git clone https://github.com/charlesportwoodii/nginx-build
	sudo apt-get install build-essential zlib1g-dev libpcre3 libpcre3-dev libluajit-5.1-common luajit libgeoip-dev geoip-database libluajit-5.1-dev luajit
	cd nginx-build
	sudo sh build-nginx.sh <version>
```

Where ```<version>``` corresponds to the Nginx build version you want build
