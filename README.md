# RDS Bootstrap

This project bootstraps PostgreSQL to create an initial database. This bootstrapping may be required for many applications who may just have permissions to write on a specific database and may not have permissions to create them.

It creates:

- *RDS Bootstrap*: Spins up an ephemeral EC2 instance which connects to the database cluster and creates a database in it. EC2 instance then automatically terminates after the job

## Architecture

![Postgres Bootstarp](./assets/postgres-database.png)

## Run-Book

### Pre-requisites
  
#### IMPORTANT NOTE

1. Required version of Terraform is mentioned in `local.tf`.
2. Go through `variables.tf` for understanding each terraform variable before running this component.

#### Resources needed before deploying this component

1. VPC with Private Subnets
2. RDS DB in which the database needs to be created