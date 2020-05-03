FROM charlesportwoodii/alpine:3.11-base
LABEL reference="https://github.com/charlesportwoodii/docker-images"
LABEL repository="https://github.com/charlesportwoodii/nginx-build"
LABEL maintainer="Charles R. Portwood II <charlesportwoodii@erianna.com>"
LABEL description="Nginx Docker image with several useful plugins."

ARG PACKAGE_NAME="nginx-mainline"

RUN apk update && \
    apk add ${PACKAGE_NAME} --no-cache && \
    rm -rf /var/cache/apk/* && \
    mkdir -p /etc/nginx/conf/conf.d /etc/nginx/conf/includes /var/www && \
    ln -sf /dev/stdout /var/log/nginx/access.log && \
	ln -sf /dev/stderr /var/log/nginx/error.log

# Define mountable directories.
VOLUME ["/etc/nginx/conf/conf.d", "/etc/nginx/conf/includes", "/etc/nginx/conf/ssl", "/var/www/"]

# Define working directory.
WORKDIR /etc/nginx

EXPOSE 80 443

ENTRYPOINT ["/usr/bin/nginx", "-g", "daemon off;"]