# Monitoring & Logging

Self-hosted, open-source stack. No paid services.

| Component | Role | Runs on |
|-----------|------|---------|
| Prometheus | metrics store + scraper | monitoring instance |
| Grafana | dashboards | monitoring instance |
| Loki | log store | monitoring instance |
| postgres_exporter | RDS metrics | monitoring instance |
| node_exporter | host CPU/mem/disk | app instance (user-data) |
| cAdvisor | container metrics | app instance (user-data) |
| Promtail | ships logs to Loki | app instance |

## How requirements are covered

- **Infrastructure metrics** (CPU/memory/disk): node_exporter -> Prometheus -> "Infrastructure Overview" dashboard.
- **Application metrics** (rate/errors/latency): cAdvisor container metrics + app logs. Container network/CPU/memory act as request-activity proxies for this simple app.
- **Database metrics**: postgres_exporter (connections, DB size, pg_up) -> "Application & Database" dashboard.
- **Centralized logging**: Promtail on the app instance ships Docker container logs (application + Express access logs on stdout) and system logs (`/var/log`) to Loki. Viewable in Grafana (Explore + the logs panel).
- **Two dashboards**: `grafana/dashboards/infra-overview.json` and `grafana/dashboards/app-db-metrics.json`, auto-provisioned.

## Deploy — the monitoring stack is deployed manually (one-time)

Unlike the app (which Jenkins deploys automatically), the monitoring stack is a one-time
manual setup. Because no instance exposes SSH, I connect with **SSM Session Manager** and
pull the config files from the artifacts S3 bucket. This keeps the whole thing consistent
with the no-SSH design.

**1. Upload the config to S3 (from a machine with the repo):**
```bash
aws s3 cp monitoring/ s3://octabyte-devops-artifacts/monitoring/ --recursive
aws s3 cp deploy/     s3://octabyte-devops-artifacts/deploy/     --recursive
```

**2. Connect to the monitoring instance over SSM (no SSH):**
```bash
aws ssm start-session --target <monitoring_instance_id> --region ap-south-1
```

**3. On the instance, pull the config and start the stack:**
```bash
sudo su - ec2-user
cd /opt/monitoring
aws s3 cp s3://octabyte-devops-artifacts/monitoring/ . --recursive

export APP_PRIVATE_IP=10.0.1.x            # terraform output app_private_ip
export PG_DSN="postgresql://appadmin:PASS@RDS_HOST:5432/appdb?sslmode=require"
export GRAFANA_PASSWORD=password


docker compose up -d
```

Grafana: `http://<monitoring_public_ip>:3000` (admin / $GRAFANA_PASSWORD).
Prometheus: `http://<monitoring_public_ip>:9090`.
Both are restricted to `admin_cidr` by the security group.

## Deploy Promtail (on the app instance)

Same pattern — SSM onto the app box and pull the two files from S3:
```bash
aws ssm start-session --target <app_instance_id> --region ap-south-1
```
```bash
sudo su - ec2-user
cd /opt/app
aws s3 cp s3://octabyte-devops-artifacts/deploy/promtail-config.yml .
aws s3 cp s3://octabyte-devops-artifacts/deploy/docker-compose.promtail.yml .

export LOKI_HOST=10.0.1.y                  # monitoring instance private IP
docker compose -f docker-compose.promtail.yml up -d
```

Promtail uses `-config.expand-env=true`, so `${LOKI_HOST}` is resolved at runtime.

## Notes / scope

- **Alerting** is intentionally out of scope: Part 3 asks for metrics, logging, and
  dashboards only. If needed, Grafana's built-in alerting would route threshold.
- postgres_exporter uses the RDS master credentials for simplicity; a read-only
  monitoring role would be the hardening step in production.
