#!/bin/bash
# Checks the deployed container answers 200 on /health.
# Usage: smoke-test.sh <staging|production>
set -euo pipefail

[ "$1" = "staging" ] && PORT=8081 || PORT=8080

for i in $(seq 1 10); do
  if [ "$(curl -s -o /dev/null -w '%{http_code}' http://localhost:$PORT/health)" = "200" ]; then
    echo "$1 healthy"
    exit 0
  fi
  sleep 5
done

echo "$1 smoke test failed" >&2
exit 1
