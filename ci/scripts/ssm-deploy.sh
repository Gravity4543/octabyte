#!/bin/bash
# runs on the jenkins side. pushes the deploy files over to the app box and kicks
# off the deploy via SSM (no ssh). usage: ssm-deploy.sh <staging|production> <image_tag>
# needs: AWS_REGION ECR_REGISTRY APP_INSTANCE_ID DB_SECRET_NAME
set -euo pipefail

ENV="$1"
IMAGE_TAG="$2"

# fire a command on the box and wait for it
run_ssm() {
  local cid
  cid=$(aws ssm send-command \
    --region "$AWS_REGION" \
    --instance-ids "$APP_INSTANCE_ID" \
    --document-name AWS-RunShellScript \
    --timeout-seconds 600 \
    --parameters commands="$1" \
    --query Command.CommandId --output text)

  aws ssm wait command-executed --region "$AWS_REGION" \
    --command-id "$cid" --instance-id "$APP_INSTANCE_ID"

  aws ssm get-command-invocation --region "$AWS_REGION" \
    --command-id "$cid" --instance-id "$APP_INSTANCE_ID" \
    --query StandardOutputContent --output text
}

# copy the files over - base64 so each is a single command
for f in docker-compose.$ENV.yml deploy.sh smoke-test.sh; do
  b64=$(base64 -w0 deploy/$f)
  run_ssm "[\"echo $b64 | base64 -d > /opt/app/$f\"]"
done

# deploy + smoke test
run_ssm "[\"cd /opt/app && chmod +x deploy.sh smoke-test.sh && ./deploy.sh $ENV $IMAGE_TAG $ECR_REGISTRY $AWS_REGION $DB_SECRET_NAME && ./smoke-test.sh $ENV\"]"
