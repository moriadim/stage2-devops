Runbook — Stage 3 Observability & Alerts
Summary

This runbook guides operators on understanding and responding to alerts from the log-watcher. It covers failover detection, high upstream error rates, and maintenance procedures.

Alert Types
1. Failover Detected

What it means: The watcher detected a change in the active pool (e.g., blue → green). This usually signals a failover, either automatic due to failure or a manual traffic switch.

Immediate actions:

Check recent Nginx access logs (/var/log/nginx/access.log or docker logs nginx_proxy) for lines with pool= and upstream_status=.

Inspect containers:

docker ps
docker logs app_blue
docker logs app_green


Look for crashes, errors, or abnormal behavior.

Verify health endpoints:

curl http://<container>:<port>/healthz


If the primary is unhealthy, investigate logs, resource usage, or restart the container.

If the switch was planned, enable maintenance mode to suppress alerts:

MAINTENANCE_MODE=true


Then restart alert_watcher.

2. High Upstream 5xx Rate

What it means: The fraction of upstream 5xx responses over the last WINDOW_SIZE requests exceeded the threshold ERROR_RATE_THRESHOLD.

Immediate actions:

Identify the affected pool using pool= in the logs.

Inspect container logs for stack traces, resource issues, or recent deployments (release field in logs).

Consider:

Failing over traffic to the other pool.

Rolling back the suspect release.

Scaling the service or applying fixes.

Verify error rates return below threshold before resuming normal operations.

Maintenance Mode

Purpose: Suppress alerts during planned toggles, load tests, or deployments.

How to enable:

Edit .env:

MAINTENANCE_MODE=true


Restart the watcher container:

docker restart alert_watcher

Troubleshooting

No Slack alerts despite errors:

Check that SLACK_WEBHOOK_URL is valid and the watcher container has internet access.

Verify logs: docker logs alert_watcher.

Structured fields missing in logs:

Ensure Nginx configuration is generated from nginx.conf.template.

Confirm headers X-App-Pool and X-Release-Id are being set and forwarded correctly.