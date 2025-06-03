#!/bin/bash

echo "Executing db script...."
set -eo pipefail
cat /etc/os-release
sudo yum -y update
sudo amazon-linux-extras install postgresql10
sudo yum -y install jq

dbCon=`aws secretsmanager get-secret-value --secret-id ${DB_CREDS_SECRET_KEY} --version-stage AWSCURRENT --region ${AWS_REGION} --output text --query '{SecretString:SecretString}'`
export PGHOST= ${DB_ENDPOINT}
echo $PGHOST
export PGPORT= ${DB_PORT}
echo $PGPORT
export PGUSER=`echo "$dbCon" | jq -r '.username'`
echo $PGUSER
export PGPASSWORD=`echo "$dbCon" | jq -r '.password'`
export PGDATABASE="postgres"

if aws --region ${AWS_REGION} rds wait db-instance-available --db-instance-identifier ${DB_INSTANCE_IDENTIFIER} ; then
  echo "RDS is up"
else
  echo "Still can not connect to $PGDATABASE, hence RDS instance is not created yet"
  echo "Shutting down this ec2 instance. Rerun the terraform workspace after RDS instance is up"
  # since instance_initiated_shutdown_behavior = "terminate"
  shutdown -h now
fi

rm -f ddl.sql
cat <<EOF >>ddl.sql
CREATE USER "${DATABASE_USER}" WITH PASSWORD '${DATABASE_PASSWORD}' NOSUPERUSER NOCREATEDB NOCREATEROLE LOGIN;
CREATE DATABASE "${DATABASE_NAME}";
REVOKE ALL ON DATABASE "${DATABASE_NAME}" FROM public;
GRANT ALL PRIVILEGES ON DATABASE "${DATABASE_NAME}" to "${DATABASE_USER}";
EOF

# Below command gives a output 1 if Database exists
if psql -lqt -U $PGUSER | cut -d \| -f 1 | grep -qw ${DATABASE_NAME}; then
  echo "Database already exists"
else
  echo "Create DB"
  psql -f ddl.sql
fi

# since instance_initiated_shutdown_behavior = "terminate"
shutdown -h now