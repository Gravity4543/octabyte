#!/bin/bash
set -euxo pipefail

dnf update -y
# docker for the app, jq + psql for the deploy script
dnf install -y docker jq postgresql15

# compose v2 plugin
mkdir -p /usr/local/lib/docker/cli-plugins
curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 \
  -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

systemctl enable --now docker
usermod -aG docker ec2-user

# Jenkins drops the compose + env files here via SSM
mkdir -p /opt/app
chown ec2-user:ec2-user /opt/app

# exporters the monitoring box scrapes
# host metrics on :9100
docker run -d --name node_exporter --restart unless-stopped \
  --net host --pid host \
  -v /:/host:ro,rslave \
  quay.io/prometheus/node-exporter:latest \
  --path.rootfs=/host

# container metrics - map to 9323 so it doesn't clash with the app
docker run -d --name cadvisor --restart unless-stopped \
  -p 9323:8080 \
  -v /:/rootfs:ro \
  -v /var/run:/var/run:ro \
  -v /sys:/sys:ro \
  -v /var/lib/docker/:/var/lib/docker:ro \
  gcr.io/cadvisor/cadvisor:latest

echo "app bootstrap done"
