# AI Camera SDK — REST API Specification

Local HTTPS control plane for the AI Camera SDK embedded vision system.
Configures pipelines, detectors, masks, outputs, calibration, power
management, firmware updates, remote tunnels, and commercial licensing.
Media capture and delivery (GStreamer, DeepStream, NVIDIA shared memory)
are handled outside this API.

---

## Hardware targets

The SDK runs on heterogeneous embedded hardware. Any board in this list
is a valid target for the control API:

### NVIDIA Jetson Orin Nano

![Jetson Orin Nano — angled view](images/jetson-orin-nano-01.jpg)
![Jetson Orin Nano — port detail](images/jetson-orin-nano-02.png)

Full NVIDIA accelerator stack: DeepStream, TensorRT, cuDNN.
Supports all three detector types (`face`, `license_plate`, `document`).

### NVIDIA AGX Orin

![NVIDIA AGX Orin — multi-camera system](images/nvidia-agx-orin.jpg)

Compact embedded AI computer with a high-performance NVIDIA Ampere-architecture
GPU. Designed for autonomous machines and multi-camera vision applications.
Full accelerator stack; supports all three detector types (`face`,
`license_plate`, `document`). Multiple CSI camera inputs allow simultaneous
multi-stream pipeline processing.

### Raspberry Pi 5 + HAILO

![Raspberry Pi 5 — internals](images/rpi5-inside.webp)

Raspberry Pi 5 with a M.2 HAILO-8L accelerator module.
The HAILO chip runs inference; supported detectors are `face` and
`license_plate`. The `document` detector is not available on this platform.

---

## Repository layout

```
.
├── openapi.yaml              # OpenAPI 3.1 source of truth
├── .spectral.yaml            # Spectral lint ruleset
├── docs/
│   ├── API-DESIGN.md         # Design rationale, auth, errors, WS protocol
│   └── LICENSING.md          # Three-tier licensing rationale
├── examples/                 # End-to-end curl flows (see examples/README.md)
│   ├── 00_env.sh
│   ├── 01_login.sh
│   ├── 02_create_input.sh
│   ├── 03_create_pipeline.sh
│   ├── 04_enable_face_detector.sh
│   ├── 05_add_rectangle_mask.sh
│   ├── 06_add_rtsp_output.sh
│   ├── 07_start_pipeline.sh
│   ├── 08_get_stats.sh
│   └── 09_apply_license.sh
└── images/                   # Hardware board photography
    ├── jetson-orin-nano-01.jpg
    ├── jetson-orin-nano-02.png
    ├── nvidia-agx-orin.jpg
    └── rpi5-inside.webp
```

---

## Quick start

```bash
# 1. Set your board hostname and credentials
export BOARD="camera.local"
export USERNAME="admin"
export PASSWORD="your-password"

# 2. Log in and capture the access token
ACCESS_TOKEN=$(curl -s -k https://${BOARD}/api/v1/auth/login \
  -H 'Content-Type: application/json' \
  -d "{\"username\":\"${USERNAME}\",\"password\":\"${PASSWORD}\"}" \
  | jq -r .access_token)

# 3. Read system info
curl -sk https://${BOARD}/api/v1/system/info \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" | jq .

# 4. Run the full example flow
cd examples && source 00_env.sh && bash 01_login.sh
```

All scripts in `examples/` assume a board reachable over HTTPS with a
self-signed certificate (use `--insecure` or mount your CA cert). See
`examples/README.md` for the complete end-to-end walkthrough.

---

## Resource overview

