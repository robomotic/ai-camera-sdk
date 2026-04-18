#!/usr/bin/env bash
# Publish the processed (masked) stream over RTSP.
# Exports: OUTPUT_ID
set -euo pipefail
: "${BASE:?}"
: "${ACCESS_TOKEN:?}"
: "${PIPELINE_ID:?}"

resp=$(curl "${CURL_OPTS[@]}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -H "Idempotency-Key: $(uuidgen)" \
  -H "X-Request-Id: ${REQUEST_ID}-output" \
  -X POST "${BASE}/pipelines/${PIPELINE_ID}/outputs" \
  -d '{
    "name": "front-gate-rtsp-out",
    "kind": "rtsp",
    "content": "processed",
    "codec": "h264",
    "rtsp": {
      "url": "rtsp://0.0.0.0:8554/front-gate",
      "transport": "tcp"
    }
  }')

export OUTPUT_ID=$(echo "$resp" | jq -r .id)
echo "OUTPUT_ID=${OUTPUT_ID}"
