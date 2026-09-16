aws_region   = "ap-south-1"
project_name = "octabyte-devops"

# Networking
enable_nat_gateway = false # RDS is the only private resource; no egress needed

# Compute
app_instance_type        = "t3.small"
monitoring_instance_type = "t3.micro"

# App / ALB
prod_port           = 8080
staging_port        = 8081
staging_host_header = "staging.localhost"

# Locked to this machine's public IP so only you can reach Grafana/Prometheus.
# If your IP changes (dynamic ISP / different network / VPN), update this and re-apply.
admin_cidr = "my-ip"

# Database
db_instance_class     = "db.t4g.micro"
db_name               = "appdb"
db_username           = "appadmin"
backup_retention_days = 7
