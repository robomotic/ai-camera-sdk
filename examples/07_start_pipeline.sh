#!/usr/bin/env bash
# Start the pipeline. Returns 202 Accepted with a PipelineStatus snapshot;
# poll /status (or subscribe to the `pipeline.status` WS channel) for
# running confirmation.
set -euo pipefail
: "${BASE:?}"
: "${ACCESS_TOKEN:?}"
: "${PIPELINE_ID:?}"

curl "${CURL_OPTS[@]}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Idempotency-Key: $(uuidgen)" \
  -H "X-Request-Id: ${REQUEST_ID}-start" \
  -X POST "${BASE}/pipelines/${PIPELINE_ID}:start" | jq .

echo "--- polling status ---"
for i in 1 2 3 4 5; do
  curl "${CURL_OPTS[@]}" \
    -H "Authorization: Bearer ${ACCESS_TOKEN}" \
    "${BASE}/pipelines/${PIPELINE_ID}/status" | jq .
  sleep 1
done
