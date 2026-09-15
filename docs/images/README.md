# Screenshots

Drop screenshots here using the naming convention below. They are referenced
from the root `README.md`, `APPROACH.md`, and `monitoring/README.md`, and render
automatically on GitHub.

Keep the numeric prefix so ordering and placement stay predictable. PNG preferred.

| File | What to capture |
|------|-----------------|
| `01-terraform-apply.png`        | `terraform apply` completing (Apply complete! ... resources added) |
| `02-ec2-instances-running.png`  | EC2 console: app + monitoring instances running |
| `03-rds-created.png`            | RDS console: PostgreSQL instance available |
| `04-alb-app-running.png`        | Browser hitting the ALB DNS, app page loads |
| `05-ecr-image.png`              | ECR console: pushed image with tag |
| `06-jenkins-pipeline.png`       | Jenkins pipeline stage view, all green |
| `07-jenkins-approval.png`       | The manual "Deploy to production?" input prompt |
| `08-grafana-infra.png`          | Grafana "Infrastructure Overview" dashboard with data |
| `09-grafana-app-db.png`         | Grafana "Application & Database" dashboard with data |
| `10-loki-logs.png`              | Grafana Explore / logs panel showing app + system logs |
| `11-ssm-session.png`            | `aws ssm start-session` connected to an instance (proves no SSH) |

If you name a file differently or capture extra ones, note what each shows and
the doc references can be updated to match.
