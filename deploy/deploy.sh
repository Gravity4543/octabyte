#!/bin/bash
# runs on the app box (jenkins calls this over SSM)
# usage: deploy.sh <staging|production> <image_tag> <ecr_registry> <region> <db_secret_name>
set -euo pipefail

ENV="$1"
IMAGE_TAG="$2"
ECR_REGISTRY="$3"
REGION="$4"
DB_SECRET_NAME="$5"

cd /opt/app

# each env gets its own db on the same rds instance
case "$ENV" in
  staging)    DB_SUFFIX="_staging" ;;
  production) DB_SUFFIX="_prod" ;;
  *) echo "unknown env: $ENV"; exit 1 ;;
esac

# grab db creds from secrets manager
SECRET=$(aws secretsmanager get-secret-value --secret-id "$DB_SECRET_NAME" \
  --region "$REGION" --query SecretString --output text)

DB_HOST=$(echo "$SECRET" | jq -r .host)
DB_PORT=$(echo "$SECRET" | jq -r .port)
DB_USER=$(echo "$SECRET" | jq -r .username)
DB_PASS=$(echo "$SECRET" | jq -r .password)
DB_NAME="$(echo "$SECRET" | jq -r .dbname)$DB_SUFFIX"

# make the env db if it's not there
export PGPASSWORD="$DB_PASS"
psql -h "$DB_HOST" -U "$DB_USER" -d postgres -tc \
  "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'" | grep -q 1 \
  || psql -h "$DB_HOST" -U "$DB_USER" -d postgres -c "CREATE DATABASE $DB_NAME"

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

# deploy
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$ECR_REGISTRY"

export ECR_REGISTRY
export IMAGE="octabyte-devops/app:$IMAGE_TAG"
docker compose -f "docker-compose.$ENV.yml" pull
docker compose -f "docker-compose.$ENV.yml" up -d

echo "deployed $ENV ($IMAGE_TAG)"
