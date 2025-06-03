data "aws_caller_identity" "active" {}

data "aws_region" "active" {}

locals {
  postgres_db_creds = {
    "DB_HOST"     = var.db_endpoint
    "DB_PORT"     = var.db_port
    "DB_NAME"     = var.database_name
    "DB_USERNAME" = var.postgres_database.username
    "DB_PASSWORD" = var.postgres_database.password
    "AWS_REGION"  = data.aws_region.active.name
  }
}

module "rds_bootstrap" {
  count = var.is_database_created ? 0 : 1

  source = "./modules/rds-bootstrap"

  database_name           = var.database_name
  #db_instance_name_prefix = var.db_instance_name_prefix

  vpc_id            = var.vpc_id
  private_subnet_id = var.subnets[0]
  rds_db_identifier = var.rds_db_identifier
  // Database user to be created for application
  db_user_name = var.postgres_database.username
  db_password  = var.postgres_database.password
  // Secret which stores the Postgres DB Master Creds
  db_creds_secret_key = var.rds_secret_manager_secret_key
  db_endpoint         = var.db_endpoint
  db_port             = var.db_port

  custom_tags = var.custom_tags

  security_group_ids = [
    var.rds_postgres_user_security_group,
  ]
}

# Store Postgres Master Credentials in the secret manager
# at this time, Terraform doesn't support RDS credential type, but we are storing rds connection details in the same format as AWS does for RDS type
# https://docs.aws.amazon.com/secretsmanager/latest/userguide/terms-concepts.html
# https://github.com/terraform-providers/terraform-provider-aws/issues/4953

module "postgres_creds_kms_key" {
  source  = "oozou/kms-key/aws"
  version = "1.0.0"

  prefix               = var.prefix
  environment          = var.environment
  name                 = "${var.database_name}-database-secret-postgres"
  key_type             = "service"
  description          = "Used to encrypt secret-postgres"
  append_random_suffix = true

  service_key_info = {
    "aws_service_names" = [
      format(
        "secretsmanager.%s.amazonaws.com",
        data.aws_region.active.name,
      ),
    ]
    "caller_account_ids" = [data.aws_caller_identity.active.account_id]
  }
}


# Append random string to SM Secret names because once we tear down the infra, the secret does not actually
# get deleted right away, which means that if we then try to recreate the infra, it'll fail as the
# secret name already exists.
resource "random_string" "postgres_creds_random_suffix" {
  length  = 6
  special = false
}

resource "aws_secretsmanager_secret" "postgres_creds" {
  name        = "${lower(var.database_name)}/postgres-database-creds--${random_string.postgres_creds_random_suffix.result}"
  description = "Postgres RDS Database ${var.database_name} Credentials"
  kms_key_id  = module.postgres_creds_kms_key.key_id

  tags = merge({
    Name = "${var.database_name}/postgres-database-creds"
  }, var.custom_tags)
}

resource "aws_secretsmanager_secret_version" "postgres_creds" {
  secret_id     = aws_secretsmanager_secret.postgres_creds.id
  secret_string = jsonencode(local.postgres_db_creds)
}

# We add a policy to the ECS Task Execution role so that ECS can pull secrets from SecretsManager and
# inject them as environment variables in the service
resource "aws_iam_policy" "consumer_policy" {
  name        = "${var.database_name}-postgres-database-secrets-${random_string.postgres_creds_random_suffix.result}"
  path        = "/"
  description = "${var.database_name} postgres database consumer policy with secret manager access"
  tags        = var.custom_tags

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": ${jsonencode([aws_secretsmanager_secret.postgres_creds.arn])}
    }
  ]
}
EOF
}
