# CI/CD (Jenkins)

The pipeline is defined in [`Jenkinsfile`](./Jenkinsfile). It is a declarative
pipeline that tests on every branch/PR and, on `main`, builds/scans/pushes the
image and deploys to staging then (after manual approval) production.

## Pipeline flow

```
any branch / PR:
  Checkout -> Install & Test (node:20 container) -> Dependency Scan (npm audit + Trivy fs)

main only (after the above):
  Build Image -> Trivy Image Scan -> Push to ECR
             -> Deploy Staging (SSM) + smoke test
             -> [ Manual Approval ]
             -> Deploy Production (SSM) + smoke test

on failure (any stage): email notification
```

## Why these choices

- **Docker-agent for tests** (`agent { docker { image 'node:20' } }`): the same
  Node version runs locally and in CI, so no "works on my machine" drift and no
  language runtimes installed on the Jenkins host.
- **SSM for deploys, not SSH**: the app instance has no inbound port 22. Jenkins
  triggers deploys with `aws ssm send-command`, authenticated by IAM. Nothing to
  key-manage, smaller attack surface.
- **Trivy as a container**: no host install; scans both dependencies (fs) and the
  built image. Dependency scan is report-only; the image scan can hard-fail on
  HIGH/CRITICAL (set `--exit-code 0` to make it report-only during the assessment
  if the base image carries unavoidable transitive CVEs).
- **Manual approval gate** before production via the `input` step.

## One-time Jenkins setup

### Plugins
- Pipeline
- Docker Pipeline
- Email Extension

### Agent requirements
- Jenkins runs on EC2 with an **instance role** granting ECR push + SSM send-command,
  so no AWS keys are stored in Jenkins.
- Docker installed and the Jenkins user in the `docker` group.
- AWS CLI v2 installed on the agent.
- SMTP configured under Manage Jenkins -> System (SMTP server + the System Admin
  e-mail as the sender) so failure emails can be sent.

### Credentials
No Jenkins credentials are required: AWS access is via the instance role, and
failure notifications use SMTP configured at the system level (no secret needed).


### Job setup
- Create a **Multibranch Pipeline** (or Pipeline) job pointed at the repo.
- Script path: `ci/Jenkinsfile`.
- Add a GitHub webhook so pushes/PRs trigger builds automatically.

## Minimum IAM for the Jenkins instance role

Attach this to the Jenkins EC2 instance role (plus `AmazonSSMManagedInstanceCore`
if you want to reach the box via SSM Session Manager). `sts:GetCallerIdentity` is
allowed by default, so no extra permission is needed for the account lookup.

I have attached the roles from aws panal Here is the policy json used for the IAM role
```json
{
  "Version": "2012-10-17",
  "Statement": [
    { "Sid": "Ecr", "Effect": "Allow",
      "Action": ["ecr:GetAuthorizationToken","ecr:BatchCheckLayerAvailability",
                 "ecr:GetDownloadUrlForLayer","ecr:BatchGetImage","ecr:PutImage",
                 "ecr:InitiateLayerUpload","ecr:UploadLayerPart","ecr:CompleteLayerUpload"],
      "Resource": "*" },
    { "Sid": "SsmDeploy", "Effect": "Allow",
      "Action": ["ssm:SendCommand","ssm:GetCommandInvocation"],
      "Resource": "*" }
  ]
}
```
