#!/usr/bin/env python3
import os
import re
import sys
import time
import json
import io
from collections import deque
from datetime import datetime
import requests

# =============================
# Configuration from Environment
# =============================
SLACK_WEBHOOK_URL = os.getenv('SLACK_WEBHOOK_URL')
ERROR_RATE_THRESHOLD = float(os.getenv('ERROR_RATE_THRESHOLD', '2'))  # percent
WINDOW_SIZE = int(os.getenv('WINDOW_SIZE', '200'))
ALERT_COOLDOWN_SEC = int(os.getenv('ALERT_COOLDOWN_SEC', '300'))
MAINTENANCE_MODE = os.getenv('MAINTENANCE_MODE', 'false').lower() in ('1', 'true', 'yes')

# =============================
# Internal State
# =============================
last_alert_time = {
    'failover': None,
    'error_rate': None,
}
window = deque(maxlen=WINDOW_SIZE)
last_pool = None

# =============================
# Regex for key=value log parsing
# =============================
KV_RE = re.compile(r'([a-zA-Z_]+)=(".*?"|[^"\s]+)')

def parse_line(line):
    """Extract structured info from log line."""
    data = {}
    for m in KV_RE.finditer(line):
        key, val = m.group(1), m.group(2)
        val = val.strip('"')
        data[key] = val
    return {
        'pool': data.get('pool'),
        'release': data.get('release'),
        'upstream_status': data.get('upstream_status') or data.get('status'),
        'upstream_addr': data.get('upstream_addr'),
        'request_time': data.get('request_time'),
        'upstream_response_time': data.get('upstream_response_time'),
        'raw': line.strip()
    }

# =============================
# Slack Notification
# =============================
def send_slack(text, attachments=None):
    if not SLACK_WEBHOOK_URL:
        print("[watcher] SLACK_WEBHOOK_URL not configured; skipping alert.")
        return
    payload = {'text': text}
    if attachments:
        payload['attachments'] = attachments
    try:
        r = requests.post(SLACK_WEBHOOK_URL, json=payload, timeout=5)
        r.raise_for_status()
        print(f"[watcher] alert sent: {text}")
    except Exception as e:
        print(f"[watcher] failed to send slack alert: {e}")

# =============================
# Alert Cooldown Management
# =============================
def should_cooldown(alert_type):
    t = last_alert_time.get(alert_type)
    if t is None:
        return False
    return (datetime.utcnow() - t).total_seconds() < ALERT_COOLDOWN_SEC

def mark_alert(alert_type):
    last_alert_time[alert_type] = datetime.utcnow()

# =============================
# Error Rate Monitoring
# =============================
def check_error_rate():
    if len(window) == 0:
        return None
    errors = 0
    total = len(window)
    for item in window:
        st = item.get('upstream_status')
        if st and st.isdigit():
            code = int(st)
            if 500 <= code <= 599:
                errors += 1
    rate = (errors / total) * 100.0
    return rate, total, errors

# =============================
# Safe Tail-F Implementation
# =============================
def tail_f(path):
    """Stream lines from a log file, handling non-seekable inputs gracefully."""
    while not os.path.exists(path):
        print(f"[watcher] waiting for log file: {path}")
        time.sleep(2)

    print(f"[watcher] starting to tail: {path}")
    with open(path, "r", errors="ignore") as f:
        try:
            f.seek(0, os.SEEK_END)
            print("[watcher] seeked to end")
        except io.UnsupportedOperation:
            print("[watcher] stream not seekable; reading from start")

        while True:
            line = f.readline()
            if not line:
                time.sleep(0.5)
                continue
            yield line

# =============================
# Main Watcher Loop
# =============================
def main(log_path):
    global last_pool, MAINTENANCE_MODE
    print("[Watcher] Starting log monitoring service...", flush=True)

    if not os.path.exists(log_path):
        print(f"[watcher] log file does not exist: {log_path}")
        sys.exit(1)

    print(f"[watcher] starting, watching {log_path}")

    for line in tail_f(log_path):
        # Allow live update of maintenance mode
        MAINTENANCE_MODE = os.getenv('MAINTENANCE_MODE', 'false').lower() in ('1', 'true', 'yes')

        print(f"[Watcher] New log line detected: {line.strip()}")
        parsed = parse_line(line)
        pool = parsed.get('pool')
        upstream_status = parsed.get('upstream_status')
        print(f"[Watcher] Parsed pool={pool}, status={upstream_status}")

        window.append(parsed)

        # =============================
        # Detect Pool Failover
        # =============================
        if pool and last_pool and pool != last_pool:
            if MAINTENANCE_MODE:
                print(f"[watcher] maintenance mode ON - suppressing failover alert ({last_pool} -> {pool})")
            else:
                if not should_cooldown('failover'):
                    text = f":rotating_light: *Failover detected* — pool changed from *{last_pool}* → *{pool}*"
                    attachments = [{
                        'fallback': 'Failover Detected',
                        'fields': [
                            {'title': 'From', 'value': last_pool, 'short': True},
                            {'title': 'To', 'value': pool, 'short': True},
                            {'title': 'Recent Release', 'value': parsed.get('release') or 'unknown', 'short': True},
                            {'title': 'Upstream', 'value': parsed.get('upstream_addr') or 'unknown', 'short': True},
                            {'title': 'Time', 'value': datetime.utcnow().isoformat() + 'Z', 'short': True},
                        ]
                    }]
                    send_slack(text, attachments)
                    mark_alert('failover')
                else:
                    print("[watcher] failover alert suppressed due to cooldown")

        # =============================
        # Check Error Rate Periodically
        # =============================
        if len(window) > 0 and len(window) % 10 == 0:
            result = check_error_rate()
            if result:
                rate, total, errors = result
                if rate >= ERROR_RATE_THRESHOLD:
                    if MAINTENANCE_MODE:
                        print("[watcher] maintenance mode ON - suppressing error rate alert")
                    else:
                        if not should_cooldown('error_rate'):
                            text = f":warning: *High upstream 5xx rate* — {rate:.2f}% 5xx over last {total} requests ({errors} errors). Threshold: {ERROR_RATE_THRESHOLD}%"
                            attachments = [{
                                'fallback': 'High error rate',
                                'fields': [
                                    {'title': 'Window', 'value': str(total), 'short': True},
                                    {'title': 'Errors', 'value': str(errors), 'short': True},
                                    {'title': 'Threshold (%)', 'value': str(ERROR_RATE_THRESHOLD), 'short': True},
                                    {'title': 'Last Pool', 'value': last_pool or 'unknown', 'short': True},
                                    {'title': 'Time', 'value': datetime.utcnow().isoformat() + 'Z', 'short': True},
                                ]
                            }]
                            send_slack(text, attachments)
                            mark_alert('error_rate')
                        else:
                            print("[watcher] error_rate alert suppressed due to cooldown")

        # =============================
        # Update Last Pool
        # =============================
        if pool:
            last_pool = pool

# =============================
# Entrypoint
# =============================
if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: watcher.py /path/to/access.log")
        sys.exit(2)
    log_path = sys.argv[1]
    main(log_path)
