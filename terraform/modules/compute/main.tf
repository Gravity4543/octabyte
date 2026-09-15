# latest AL2023 - has the SSM agent baked in
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# app box - runs the staging + prod containers. no key pair on purpose (SSM only)
resource "aws_instance" "app" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.app_instance_type
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [var.app_sg_id]
  iam_instance_profile   = aws_iam_instance_profile.instance.name

  user_data = file("${path.module}/user_data/app.sh")

  metadata_options {
    http_tokens = "required" # enforce IMDSv2
  }

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name = "${var.project_name}-app"
    Role = "app"
  }
}

# monitoring box - Prometheus/Grafana/Loki via compose
resource "aws_instance" "monitoring" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.monitoring_instance_type
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [var.monitoring_sg_id]
  iam_instance_profile   = aws_iam_instance_profile.instance.name

  user_data = file("${path.module}/user_data/monitoring.sh")

  metadata_options {
    http_tokens = "required" # enforce IMDSv2
  }

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name = "${var.project_name}-monitoring"
    Role = "monitoring"
  }
}
