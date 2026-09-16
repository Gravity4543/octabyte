# Approach

This document explains how I approached each part of the assignment and the reasoning
behind the main decisions.

## Overall strategy

I treated this as four connected pieces: infrastructure first (everything else deploys
onto it), then the application and its pipeline, then monitoring, then documentation. I
kept cost low throughout since that was a stated priority, and I made deliberate tradeoffs
(documented below and in the README) rather than reaching for the most "complete" option
every time.

The app is a readymade Express todo project. Since the assignment says application logic
isn't important, I focused effort on the DevOps concerns but did extend the app in a few
small, honest ways that make the infrastructure meaningful:
- added a `/health` endpoint for the ALB and monitoring,
- wired it to persist tasks in PostgreSQL (so RDS, DB metrics, backups and secrets are all real, not decorative),
- exported the app and wrote a test that exercises the real routes (the original test tested a fake app),
- bumped the base image off the end-of-life `node:16`.

## Part 1 — Infrastructure (Terraform)

I split the infrastructure into small modules (`vpc`, `security`, `database`, `compute`,
`alb`, `ecr`) wired together by a root module, with a separate `bootstrap` step that
creates the S3 state bucket and DynamoDB lock table (the classic backend chicken-and-egg).

Key decisions:
- **Environment strategy**: staging and production run as two containers on one app
  instance, on different ports, from the same image, with separate databases on a shared
  RDS instance. This is the biggest cost saver and the deploy path is written so promoting
  prod to its own instance later is trivial. (More detail in the README.)
- **SSM over SSH**: no port 22 anywhere; instance access and deploys go through SSM.
- **NAT disabled**: RDS is the only private resource and needs no egress, so I dropped the
  NAT gateway and saved ~$32/mo.
- **State**: remote state in S3 with DynamoDB locking, encrypted, versioned.

Security groups encode explicit relationships (ALB → app, app/monitoring → RDS,
monitoring → exporters) rather than broad rules. Secrets Manager holds the generated DB
password; RDS has automated backups.

## Part 2 — CI/CD (Jenkins)

I used Jenkins because it was already available. The pipeline runs tests on every branch
and, on `main`, builds and scans the image, pushes to ECR, deploys to staging, waits for
a manual approval, then deploys to production.

Choices worth calling out:
- **Docker-agent for tests**: the test stage runs inside a `node:20` container so CI uses
  the same runtime as local, with nothing language-specific installed on the Jenkins host.
- **SSM for deploys**: a small wrapper script ships the compose/deploy files to the app
  instance and runs them via `aws ssm send-command` — consistent with the no-SSH design.
- **Vulnerability scanning**: Trivy scans both dependencies (filesystem) and the built
  image. The dependency scan is report-only; the image scan is report-only too, because the
  findings are almost entirely CVEs in the base image's bundled OS/npm packages rather than
  our app dependencies (our app deps scan clean). In production I'd rebuild/pin the base and
  make the image scan blocking.
- **Auth via instance role**: Jenkins runs on EC2 with an IAM role, so no AWS keys are
  stored; the account id and ECR registry are derived at runtime with STS.
- **Notifications**: email on failure via Jenkins SMTP.

## Part 3 — Monitoring & logging

Self-hosted, all open-source, on a dedicated monitoring instance:
- **Prometheus** scrapes `node_exporter` (host CPU/mem/disk) and `cAdvisor` (containers) on
  the app box, plus `postgres_exporter` for database metrics.
- **Grafana** shows two dashboards (infrastructure overview, application & database),
  provisioned from JSON in the repo so they load automatically.
- **Loki + Promtail** provide centralized logging — Promtail on the app box ships container
  logs (application + access) and system logs to Loki, viewable in Grafana.

I left alerting out of scope on purpose: Part 3 asks for metrics, logging and dashboards,
not alerting. If needed, Grafana's built-in alerting would route to the same channel used
for CI failures.

## Part 4 — Documentation & best practices

The README covers setup, architecture decisions, security and cost. Both optional best
practices are implemented: secret management (Secrets Manager) and a backup strategy (RDS
automated backups). Screenshots from a live run are included as evidence, and this file
plus `CHALLENGES.md` complete the required approach and challenges documentation.

## What I'd add with more time

- Expose real application metrics from the app (a `/metrics` endpoint via `prom-client`) for
  true request-rate/latency/error dashboards instead of using container metrics as a proxy.
- Scope the Terraform execution role to least privilege instead of admin.
- Separate staging and production onto their own instances (or accounts) for real isolation.
- Add Grafana alert rules and pin/rebuild the container base image so the image scan can block.
