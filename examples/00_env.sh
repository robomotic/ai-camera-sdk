#!/usr/bin/env bash
# Source this file: `source 00_env.sh`
# Holds shared environment for the example flow. Edit as needed.

export BOARD="camera.local"
export BASE="https://${BOARD}/api/v1"
export USERNAME="admin"
export PASSWORD="change-me-please"

# Curl defaults: self-signed cert, fail on HTTP >=400, show server errors.
export CURL_OPTS=(--silent --show-error --fail-with-body --insecure)

# Request correlation for the whole flow.
export REQUEST_ID="example-$(date +%s)"

echo "BOARD=${BOARD}"
echo "BASE=${BASE}"
echo "USERNAME=${USERNAME}"
echo "REQUEST_ID=${REQUEST_ID}"
