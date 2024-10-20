#!/usr/bin/with-contenv sh

echo=echo
for cmd in echo /bin/echo; do
	$cmd >/dev/null 2>&1 || continue
	if ! $cmd -e "" | grep -qE '^-e'; then
		echo=$cmd
		break
	fi
done

cli=$($echo -e "\033[")
norm="${cli}0m"
bold="${cli}1;37m"
red="${cli}1;31m"
green="${cli}1;32m"
yellow="${cli}1;33m"
blue="${cli}1;34m"

echo -e "\n${bold}Nginx/PHP Configuration${norm}\n"

# General
GEOIP2_CONF=${GEOIP2_CONF:-/etc/geoip2.conf}
GEOIP2_PATH=${GEOIP2_PATH:-/geoip2}
MM_ACCOUNT=${MM_ACCOUNT:-}
MM_LICENSE=${MM_LICENSE:-}
USER=${USER:-docker}
PORT=${PORT:-8080}
PUID=${PUID:-1000}
PGID=${PGID:-1000}
TZ=${TZ:-America/Toronto}

# PHP
MEMORY_LIMIT=${MEMORY_LIMIT:-512M}
UPLOAD_MAX_SIZE=${UPLOAD_MAX_SIZE:-16M}
CLEAR_ENV=${CLEAR_ENV:-yes}
OPCACHE_MEM_SIZE=${OPCACHE_MEM_SIZE:-256}
MAX_FILE_UPLOADS=${MAX_FILE_UPLOADS:-50}

# Timezone
if [[ ! -z "$TZ" ]]; then
  echo "  ${norm}[${green}+${norm}] Setting timezone to ${green}${TZ}${norm}"
  ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime
  echo ${TZ} > /etc/timezone
fi

# Configuration
echo "  ${norm}[${green}+${norm}] Setting the listening port to ${green}${PORT}${norm}"
sed -i -e "s,@GEOIP2@,${GEOIP2_PATH},g" /etc/nginx/nginx.conf
sed -i -e "s,@PORT@,${PORT},g" /etc/nginx/nginx.conf
sed -i -e "s,@PORT@,${PORT},g" /etc/nginx/conf.d/00-default.conf
sed -i -e "s,@PORT@,${PORT},g" /usr/local/bin/healthcheck
if [[ ! -z "$MM_ACCOUNT" ]] && [[ ! -z "$MM_LICENSE" ]]; then
  echo -e "  ${norm}[${green}+${norm}] Settings GeoIP2 with ${green}${MM_ACCOUNT}${norm}"
  mkdir -p ${GEOIP2_PATH}
  cat > ${GEOIP2_CONF} <<EOL
AccountID ${MM_ACCOUNT}
LicenseKey ${MM_LICENSE}
EditionIDs GeoLite2-ASN GeoLite2-City GeoLite2-Country
EOL
  (sleep 5 && geoipupdate -v -f ${GEOIP2_CONF} -d ${GEOIP2_PATH}) &
fi

# Setting permissions
echo "  ${norm}[${green}+${norm}] Setting user mapping to ${green}${USER} (${PUID}:${PGID})${norm}"
chown ${PUID}:${PGID} /proc/self/fd/1 /proc/self/fd/2 || true
if [ "$PUID" != "1000" ] || [ "$PGID" != "1000" ] || [ "$USER" != "docker" ]; then
  sed -i -e "s/^docker:\([^:]*\):[0-9]*:\([0-9]*\)/${USER}:\1:${PUID}:\2/" /etc/passwd
  sed -i -e "s/^${USER}:\([^:]*\):[0-9]*:\([0-9]*\)/${USER}:\1:${PUID}:${PGID}/" /etc/passwd
  sed -i -e "s/^docker:\([^:]*\):[0-9]*/${USER}:\1:${PGID}/" /etc/group
else
  echo "  ${norm}[${green}+${norm}] No changes needed for user and group"
fi

# Init
echo "  ${norm}[${green}+${norm}] Setting files and folders..."
mkdir -p \
  /etc/nginx/conf.d \
  /var/cache/nginx \
  /var/lib/nginx \
  /var/run/nginx \
  /var/run/php-fpm

# Perms
echo "  ${norm}[${green}+${norm}] Setting user permissions..."
chown -R ${USER}: \
  /var/cache/nginx \
  /var/lib/nginx \
  /var/log/nginx \
  /var/log/php83 \
  /var/run/nginx \
  /var/run/php-fpm \
  #/var/www

# PHP
echo "  ${norm}[${green}+${norm}] Setting PHP-FPM configuration..."
sed -e "s/@MEMORY_LIMIT@/$MEMORY_LIMIT/g" \
    -e "s/@UPLOAD_MAX_SIZE@/$UPLOAD_MAX_SIZE/g" \
    -e "s/@CLEAR_ENV@/$CLEAR_ENV/g" \
    -i /etc/php83/php-fpm.d/www.conf

echo "  ${norm}[${green}+${norm}] Setting PHP INI configuration..."
sed -e "s|memory_limit.*|memory_limit = ${MEMORY_LIMIT}|g" \
    -e "s|;date\.timezone.*|date\.timezone = ${TZ}|g" \
    -e "s|max_file_uploads.*|max_file_uploads = ${MAX_FILE_UPLOADS}|g"  \
    -i /etc/php83/php.ini

# OpCache
echo "  ${norm}[${green}+${norm}] Setting OpCache configuration..."
sed -e "s/@OPCACHE_MEM_SIZE@/$OPCACHE_MEM_SIZE/g" \
    -i /etc/php83/conf.d/opcache.ini

echo -e "  ${norm}[${green}+${norm}] Settings services...\n"
mkdir -p /etc/services.d/nginx
cat > /etc/services.d/nginx/run <<EOL
#!/usr/bin/execlineb -P
with-contenv
s6-setuidgid ${PUID}:${PGID}
nginx -g "daemon off;"
EOL
chmod +x /etc/services.d/nginx/run

mkdir -p /etc/services.d/php-fpm
cat > /etc/services.d/php-fpm/run <<EOL
#!/usr/bin/execlineb -P
with-contenv
s6-setuidgid ${PUID}:${PGID}
php-fpm83 -F
EOL
chmod +x /etc/services.d/php-fpm/run

if [[ ! -z "$MM_ACCOUNT" ]] && [[ ! -z "$MM_LICENSE" ]]; then
  cat > /etc/crontabs/root   <<EOL
0 0 * * * geoipupdate -v -f ${GEOIP2_CONF} -d ${GEOIP2_PATH} >/proc/1/fd/1 2>/proc/1/fd/2
EOL
  mkdir -p /etc/services.d/cron
  cat > /etc/services.d/cron/run <<EOL
#!/usr/bin/execlineb -P
with-contenv
crond -f -l 2
EOL
  chmod +x /etc/services.d/cron/run
fi