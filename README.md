<p align="center">
  <a href="https://gitlab.com/cyberpnkz/nginx" target="_blank"><img width="75%" src="https://raw.githubusercontent.com/k44sh/nginx/main/.nginx.png"></a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Docker-Alpine%20Linux-blue?logo=alpinelinux" alt="Alpine Linux">
  <a href="https://gitlab.com/cyberpnkz/nginx/-/pipelines/latest"><img src="https://img.shields.io/gitlab/pipeline-status/cyberpnkz/nginx?logo=gitlab&label=Build" alt="Build Status"></a>
  <a href="https://github.com/k44sh/nginx"><img src="https://img.shields.io/github/stars/k44sh/nginx?logo=github&label=Stars" alt="Github Stars"></a>
  <a href="https://raw.githubusercontent.com/k44sh/nginx/main/LICENSE"><img src="https://img.shields.io/github/license/k44sh/nginx?label=License" alt="License"></a>
</p>

<p align="center">
  <a href="https://hub.docker.com/r/k44sh/nginx/tags?page=1&ordering=last_updated"><img src="https://img.shields.io:/docker/v/k44sh/nginx/latest?logo=docker&label=Version" alt="Latest Version"></a>
  <a href="https://hub.docker.com/r/k44sh/nginx/tags"><img src="https://img.shields.io:/docker/image-size/k44sh/nginx/latest?logo=docker&label=Size" alt="Docker Size"></a>
  <a href="https://hub.docker.com/r/k44sh/nginx/tags"><img src="https://img.shields.io:/docker/pulls/k44sh/nginx?logo=docker&label=Pull" alt="Docker Pulls"></a>
</p>

## About

Docker of the NGINX web server based on Alpine Linux
___

## Features

* Latest version of [NGINX](https://nginx.org/download) from [Alpine Linx](https://alpinelinux.org/)
* [s6-overlay](https://github.com/just-containers/s6-overlay) process supervisor
* [GeoIP2](https://www.maxmind.com/en/geoip-databases) database by [MaxMind](https://www.maxmind.com) (Update with your own key)
* Run as non-root user
* Multi-platform image

## Modules

| **Module**                                                                            | **Desctiption**                                               |
| :------------------------------------------------------------------------------------ | :------------------------------------------------------------ |
| [nginx-mod-http-brotli](https://github.com/google/ngx_brotli)                         | Serves compressed responses with brotli (`Google`)            |
| [nginx-mod-http-auth-jwt](https://github.com/kjdev/nginx-auth-jwt)                    | Client authorization (JSON Web Token (JWT) / OpenID Connect)  |
| [nginx-mod-http-cookie-flag](https://github.com/AirisX/nginx_cookie_flag_module)      | Set the flags `HttpOnly`, `secure and` `SameSite` for cookies |
| [nginx-mod-http-dav-ext](https://github.com/arut/nginx-dav-ext-module)                | Additional implementation for full WebDav compatibility       |
| [nginx-mod-http-fancyindex](https://github.com/aperezdc/ngx-fancyindex)               | Like the built-in autoindex module, but fancier               |
| [nginx-mod-http-geoip2](https://github.com/leev/ngx_http_geoip2_module)               | City and country code lookups via the MaxMind GeoIP2          |
| [nginx-mod-http-headers-more](https://github.com/openresty/headers-more-nginx-module) | Set and clear input and output headers                        |
| [nginx-mod-http-vts](https://github.com/vozlt/nginx-module-vts)                       | Virtual host and upstream traffic status                      |
| [nginx-mod-rtmp](https://github.com/arut/nginx-rtmp-module)                           | RTMP protocol support. Live streaming and video on demand     |

### Example

#### VTS Module

<p align="center">
  <a href="https://gitlab.com/cyberpnkz/nginx" target="_blank"><img width="75%" src="https://raw.githubusercontent.com/k44sh/nginx/main/.stats.png"></a>
</p>

## Multi Platform Images

* `linux/amd64`
* `linux/arm64`
* `linux/arm/v7`

## Environment Variables

| **Variable** | **Desctiption**                                        |
| :----------- | :----------------------------------------------------- |
| `TZ`         | The timezone assigned to the container (default `UTC`) |
| `PORT`       | NGINX listening port (default `8080`)                  |
| `PUID`       | NGINX user id (default `1000`)                         |
| `PGID`       | NGINX group id (default `1000`)                        |
| `MM_ACCOUNT` | Your MaxMind account ID                                |
| `MM_LICENSE` | Your MaxMind license key                               |

> ℹ️ In the absence of MaxMinx (GeoIP2) information, there will be no cron for updating the database

## Volumes

* `/config`: NGINX configuration files `/etc/nginx`
* `/data`:   NGINX web content files `/var/www`

## Usage

### Docker Compose

Docker compose is the recommended way to run this image. Edit the compose file with your preferences and run the following command:

```shell
mkdir $(pwd)/{config,data}
docker compose up -d
docker compose logs -f
```

### Start

You can also use the following minimal command:

```shell
docker run -d --name nginx -p 80:8000 k44sh/nginx:latest 
docker logs -f nginx
```

Or this one for more customization:

```shell
mkdir $(pwd)/{config,data}
docker run -d --name nginx \
  --ulimit nproc=65535 \
  --ulimit nofile=32000:40000 \
  -p 80:8000/tcp \
  -e TZ="America/Toronto" \
  -e PORT="plop" \
  -e PUID=1002 \
  -e PGID=1002 \
  -e MM_ACCOUNT="xxxxxx" \
  -e MM_LICENSE="xxxxxxxxxxxx" \
  -v $(pwd)/config:/config \
  -v $(pwd)/data:/data \
  k44sh/nginx && \
  docker logs -f nginx
```

### Upgrade

To upgrade, pull the newer image and launch the container:

```shell
docker compose pull
docker compose up -d
```

### Cleanup

```shell
docker compose down -v
rm -rf $(pwd)/{config,data}
```
