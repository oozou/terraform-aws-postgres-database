variable "database_name" {
  description = "New Database Name"
  type        = string
}

variable "vpc_id" {
  description = "VPC id where security group is created"
  type        = string
}

variable "private_subnet_id" {
  description = "Private subnet to launch ephemeral EC2 instance"
  type        = string
}

variable "db_creds_secret_key" {
  description = "Secret Manager key to access DB master credentials"
  type        = string
}

variable "db_user_name" {
  description = "Database user Name"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Database Password"
  type        = string
  sensitive   = true
}

variable "security_group_ids" {
  description = "List of security groups the ephemeral instance will belong to. Allow access to the RDS cluster and internet"
  type        = list(string)
}

variable "custom_tags" {
  description = "Custom tags which can be passed on to the AWS resources. They should be key value pairs having distinct keys."
  type        = map(any)
  default     = {}
}

variable "rds_db_identifier" {
  description = "The identifier of the db"
  type        = string
}

# variable "db_instance_name_prefix" {
#   description = "DB instance name prefix. eg., if passed 'test', the full db instance name would be test-read-write-instance"
#   type        = string
#   default     = ""
# }