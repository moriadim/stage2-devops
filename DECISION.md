# Implementation Decisions

## Overview
Blue/Green deployment with nginx automatic failover.

## Why This Approach

### Nginx upstream with backup
Using nginx's built-in backup directive means you get automatic failover without writing custom health checks. When the primary fails 2 times within 3 seconds, nginx automatically routes to backup. The retry logic happens within the same request so clients get 200 responses even during failover.

### Fast timeouts
1 second timeouts (connect, send, read) so failures are detected quickly. Total request time stays under 6 seconds even with retries, well under the 10 second requirement.

### entrypoint.sh script
The entrypoint dynamically generates the nginx upstream config based on ACTIVE_POOL. This lets you switch which pool is active just by changing an env var and restarting nginx.

### Keep it simple
No health check services or sidecars. Just nginx, blue, green. Everything in one docker-compose file. Easy to understand and debug.

## Trade-offs

Could have used more complex setups with consul for service discovery, or kubernetes with readiness probes. But for this use case, nginx upstreams with backup is simpler and works fine.

Could have built a custom health check container. But nginx already handles this with max_fails and fail_timeout. No need to overcomplicate.

## Testing

The test scripts just use curl. No fancy testing frameworks needed. If curl works, the deployment works.

## What Didn't Work

First tried to use nginx's default health check but it wasn't fast enough. Had to tune max_fails and fail_timeout to get the right behavior.

Started with longer timeouts (2-3 seconds) but that didn't meet the 10 second total request time requirement. Had to tighten to 1 second per phase.

