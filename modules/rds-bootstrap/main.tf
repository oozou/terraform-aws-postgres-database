data "aws_caller_identity" "active" {}

data "aws_region" "active" {}

locals {
  region-account     = "${data.aws_region.active.name}:${data.aws_caller_identity.active.account_id}"
  security_group_ids = concat([aws_security_group.outbound_internet.id], var.security_group_ids)
}

data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-*"]
  }

  owners = ["amazon"]
}

# ####################### IAM #####################
resource "aws_iam_instance_profile" "rds_bootstrap_profile" {
  name = "${var.database_name}-rds-bootstrap-profile"
  role = aws_iam_role.rds_bootstrap_role.name
}

resource "aws_iam_role" "rds_bootstrap_role" {
  name               = "${var.database_name}-rds-bootstrap-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.rds_bootstrap_assume.json

  tags = merge({
    Name = "${var.database_name}-rds-bootstrap-role"
  }, var.custom_tags)
}

data "aws_iam_policy_document" "rds_bootstrap_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "rds_bootstrap_role_attachment" {
  role       = aws_iam_role.rds_bootstrap_role.name
  policy_arn = aws_iam_policy.rds_bootstrap_access.arn
}

resource "aws_iam_policy" "rds_bootstrap_access" {
  name   = "${var.database_name}-access"
  policy = data.aws_iam_policy_document.rds_bootstrap_access.json
  tags   = var.custom_tags
}

# ################## Security Group ###################
# SG for outbound internet access
resource "aws_security_group" "outbound_internet" {
  name   = "${var.database_name}-rds-bootstrap"
  vpc_id = var.vpc_id

  tags = merge({
    Name = "${var.database_name}-rds-bootstrap"
  }, var.custom_tags)
}

# Allow HTTP to world
resource "aws_security_group_rule" "outbound_internet_http" {
  type              = "egress"
  security_group_id = aws_security_group.outbound_internet.id
  from_port         = "80"
  to_port           = "80"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

# Allow HTTPS to world
resource "aws_security_group_rule" "outbound_internet_https" {
  type              = "egress"
  security_group_id = aws_security_group.outbound_internet.id
  from_port         = "443"
  to_port           = "443"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

data "aws_iam_policy_document" "rds_bootstrap_access" {
  statement {
    sid     = "AllowReadAccessToDBCredentials"
    effect  = "Allow"
    actions = ["secretsmanager:GetSecretValue"]

    resources = ["${var.db_creds_secret_key}*"]
  }

  statement {
    sid     = "AllowReadAccessToDBInstances"
    effect  = "Allow"
    actions = ["rds:DescribeDBInstances"]

    resources = ["*"]
  }
}

# ############## Instance #################
# bootstrap_instance_ami, postgres_user_security_group
resource "aws_instance" "ephemeral_instance" {
  subnet_id              = var.private_subnet_id
  instance_type          = "t3.micro"
  iam_instance_profile   = aws_iam_instance_profile.rds_bootstrap_profile.id
  ami                    = data.aws_ami.amazon_linux.id
  vpc_security_group_ids = local.security_group_ids
  user_data              = data.template_file.user_data.rendered

  # Terminate instance on shutdown
  instance_initiated_shutdown_behavior = "terminate"

  root_block_device {
    volume_type           = "gp2"
    volume_size           = "128"
    delete_on_termination = "true"
  }

  tags = merge({
    Name = "${var.database_name}-rds-bootstrap"
  }, var.custom_tags)
}

# Bootstrap script
data "template_file" "user_data" {
  template = file("${path.module}/templates/scripts.sh.tpl")

  vars = {
    DATABASE_NAME           = var.database_name
    DB_INSTANCE_IDENTIFIER  = var.rds_db_identifier
    AWS_REGION              = data.aws_region.active.name
    DB_CREDS_SECRET_KEY     = var.db_creds_secret_key
    DATABASE_USER           = var.db_user_name
    DATABASE_PASSWORD       = var.db_password
    DB_ENDPOINT             = var.db_endpoint
    DB_PORT                 = var.db_port
  }
}
