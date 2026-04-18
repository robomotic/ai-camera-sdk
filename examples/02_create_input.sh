#!/usr/bin/env bash
# Register an RTSP input. Credentials are write-only: stored securely,
# never returned by subsequent GETs.
# Exports: INPUT_ID
set -euo pipefail
: "${BASE:?}"
: "${ACCESS_TOKEN:?run 01_login.sh}"

IDEMPOTENCY_KEY=$(uuidgen)

resp=$(curl "${CURL_OPTS[@]}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -H "Idempotency-Key: ${IDEMPOTENCY_KEY}" \
  -H "X-Request-Id: ${REQUEST_ID}-input" \
  -X POST "${BASE}/inputs" \
  -d '{
    "name": "front-gate-rtsp",
    "kind": "rtsp",
    "uri": "rtsp://192.168.1.50:554/stream1",
    "credentials": {
      "username": "viewer",
      "password": "s3cret"
    }
  }')

export INPUT_ID=$(echo "$resp" | jq -r .id)
echo "INPUT_ID=${INPUT_ID}"
