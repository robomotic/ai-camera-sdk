#!/usr/bin/env bash
# Create a pipeline bound to the input from step 02.
# Exports: PIPELINE_ID
set -euo pipefail
: "${BASE:?}"
: "${ACCESS_TOKEN:?}"
: "${INPUT_ID:?run 02_create_input.sh}"

resp=$(curl "${CURL_OPTS[@]}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -H "Idempotency-Key: $(uuidgen)" \
  -H "X-Request-Id: ${REQUEST_ID}-pipeline" \
  -X POST "${BASE}/pipelines" \
  -d "$(cat <<JSON
{
  "name": "front-gate-privacy",
  "description": "Blur faces on the front-gate RTSP feed.",
  "enabled": false,
  "input_id": "${INPUT_ID}"
}
JSON
)")

export PIPELINE_ID=$(echo "$resp" | jq -r .id)
echo "PIPELINE_ID=${PIPELINE_ID}"
