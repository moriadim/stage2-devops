# Blue/Green Setup

Simple setup where nginx automatically switches to backup when primary fails. No failed requests.

## Files

- docker-compose.yml - runs everything
- nginx.conf.template - nginx config
- entrypoint.sh - generates upstream servers based on ACTIVE_POOL
- DEPLOYMENT_RESEARCH.md - Part B research document

## Getting Started

### 1. Create .env file

Copy the example or create your own:

```bash
BLUE_IMAGE=your-registry/blue:tag
GREEN_IMAGE=your-registry/green:tag
ACTIVE_POOL=blue
RELEASE_ID_BLUE=v1.0
RELEASE_ID_GREEN=v1.0
PORT=3000
```

### 2. Start it up

```bash
docker-compose up -d
```

### 3. Test it

```bash
curl http://localhost:8080/version
```

You should see `X-App-Pool: blue` in the headers

## Testing Failover

Here's how to make sure it works:

1. Start breaking Blue:
```bash
curl -X POST http://localhost:8081/chaos/start?mode=error
```

2. Hit the nginx endpoint:
```bash
curl http://localhost:8080/version
```

3. Should now show `X-App-Pool: green` - it switched automatically!

4. Stop breaking stuff:
```bash
curl -X POST http://localhost:8081/chaos/stop
```

## Ports

- http://localhost:8080 - Nginx (main entry)
- http://localhost:8081 - Blue (direct)
- http://localhost:8082 - Green (direct)

## Env Variables

Just set these in `.env`:

- `BLUE_IMAGE` / `GREEN_IMAGE` - your docker images
- `ACTIVE_POOL` - which one is active (blue or green)
- `RELEASE_ID_BLUE` / `RELEASE_ID_GREEN` - whatever IDs you want
- `PORT` - app port (default 3000)

## Switch Active Pool

Want to make green active? Edit `.env`:
```bash
ACTIVE_POOL=green
```

Then:
```bash
docker-compose restart nginx
```

## How It Works

When a request hits nginx, it tries the primary (blue). If that fails or times out (after 1 second), it automatically retries to the backup (green) in the same request. Client still gets a 200.

After Blue fails twice, nginx marks it as down for 3 seconds and routes everything to Green.

## Debugging

```bash
# Check logs
docker-compose logs -f

# Health checks
curl http://localhost:8081/healthz
curl http://localhost:8082/healthz

# Reload nginx (if you change config)
docker-compose exec nginx nginx -s reload
```

## Notes

- Uses pre-built images, no building needed
- Everything is parameterized via `.env`
- Works great in CI/CD
- Total request time during failover stays under 6 seconds
