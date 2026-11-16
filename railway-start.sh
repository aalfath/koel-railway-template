#!/bin/sh
# Railway start script for Koel. Runs as root, then hands over to the image's own entrypoint chain.
set -e

PORT="${PORT:-80}"
DATA_DIR="${KOEL_DATA_DIR:-/data}"

# Fixed settings for a single-container Koel behind Railway's HTTPS proxy.
export APP_ENV="${APP_ENV:-production}"
export APP_DEBUG="${APP_DEBUG:-false}"
export FORCE_HTTPS="${FORCE_HTTPS:-true}"
export TRUSTED_PROXIES="${TRUSTED_PROXIES:-*}"
export DB_CONNECTION="${DB_CONNECTION:-pgsql}"
export MEDIA_PATH="${MEDIA_PATH_OVERRIDE:-$DATA_DIR/music}"
export LOG_CHANNEL="${LOG_CHANNEL:-stderr}"

if [ -z "$APP_KEY" ]; then
  echo "APP_KEY is not set. Set it to base64:<44 chars> (the template generates one)." >&2
  exit 1
fi

# Apache listens on Railway's PORT.
sed -i "s/^Listen .*/Listen ${PORT}/" /etc/apache2/ports.conf
sed -i "s/<VirtualHost \*:[0-9]*>/<VirtualHost *:${PORT}>/" /etc/apache2/sites-available/000-default.conf

# Everything that must survive a redeploy lives on the volume at $DATA_DIR.
mkdir -p "$DATA_DIR/music" "$DATA_DIR/images" "$DATA_DIR/search-indexes"
chown www-data:www-data "$DATA_DIR" "$DATA_DIR/music" "$DATA_DIR/images" "$DATA_DIR/search-indexes"

link_to_volume() {
  # $1 = path inside the app, $2 = target on the volume
  if mountpoint -q "$1" 2>/dev/null; then
    echo "$1 is a separate mount, leaving it as is"
    return
  fi
  if [ ! -L "$1" ]; then
    if [ -d "$1" ] && [ -n "$(ls -A "$1" 2>/dev/null)" ]; then
      cp -an "$1"/. "$2"/ || true
      chown -R www-data:www-data "$2"
    fi
    rm -rf "$1"
    ln -s "$2" "$1"
    chown -h www-data:www-data "$1"
  fi
}
link_to_volume /var/www/html/storage/app/public/images "$DATA_DIR/images"
link_to_volume /var/www/html/storage/search-indexes "$DATA_DIR/search-indexes"

# An (empty) .env makes the image's koel-init run the full `koel:init`
# (migrations, first admin, media path, scheduler). All settings still come from the environment.
cd /var/www/html
[ -f .env ] || { touch .env; chown www-data:www-data .env; }

su -s /bin/sh -c /usr/local/bin/koel-init www-data

# Replace the upstream default admin password (KoelIsCool) before the web server starts.
su -s /bin/sh -c "php /usr/local/bin/railway-admin.php" www-data

# Koel's scheduler (daily library scan, podcast sync) runs from www-data's crontab.
if command -v cron >/dev/null 2>&1; then
  cron || echo "cron did not start; scheduled scans are disabled" >&2
fi

echo "Starting Koel on port ${PORT}"
exec docker-php-entrypoint "$@"
