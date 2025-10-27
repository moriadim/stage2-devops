#!/bin/sh
set -e

PORT="${PORT:-3000}"
ACTIVE_POOL="${ACTIVE_POOL:-blue}"

# Build upstream server config
if [ "$ACTIVE_POOL" = "blue" ]; then
    PRIMARY="        server app_blue:${PORT} max_fails=2 fail_timeout=3s;"
    BACKUP="        server app_green:${PORT} max_fails=2 fail_timeout=3s backup;"
else
    PRIMARY="        server app_green:${PORT} max_fails=2 fail_timeout=3s;"
    BACKUP="        server app_blue:${PORT} max_fails=2 fail_timeout=3s backup;"
fi

template="/etc/nginx/templates/nginx.conf.template"
config="/etc/nginx/nginx.conf"

# Inject server directives into template
awk -v primary="$PRIMARY" -v backup="$BACKUP" '
    /# Will be replaced by entrypoint.sh based on ACTIVE_POOL/ {
        print primary
        print backup
        next
    }
    { print }
' "$template" > "$config"

# Make sure it worked
if ! grep -q "server app_.*:${PORT}" "$config"; then
    echo "ERROR: config generation failed"
    cat "$config"
    exit 1
fi

echo "nginx config ready (ACTIVE_POOL=$ACTIVE_POOL, PORT=$PORT)"

exec nginx -g 'daemon off;'
