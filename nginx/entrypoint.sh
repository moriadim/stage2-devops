#!/bin/sh
set -e

ACTIVE_POOL=${ACTIVE_POOL:-app_blue}
echo "Active pool: ${ACTIVE_POOL}"

# Replace variable in nginx template
envsubst '${ACTIVE_POOL}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

# Validate configuration
nginx -t

# Start nginx in the foreground
exec nginx -g 'daemon off;'
