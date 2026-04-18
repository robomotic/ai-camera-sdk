#!/usr/bin/env bash
# Apply a commercial license key. Keys are hardware-bound; a key issued
# for a different serial yields 409 with code LICENSE_INVALID.
set -euo pipefail
: "${BASE:?}"
: "${ACCESS_TOKEN:?}"

LICENSE_KEY="${LICENSE_KEY:-PASTE-YOUR-KEY-HERE}"

curl "${CURL_OPTS[@]}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -H "Idempotency-Key: $(uuidgen)" \
  -H "X-Request-Id: ${REQUEST_ID}-license" \
  -X POST "${BASE}/license" \
  -d "$(cat <<JSON
{ "key": "${LICENSE_KEY}" }
JSON
)" | jq .

echo "--- /license/features ---"
curl "${CURL_OPTS[@]}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  "${BASE}/license/features" | jq .
