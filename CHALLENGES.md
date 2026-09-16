# Challenges & Resolutions

Real problems hit during the assignment and how I resolved them. Most of these only
surfaced at apply/run time, which is exactly why the end-to-end run mattered.

## 1. Instances launched from the "minimal" AL2023 AMI — no SSM agent

**Symptom:** After a fresh apply, both EC2 instances showed `TargetNotConnected` and never
registered with SSM, so Session Manager and pipeline deploys couldn't reach them. IAM,
routing, egress and DNS all checked out.

**Cause:** the AMI data source filtered on `al2023-ami-*-x86_64` with `most_recent = true`,
which matched the **minimal** AL2023 image on this apply. The minimal variant does not ship
the SSM agent preinstalled.

**Fix:** pinned the filter to the standard image (`al2023-ami-2023.*-x86_64`). Re-applied,
instances registered, Session Manager worked.

## 2. Terraform plan passed but apply failed on the Postgres version

**Symptom:** `terraform apply` failed with `Cannot find version 16.4 for postgres`, even
though `plan` had succeeded.

**Cause:** `plan` doesn't validate engine versions against the region; only the real
`CreateDBInstance` call does. Postgres 16.4 had been deprecated in `ap-south-1`.

**Fix:** queried `aws rds describe-db-engine-versions` for available 16.x versions and
pinned `16.9`.

## 3. Secrets Manager name conflict on re-apply

**Symptom:** after a destroy + re-apply, creating the DB secret failed:
`a secret with this name is already scheduled for deletion`.

**Cause:** Secrets Manager schedules secrets for deletion with a recovery window instead of
removing them immediately, so the name was still reserved.

**Fix:** force-deleted the pending secret, and set `recovery_window_in_days = 0` on the
resource so this ephemeral environment tears down cleanly on future destroys.

## 4. Cancelled apply left a stuck state lock + orphaned RDS

**Symptom:** I cancelled an apply during the (slow) RDS creation; the next command reported
the state was locked, and the RDS instance had actually been created on AWS but wasn't in
state.

**Fix:** released the lock with `terraform force-unlock`, then `terraform import`ed the
existing RDS instance so state matched reality, and re-applied (which only added the
remaining secret version). Lesson: don't cancel during RDS operations.

## 5. App folder committed as a git submodule

**Symptom:** the first Jenkins run failed at `npm ci` with "no package-lock.json". GitHub
showed the app folder as an empty submodule link.

**Cause:** the cloned app kept its own `.git`, so when I pushed, git recorded it as a
submodule reference (mode 160000) instead of the actual files.

**Fix:** removed the nested `.git`, `git rm --cached` the submodule entry, and re-added the
folder as normal tracked files.

## 6. Deploy script not executable

**Symptom:** Deploy Staging failed with `Permission denied` (exit 126) running
`./ci/scripts/ssm-deploy.sh`.

**Fix:** invoked it via `bash ci/scripts/ssm-deploy.sh` and marked the shell scripts
executable in git (`git update-index --chmod=+x`).

## 7. Production compose filename mismatch

**Symptom:** staging deployed fine, but Deploy Production failed with
`docker-compose.production.yml: No such file or directory`.

**Cause:** the deploy script builds the filename from the environment name
(`docker-compose.$ENV.yml`, so `production`), but the file was named `docker-compose.prod.yml`.

**Fix:** renamed it to `docker-compose.production.yml` so staging and production use a
consistent naming scheme.

## 8. ECR repo blocked `terraform destroy`

**Symptom:** destroy failed because the ECR repository still contained pushed images.

**Fix:** added `force_delete = true` to the ECR repository so Terraform can remove it with
its images (and deleted the repo directly to unblock the immediate teardown).

## 9. Monitoring instance ran out of memory

**Symptom:** running the full monitoring stack (Prometheus + Grafana + Loki +
postgres_exporter) on a `t3.micro` (1 GB) made the box unresponsive.

**Cause:** the combined stack needs more than 1 GB.

**Fix:** rebooted to recover, and noted the proper remedies.
Takeaway: monitoring infrastructure needs right-sizing too.

## Minor notes

- **Jenkins wouldn't start** on the new instance: the current Jenkins release requires Java
  21+, and the box had Java 17. Installed `java-21-amazon-corretto` and pointed Jenkins at it.
- **Email SMTP timeout**: a wrong port/SSL combination caused a connection timeout on the
  test email; `nc` confirmed the network path was fine, and fixing the port (465 + SSL)
  resolved it.
