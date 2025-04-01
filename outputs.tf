output "postgres_database_creds_consumer_policy" {
  value = aws_iam_policy.consumer_policy.arn
}

output "postgres_database_creds_secrets_arn" {
  value = aws_secretsmanager_secret.postgres_creds.arn
}
