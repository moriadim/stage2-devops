# watcher/Dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --default-timeout=100 -r requirements.txt

COPY watcher.py .

# This log directory will be shared with the nginx container
RUN mkdir -p /var/log/nginx
VOLUME ["/var/log/nginx"]

CMD ["python", "watcher.py", "/var/log/nginx/access.log"]

