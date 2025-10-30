#!/usr/bin/env sh
set -e

TEMPLATE="/etc/nginx/templates/nginx.conf.template"
OUT="/etc/nginx/nginx.conf"

ACTIVE_POOL="${ACTIVE_POOL:-blue}"
PORT="${PORT:-3000}"

# Build upstream server list. We list both servers but we can prefer order or use backup semantics.
# For simplicity: primary server first (based on ACTIVE_POOL), secondary second.
if [ "$ACTIVE_POOL" = "green" ] ; then
  UPSTREAM_SERVERS="server app_green:${PORT};\nserver app_blue:${PORT} backup;"
else
  UPSTREAM_SERVERS="server app_blue:${PORT};\nserver app_green:${PORT} backup;"
fi

# Substitute placeholder __UPSTREAM_SERVERS__ in the template
awk -v servers="$UPSTREAM_SERVERS" '{gsub(/__UPSTREAM_SERVERS__/, servers); print}' "$TEMPLATE" > "$OUT"

echo "[entrypoint] wrote nginx.conf with ACTIVE_POOL=${ACTIVE_POOL}, PORT=${PORT}"
echo "[entrypoint] upstream servers:"
echo -e "$UPSTREAM_SERVERS"

# Start nginx in foreground
exec nginx -g 'daemon off;'
