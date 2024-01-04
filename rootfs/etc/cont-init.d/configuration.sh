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

echo -e "\n${bold}Nginx Configuration${norm}\n"

# General
GEOIP2_CONF=${GEOIP2_CONF:-/etc/geoip2.conf}
GEOIP2_PATH=${GEOIP2_PATH:-/geoip2}
MM_ACCOUNT=${MM_ACCOUNT:-}
MM_LICENSE=${MM_LICENSE:-}
USER=${USER:-nginx}
PORT=${PORT:-8080}
PUID=${PUID:-1000}
PGID=${PGID:-1000}
TZ=${TZ:-UTC}

# Timezone
if [[ ! -z "$TZ" ]]; then
  echo "  ${norm}[${green}+${norm}] Setting timezone to ${green}${TZ}${norm}"
  ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime
  echo ${TZ} > /etc/timezone
fi

# Configuration
echo "  ${norm}[${green}+${norm}] Setting the listening port to ${green}${PORT}${norm}"
sed -i -e "s,@GEOIP2@,${GEOIP2_PATH},g" /etc/nginx/nginx.conf
sed -i -e "s,@PORT@,${PORT},g" /etc/nginx/conf.d/default.conf
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

# Fix permissions
echo "  ${norm}[${green}+${norm}] Setting user mapping to ${green}${USER} (${PUID}:${PGID})${norm}"
chown ${PUID}:${PGID} /proc/self/fd/1 /proc/self/fd/2 || true
if [ -n "${PGID}" ] && [ "${PGID}" != "$(id -g ${USER})" ]; then
  sed -i -e "s/^${USER}:\([^:]*\):[0-9]*/${USER}:\1:${PGID}/" /etc/group
  sed -i -e "s/^${USER}:\([^:]*\):\([0-9]*\):[0-9]*/${USER}:\1:\2:${PGID}/" /etc/passwd
fi
if [ -n "${PUID}" ] && [ "${PUID}" != "$(id -u ${USER})" ]; then
  sed -i -e "s/^${USER}:\([^:]*\):[0-9]*:\([0-9]*\)/${USER}:\1:${PUID}:\2/" /etc/passwd
fi

# Permissions
echo "  ${norm}[${green}+${norm}] Setting files and folders permissions"
mkdir -p /var/cache/nginx
chown -R ${USER}: \
  /var/cache/nginx \
  /var/lib/nginx \
  /var/log/nginx \
  /var/run/nginx \
  ${SSL_PATH}

# Services
echo -e "  ${norm}[${green}+${norm}] Settings services\n"
mkdir -p /etc/services.d/nginx
cat > /etc/services.d/nginx/run <<EOL
#!/usr/bin/execlineb -P
with-contenv
s6-setuidgid ${PUID}:${PGID}
nginx -g "daemon off;"
EOL
chmod +x /etc/services.d/nginx/run
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
