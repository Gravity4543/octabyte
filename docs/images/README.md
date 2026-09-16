# Screenshots

Evidence captured during a live run of the stack. Referenced from the root
`README.md`, `APPROACH.md`, and `CHALLENGES.md`.

| File | What it shows |
|------|---------------|
| `1_terraform_apply.PNG` | `terraform apply` running |
| `2_terraform_apply.PNG` | apply complete |
| `3_instances.PNG` | app + monitoring EC2 instances running |
| `4_targetgroups.PNG` | ALB target groups (staging/prod) |
| `5_alb_rules.PNG` | ALB listener host-based routing rules |
| `6_vpc_resource_map.PNG` | VPC resource map |
| `7_vpc_details.PNG` | VPC subnets / details |
| `8_security_groups.PNG` | security group rules |
| `9_statelocking.PNG` | S3 remote state + DynamoDB lock |
| `10_Outputs.PNG` | terraform outputs |
| `11_build_failure.PNG` | a failing pipeline build |
| `12_email_faliure_alert.PNG` | failure email notification |
| `13_manual_production_approval.PNG` | manual production approval gate |
| `14_full_green_pipeline.PNG` | full green pipeline (all stages) |
| `15_application_up.PNG` | app responding on /health via the ALB |
| `16_infrastcture_overview.PNG` | Grafana infra dashboard |
| `17_infra_part2.PNG` | Grafana infra dashboard (more panels) |
| `18_application_overview.PNG` | Grafana app/database dashboard |
| `19_datasource.PNG` | Grafana datasources (Prometheus + Loki) |
