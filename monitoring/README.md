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

## Deploy (on the monitoring instance)

The app instance private IP and the DB DSN are injected at deploy time.

```bash
# on the monitoring instance, in the monitoring/ directory
export APP_PRIVATE_IP=10.0.1.x            # terraform output app_private_ip
export PG_DSN="postgresql://appadmin:PASS@RDS_HOST:5432/appdb?sslmode=require"
export GRAFANA_PASSWORD=choose-a-password

# Prometheus does not expand env vars in its config, so render it first:
envsubst < prometheus/prometheus.yml > prometheus/prometheus.rendered.yml
mv prometheus/prometheus.rendered.yml prometheus/prometheus.yml

docker compose up -d
```

Grafana: `http://<monitoring_public_ip>:3000` (admin / $GRAFANA_PASSWORD).
Prometheus: `http://<monitoring_public_ip>:9090`.
Both are restricted to `admin_cidr` by the security group.

## Deploy Promtail (on the app instance)

```bash
# in /opt/app on the app instance
export LOKI_HOST=10.0.1.y                  # monitoring instance private IP
docker compose -f docker-compose.promtail.yml up -d
```

Promtail uses `-config.expand-env=true`, so `${LOKI_HOST}` is resolved at runtime.

## Notes / scope

- **Alerting** is intentionally out of scope: Part 3 asks for metrics, logging, and
  dashboards only. If needed, Grafana's built-in alerting would route threshold
  breaches to the same Slack channel used for CI failures.
- postgres_exporter uses the RDS master credentials for simplicity; a read-only
  monitoring role would be the hardening step in production.
