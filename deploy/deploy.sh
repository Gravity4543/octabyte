#!/bin/bash
# runs on the app box (jenkins calls this over SSM)
# usage: deploy.sh <staging|production> <image_tag> <ecr_registry> <region> <db_secret_name>
set -euo pipefail

ENV="$1"
IMAGE_TAG="$2"
ECR_REGISTRY="$3"
REGION="$4"
DB_SECRET_NAME="$5"

COMPOSE="docker-compose.$ENV.yml"

# pull the db creds out of secrets manager into DB_* vars
load_db_creds() {
  local secret
  secret=$(aws secretsmanager get-secret-value --secret-id "$DB_SECRET_NAME" \
    --region "$REGION" --query SecretString --output text)

  DB_HOST=$(echo "$secret" | jq -r .host)
  DB_PORT=$(echo "$secret" | jq -r .port)
  DB_USER=$(echo "$secret" | jq -r .username)
  DB_PASS=$(echo "$secret" | jq -r .password)

  # each env gets its own db on the shared rds instance
  local base suffix
  base=$(echo "$secret" | jq -r .dbname)
  [ "$ENV" = "production" ] && suffix="_prod" || suffix="_staging"
  DB_NAME="${base}${suffix}"
}

# create the env database if it doesn't exist yet
ensure_db() {
  export PGPASSWORD="$DB_PASS"
  local exists
  exists=$(psql -h "$DB_HOST" -U "$DB_USER" -d postgres -tAc \
    "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'")
  if [ "$exists" != "1" ]; then
    psql -h "$DB_HOST" -U "$DB_USER" -d postgres -c "CREATE DATABASE $DB_NAME"
  fi
}

# write the env file the container reads
write_env_file() {
  cat > ".env.$ENV" <<EOF
PORT=3000
DB_HOST=$DB_HOST
DB_PORT=$DB_PORT
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASS
DB_NAME=$DB_NAME
DB_SSL=true
EOF
  chmod 600 ".env.$ENV"
}

# pull the image and (re)start the container
start_app() {
  aws ecr get-login-password --region "$REGION" \
    | docker login --username AWS --password-stdin "$ECR_REGISTRY"

  export ECR_REGISTRY
  export IMAGE="octabyte-devops/app:$IMAGE_TAG"
  docker compose -f "$COMPOSE" pull
  docker compose -f "$COMPOSE" up -d
}

cd /opt/app
load_db_creds
ensure_db
write_env_file
start_app
echo "deployed $ENV ($IMAGE_TAG)"
