
module "postgres_db_service" {
  source = "../.."

  database_name = "test"
  prefix = "oozou"
  environment = "dev"

  vpc_id  = "vpc-xxxx"
  subnets = ["subnet-xxx","subnet-xxx"]

  rds_db_identifier           = "xxx-dev-app-db"
  rds_secret_manager_secret_key    = "xxx-dev-app-db/postgres-master-creds"
  rds_postgres_user_security_group = "sg-xxxx"

  #db_resource_id = module.postgres_db_cluster_warehouse_service.cluster_resource_id
  db_endpoint    = "xxx-dev-app-db.ap-southeast-7.rds.amazonaws.com"
  db_port        = "5432"

  postgres_database = {
    username = "testuser"
    password = "test123"
  }

  is_database_created = false
}
