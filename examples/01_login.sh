#!/usr/bin/env bash
# Exchange username/password for an access + refresh JWT pair.
# Exports: ACCESS_TOKEN, REFRESH_TOKEN, EXPIRES_IN
set -euo pipefail
: "${BASE:?source 00_env.sh first}"
: "${USERNAME:?}"
: "${PASSWORD:?}"

resp=$(curl "${CURL_OPTS[@]}" \
  -H "Content-Type: application/json" \
  -H "X-Request-Id: ${REQUEST_ID}-login" \
  -X POST "${BASE}/auth/login" \
  -d "$(cat <<JSON
{
  "username": "${USERNAME}",
  "password": "${PASSWORD}"
}
JSON
)")

export ACCESS_TOKEN=$(echo "$resp" | jq -r .access_token)
export REFRESH_TOKEN=$(echo "$resp" | jq -r .refresh_token)
export EXPIRES_IN=$(echo "$resp" | jq -r .expires_in)

echo "ACCESS_TOKEN=${ACCESS_TOKEN:0:12}…"
echo "EXPIRES_IN=${EXPIRES_IN}s"
