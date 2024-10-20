ARG ALPINE_VERSION=latest
ARG USER=docker

FROM golang:alpine as geoip2

RUN apk add --update git
ENV GOPATH=/opt/geoipupdate
ENV GOMAXPROCS=1
RUN VERSION=$(git ls-remote --tags "https://github.com/maxmind/geoipupdate"| \
    awk '{print $2}' | sed 's/refs\/tags\///;s/\..*$//' | sort -uV | tail -1) \
    && go install github.com/maxmind/geoipupdate/$VERSION/cmd/geoipupdate@latest

FROM alpine:${ALPINE_VERSION} as builder

ENV TZ="UTC" \
  PUID="1000" \
  PGID="1000"

ARG USER
RUN apk --update --no-cache add \
    apache2-utils \
    bash \
    bind-tools \
    ca-certificates \
    curl \
    ffmpeg \
    geoip \
    jq \
    nano \
    nginx \
    nginx-mod-http-auth-jwt \
    nginx-mod-http-brotli \
    nginx-mod-http-cookie-flag \
    nginx-mod-http-dav-ext \
    nginx-mod-http-fancyindex \
    nginx-mod-http-geoip2 \
    nginx-mod-http-headers-more \
    nginx-mod-http-vts \
    nginx-mod-rtmp \
    php83 \
    php83-dev \
    php83-bcmath \
    php83-cli \
    php83-ctype \
    php83-curl \
    php83-dom \
    php83-fileinfo \
    php83-fpm \
    php83-gd \
    php83-json \
    php83-iconv \
    php83-intl \
    php83-json \
    php83-mbstring \
    php83-mysqli \
    php83-openssl \
    php83-opcache \
    php83-pecl-apcu \
    php83-pear \
    php83-phar \
    php83-posix \
    php83-session \
    php83-simplexml \
    php83-sockets \
    php83-tokenizer \
    php83-xml \
    php83-zip \
    php83-zlib \
    s6-overlay \
    tzdata

RUN addgroup -g ${PGID} ${USER} \
  && adduser -D -H -u ${PUID} -G ${USER} -s /sbin/nologin ${USER} \
  && nginx -v && php83 -v \
  && rm -rf /tmp/* /var/cache/apk/*

  RUN touch /var/log/nginx/access.log \
  /var/log/nginx/error.log /var/log/nginx/stream.log \
  /var/log/php83/error.log /var/log/php83/access.log && \
  ln -sf /dev/stdout /var/log/nginx/access.log && \
  ln -sf /dev/stderr /var/log/nginx/error.log && \
  ln -sf /dev/stdout /var/log/php83/access.log && \
  ln -sf /dev/stderr /var/log/php83/error.log && \
  ln -sf /dev/stdout /var/log/nginx/stream.log

COPY rootfs /
COPY --from=geoip2 /opt/geoipupdate/bin/geoipupdate /usr/local/bin/

VOLUME [ "/etc/nginx", "/var/www" ]

EXPOSE 8080

ENTRYPOINT [ "/init" ]

HEALTHCHECK --interval=10s --timeout=5s --start-period=5s CMD /usr/local/bin/healthcheck