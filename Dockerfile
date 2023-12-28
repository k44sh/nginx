ARG ALPINE_VERSION=latest
ARG USER=nginx
ARG PUID=1000
ARG PGID=1000

FROM golang:alpine as geoip2

RUN apk add --update git
ENV GOPATH=/opt/geoipupdate
ENV GOMAXPROCS=1
RUN VERSION=$(git ls-remote --tags "https://github.com/maxmind/geoipupdate"| \
    awk '{print $2}' | sed 's/refs\/tags\///;s/\..*$//' | sort -uV | tail -1) \
    && go install github.com/maxmind/geoipupdate/$VERSION/cmd/geoipupdate@latest

FROM alpine:${ALPINE_VERSION} as builder
RUN apk --update --no-cache add curl

ARG USER PUID PGID
RUN addgroup -g ${PGID} ${USER} && adduser -D -H -u ${PUID} -G ${USER} -s /bin/sh ${USER}
RUN apk --update --no-cache add \
    apache2-utils \
    bash \
    bind-tools \
    ca-certificates \
    curl \
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
    s6-overlay \
    && nginx -V && rm -rf /tmp/* /var/cache/apk/*

RUN ln -sf /dev/stdout /var/log/nginx/access.log
RUN ln -sf /dev/stderr /var/log/nginx/error.log

COPY rootfs /
COPY --from=geoip2 /opt/geoipupdate/bin/geoipupdate /usr/local/bin/

VOLUME [ "/etc/nginx", "/var/www" ]

EXPOSE 8080

ENTRYPOINT [ "/init" ]

HEALTHCHECK --interval=5s --timeout=5s --start-period=5s CMD /usr/local/bin/healthcheck