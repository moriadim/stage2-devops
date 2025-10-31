# Stage 2 & Stage 3 DevOps – Blue/Green Deployment with Observability & Alerts

Hey Cool Keeds! 👋 Welcome to the Stage 2 & 3 setup for Blue/Green deployment monitoring using Nginx, Docker Compose, and a Python log-watcher. This project gives you a hands-on environment for automatic failover, operational visibility, and Slack alerts for upstream errors.

---

## **Overview**

This setup builds on Stage 2 by adding **observability and alerting**:

- Nginx logs record which pool served each request and relevant metrics.
- A Python log-watcher tails these logs in real-time.
- Alerts are sent to Slack when:
  - Failovers occur (Blue → Green or Green → Blue)
  - Upstream 5xx error rates exceed thresholds
- Configurable via environment variables in `.env`.

---

## **Architecture**

```text
       ┌─────────┐        ┌─────────┐
       │ app_blue│        │ app_green│
       └─────┬───┘        └─────┬───┘
             │                 │
             └─────┐   ┌───────┘
                   │   │
              ┌────▼───▼─────┐
              │   Nginx      │
              │  (reverse    │
              │   proxy)     │
              └─────┬────────┘
                    │
             ┌──────▼────────┐
             │ alert_watcher │
             │  (Python)     │
             └──────┬────────┘
                    │
                    ▼
                Slack Channel
Setup Instructions
Clone the repository

bash
Copier le code
git clone https://github.com/<username>/stage2-devops.git
cd stage2-devops
Create .env file

bash
Copier le code
cp .env.example .env
Edit .env to set:

SLACK_WEBHOOK_URL → Slack incoming webhook URL

ACTIVE_POOL → Initial active pool (blue or green)

ERROR_RATE_THRESHOLD → 5xx threshold for alerts (default 2%)

WINDOW_SIZE → Sliding window for error rate calculation (default 200)

ALERT_COOLDOWN_SEC → Cooldown between alerts (default 300s)

Start the stack

bash
Copier le code
docker-compose up -d
Simulate traffic & chaos

Baseline traffic: curl http://localhost:8080/version

Inject chaos to test failover:

bash
Copier le code
curl -X POST http://localhost:8081/chaos/start
Stop chaos:

bash
Copier le code
curl -X POST http://localhost:8081/chaos/stop
Verify Slack alerts

Failover alert: Blue → Green or Green → Blue

Error rate alert: triggered if 5xx errors exceed threshold

bash
Copier le code
docker logs -f alert_watcher
View Nginx logs

bash
Copier le code
tail -f ./logs/nginx/test_access.log
Logs show: pool, release, upstream_status, upstream_addr, request_time, upstream_response_time.

File Structure
cpp
Copier le code
.
├── docker-compose.yml
├── nginx.conf.template
├── watcher.py
├── requirements.txt
├── .env.example
├── README.md
├── runbook.md
└── logs/
Notes
No changes were made to the app images.

All work is done through Nginx configuration, Docker Compose, environment variables, and the log-watcher.

Alerts are rate-limited and deduplicated to avoid Slack spam.

The system is safe to run in local dev or cloud staging.

Stage 2 Verification
Baseline: Blue is active, all requests succeed.

Chaos: Blue fails, Green automatically takes over.

Failover: Verify /version endpoint returns correct headers:

X-App-Pool: blue or green

X-Release-Id: corresponding release ID

Stage 3 Verification
Log-watcher posts alerts to Slack on:

Failover

High 5xx error rate

Alerts include:

Previous & current pool

Upstream addresses

Release IDs

Sample log lines for troubleshooting

References
Explainer Video

Nginx Logging & Upstream Docs

Slack Incoming Webhooks