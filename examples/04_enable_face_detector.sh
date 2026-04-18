#!/usr/bin/env bash
# Configure the face detector on the pipeline. PUT replaces the whole config.
set -euo pipefail
: "${BASE:?}"
: "${ACCESS_TOKEN:?}"
: "${PIPELINE_ID:?run 03_create_pipeline.sh}"

curl "${CURL_OPTS[@]}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -H "X-Request-Id: ${REQUEST_ID}-detector" \
  -X PUT "${BASE}/pipelines/${PIPELINE_ID}/detectors/face" \
  -d '{
    "enabled": true,
    "model_variant": "balanced",
    "confidence_threshold": 0.55,
    "nms_threshold": 0.45,
    "max_detections": 32,
    "roi": { "x": 0.0, "y": 0.0, "w": 1.0, "h": 0.8 },
    "tracking": { "enabled": true, "max_age": 30, "iou_threshold": 0.3 }
  }' | jq .
