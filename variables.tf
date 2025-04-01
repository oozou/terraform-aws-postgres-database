/* -------------------------------------------------------------------------- */
/*                                  GENERICS                                  */
/* -------------------------------------------------------------------------- */
variable "prefix" {
  description = "The prefix name of customer to be displayed in AWS console and resource."
  type        = string
}

variable "environment" {
  description = "Environment name used as environment resources name."
  type        = string
}

variable "custom_tags" {
  description = "Tags to add more; default tags contian {terraform=true, environment=var.environment}"
  type        = map(string)
  default     = {}
}

variable "database_name" {
  description = "Name of the database to create"
  type        = string
}

variable "vpc_id" {
  description = "VPC id where security group is created"
  type        = string
}

variable "subnets" {
  description = "Subnet IDs to deploy into"
  type        = list(string)
}

variable "rds_db_identifier" {
  description = "postgres db Id"
  type        = string
}

variable "rds_secret_manager_secret_key" {
  description = "Secret manager key to pull RDS creds"
  type        = string
}

variable "rds_postgres_user_security_group" {
  description = "Security group to allow access to postgres RDS"
  type        = string
}

# variable "db_resource_id" {
#   description = "The db_resource_id of postgres db"
#   type        = string
# }

variable "db_endpoint" {
  description = "The endpoint of the db"
  type        = string
}

variable "db_port" {
  description = "The db port"
  type        = number
  default     = 5432
}

variable "postgres_database" {
  description = "The postgres database username and password to be created"
  type = object({
    username = string
    password = string
  })
}

variable "is_database_created" {
  description = "Flag to toggle bootstrap instance to run"
  type        = bool
  default     = false
}