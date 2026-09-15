# shared role for both EC2 boxes - SSM, ECR pull, read the DB secret + SSM params
data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "instance" {
  name               = "${var.project_name}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
  tags               = { Name = "${var.project_name}-ec2-role" }
}

# SSM session manager + agent
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# pull images from ECR
resource "aws_iam_role_policy_attachment" "ecr_readonly" {
  role       = aws_iam_role.instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# S3 read so the boxes can pull deploy/monitoring files from the artifacts bucket
resource "aws_iam_role_policy_attachment" "s3_readonly" {
  role       = aws_iam_role.instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

# only the one DB secret + our SSM param path, nothing broader
data "aws_iam_policy_document" "app_secrets" {
  statement {
    sid       = "ReadDbSecret"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [var.db_secret_arn]
  }

  statement {
    sid = "ReadEnvParameters"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
    ]
    resources = ["arn:aws:ssm:*:*:parameter${var.ssm_parameter_prefix}/*"]
  }
}

resource "aws_iam_role_policy" "app_secrets" {
  name   = "${var.project_name}-secrets-read"
  role   = aws_iam_role.instance.id
  policy = data.aws_iam_policy_document.app_secrets.json
}

resource "aws_iam_instance_profile" "instance" {
  name = "${var.project_name}-instance-profile"
  role = aws_iam_role.instance.name
}