| Group | Resources |
|---|---|
| **Device** | `GET /system/info`, `GET /system/health`, `PUT /system/time`, `PUT /system/network` |
| **Auth** | `POST /auth/login`, `POST /auth/refresh`, `POST /auth/logout`, `POST /auth/password`, `POST /auth/api-keys` |
| **Users & roles** | `GET /users`, `POST /users`, `GET /roles`, `POST /roles`, `GET /audit-log` |
| **Inputs** | `GET /inputs`, `POST /inputs`, `POST /inputs/{id}:probe` |
| **Pipelines** | `GET /pipelines`, `POST /pipelines`, `POST /pipelines/{id}:start`, `POST /pipelines/{id}:stop`, `GET /pipelines/{id}/status` |
| **Detectors** | `GET /detectors/models`, `PUT /pipelines/{id}/detectors/{face\|license_plate\|document}` |
| **Calibration** | `POST /calibrations`, `POST /calibrations/{id}/images`, `POST /calibrations/{id}:compute`, `POST /calibrations/{id}:apply` |
| **Masks** | `POST /pipelines/{id}/masks`, `PATCH /pipelines/{id}/masks/{mask_id}` |
| **Outputs** | `POST /pipelines/{id}/outputs`, `PATCH /pipelines/{id}/outputs/{out_id}` — supports RTSP, UDP, HDMI, shm, file |
| **Power** | `GET /power/metrics`, `GET /power/history`, `PUT /power/policy`, `POST /power/schedules` |
| **Stats** | `GET /stats/summary`, `GET /stats/timeseries`, `GET /stats/export?format=prometheus` |
| **Updates** | `GET /updates/available`, `POST /updates/{id}:install`, `POST /updates/rollback` |
| **Tunnels** | `POST /tunnels`, `POST /tunnels/{id}:connect`, `GET /tunnels/{id}/status` |
| **License** | `POST /license`, `GET /license`, `GET /license/features` |
| **Events** | `GET /events`, `WS /ws` (realtime) |

---

## Key design decisions

- **URI versioning** — `/api/v1/...`
- **RFC 7807 Problem+JSON** — all 4xx/5xx responses, with canonical
  `code` strings (`DETECTOR_UNAVAILABLE`, `HARDWARE_UNSUPPORTED`, etc.)
- **Cursor pagination** — `?limit=…&cursor=…`, `next_cursor` in response
- **ETag + If-Match** — optimistic concurrency on all mutable resources
- **Idempotency-Key** — replay-safe POSTs (create input, pipeline, etc.)
- **JWT + API keys** — interactive users get short-lived JWTs; machines
  use long-lived `X-API-Key` credentials
- **RBAC scopes** — `admin`, `operator`, `viewer`, `service`; fine-grained
  `pipelines:write`, `detectors:read`, etc.
- **Credentials write-only** — RTSP passwords, license keys, API key
  secrets are never returned by GET
- **Realtime** — WebSocket at `WS /ws`; subscribe to `pipeline.status`,
  `power.metrics`, `detector.events`, `updates.jobs`, `tunnels.status`,
  `system.health`

Full details: [`docs/API-DESIGN.md`](docs/API-DESIGN.md)

---

## Licensing

| Artifact | License |
|---|---|
| Firmware / on-device services | Proprietary (commercial EULA) |
| Reference web portal | **AGPL-3.0-only** |
| `openapi.yaml` + `docs/` | **CC-BY-4.0** |
| `examples/` | **CC0-1.0** (public domain) |

Full rationale: [`docs/LICENSING.md`](docs/LICENSING.md)

---

## Validating the spec

```bash
# Install Spectral
npx --yes -p @stoplight/spectral-cli spectral lint openapi.yaml
# Expect: "No results with a severity of 'error' found!"
```

```bash
# Parse YAML only (no external tools needed)
python3 -c "import yaml; yaml.safe_load(open('openapi.yaml'))"
```

---

## OpenAPI tooling

Because the spec is OpenAPI 3.1, it can be used to generate clients,
servers, and documentation with any OpenAPI-capable toolchain:

```bash
# Generate a Python client
npx @openapitools/openapi-generator-cli generate \
  -i openapi.yaml -g python \
  -o ./generated/python

# Generate a TypeScript fetch client
npx @openapitools/openapi-generator-cli generate \
  -i openapi.yaml -g typescript-fetch \
  -o ./generated/ts

# Serve interactive docs
npx @redocly/cli preview-docs openapi.yaml
```
