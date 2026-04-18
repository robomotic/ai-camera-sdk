#!/usr/bin/env bash
# Add a static rectangular privacy mask covering the upper third of the
# frame (e.g. to blur a neighbour's window). `follow_detection: false`
# because this mask is fixed, not tracking a detection.
# Exports: MASK_ID
set -euo pipefail
: "${BASE:?}"
: "${ACCESS_TOKEN:?}"
: "${PIPELINE_ID:?}"

resp=$(curl "${CURL_OPTS[@]}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -H "Idempotency-Key: $(uuidgen)" \
  -H "X-Request-Id: ${REQUEST_ID}-mask" \
  -X POST "${BASE}/pipelines/${PIPELINE_ID}/masks" \
  -d '{
    "target": "all",
    "style": "blur",
    "strength": 40,
    "follow_detection": false,
    "shape": {
      "type": "rectangle",
      "rect": { "x": 0.0, "y": 0.0, "w": 1.0, "h": 0.33 }
    }
  }')

export MASK_ID=$(echo "$resp" | jq -r .id)
echo "MASK_ID=${MASK_ID}"
