#!/usr/bin/env bash
# Fetch summary and per-pipeline counters, then a Prometheus export.
set -euo pipefail
: "${BASE:?}"
: "${ACCESS_TOKEN:?}"
: "${PIPELINE_ID:?}"

echo "--- /stats/summary ---"
curl "${CURL_OPTS[@]}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  "${BASE}/stats/summary" | jq .

echo "--- /stats/pipelines/${PIPELINE_ID} ---"
curl "${CURL_OPTS[@]}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  "${BASE}/stats/pipelines/${PIPELINE_ID}" | jq .

echo "--- /stats/export?format=prometheus ---"
curl "${CURL_OPTS[@]}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  "${BASE}/stats/export?format=prometheus"
