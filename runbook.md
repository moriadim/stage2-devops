# Runbook — Stage 3 Observability & Alerts

## Summary
This runbook describes the alerts produced by the log-watcher and how operators should respond.

### Alert types

1. **Failover detected**
   - **What it means:** The watcher observed requests served by a different pool than the last-seen pool (e.g., `blue -> green`). Usually indicates a failover or traffic switch.
   - **Immediate action:**
     1. Inspect the recent `/var/log/nginx/access.log` (or `docker logs nginx_proxy`) to see lines showing `pool=` and `upstream_status=` fields.
     2. Check `docker ps` and `docker logs` for `app_blue` and `app_green` to identify errors or crashes.
     3. Verify health endpoints (`/healthz`). If primary is unhealthy, investigate application logs, resource usage, or restart container.
     4. If the toggle was planned, set `MAINTENANCE_MODE=true` in `.env` for the `alert_watcher` to suppress alerts during maintenance.

2. **High upstream 5xx rate**
   - **What it means:** Over the last `WINDOW_SIZE` requests the fraction of 5xx upstream responses exceeded `ERROR_RATE_THRESHOLD` (%).
   - **Immediate action:**
     1. Identify which pool is causing errors via the `pool=` field in logs.
     2. Inspect upstream container logs for stack traces, resource exhaustion, or recent deployments (check `release` in logs).
     3. Consider failing over to the other pool or rolling back the suspect release.
     4. Increase capacity or apply fixes as needed; once stable, verify error rate drops below threshold.

## Maintenance mode
Set `MAINTENANCE_MODE=true` for the `alert_watcher` (then restart that container) to suppress alerts while performing planned toggles or load tests.

## Troubleshooting
- **No Slack alerts despite conditions:** Ensure `SLACK_WEBHOOK_URL` is valid and the watcher container has egress to Slack. Check `docker logs alert_watcher`.
- **Logs missing structured fields:** Verify nginx uses `nginx.conf` generated from `nginx.conf.template` (entrypoint writes it) and that clients set `X-App-Pool` / `X-Release-Id` as expected.

