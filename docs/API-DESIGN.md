# AI Camera SDK Control API — Design Notes

This document complements [`openapi.yaml`](../openapi.yaml). The YAML file is
the machine-readable source of truth; this document explains the *why* and
covers the parts of the API (realtime, RBAC matrix, rate limiting) that do
not fit cleanly into OpenAPI 3.1 itself.

## 1. Scope and non-goals

The REST API is the **control plane** for an `ai-camera-sdk` device. It
configures inputs, pipelines, detectors, masks, outputs, calibration,
power, updates, tunnels, and licensing; it exposes stats, events and
health; and it manages users, roles and API keys.

The media plane is **out of scope**. Capture (USB, CSI, RTSP), processing
(DeepStream / accelerator SDKs) and delivery (RTSP, UDP, HDMI, shm, file)
are handled by GStreamer and NVIDIA / vendor shared memory. The API only
**describes** media resources; it does not stream bytes.

Target hardware (detector availability varies per platform):

- NVIDIA Jetson Nano
- Ambarella CV-series
- Raspberry Pi with HAILO accelerator

## 2. Versioning

- URI versioning: all endpoints live under `/api/v1/...`.
- Breaking changes bump the major version and live at `/api/v2/...`
  alongside `/api/v1/...` during a deprecation window.
- Additive, backwards-compatible changes ship within the same version.
- The OpenAPI `info.version` uses SemVer (`1.0.0`, `1.1.0`, …) and is
  advertised in `GET /system/info` as `api_version`.

## 3. Transport

- HTTPS only. The device ships with a self-signed certificate; a
  (future) certificate-rotation endpoint will allow operators to install
  their own CA-signed cert.
- Default content type: `application/json; charset=utf-8`.
- Binary uploads (calibration images, license files) use
  `multipart/form-data`.
- Unauthenticated probes: `GET /healthz` (liveness) and
  `GET /readyz` (readiness). Everything else requires auth.

## 4. Authentication

Two mechanisms coexist:

### 4.1 JWT for interactive users

- `POST /auth/login` returns `{access_token, refresh_token, token_type,
  expires_in}`.
- Access tokens are short-lived (default 15 minutes); refresh tokens are
  long-lived (default 30 days) and are rotated on each refresh.
- JWT claims: `sub`, `roles`, `scope` (space-separated), `exp`, `iat`,
  `jti`. The `jti` is recorded so refresh tokens can be revoked.
- `POST /auth/logout` revokes the current refresh token.
- `POST /auth/password` changes the caller's own password; admins can
  reset others via `POST /users/{id}:reset-password`.

### 4.2 API keys for machines

- Created under `POST /auth/api-keys` and scoped per-key.
- Sent as `X-API-Key: <secret>`. The secret is **returned only once**
  (`ApiKeyCreated.secret`); subsequent `GET` operations expose only the
  `prefix`.
- API keys may have an `expires_at` and are revoked via `DELETE
  /auth/api-keys/{id}`.

Both schemes are accepted on any authenticated endpoint. The OpenAPI
`security` array lists both so generators can emit either.

## 5. Authorization (RBAC)

Authorization is scope-based. Each endpoint documents its required
scopes via `x-required-scopes`. Roles aggregate scopes; users are
assigned roles.

### 5.1 Built-in roles

| Role       | Intent                                                    |
|------------|-----------------------------------------------------------|
| `admin`    | Full control, including user mgmt, licensing, updates.    |
| `operator` | Pipeline/detector/mask/output/calibration control + stats |
| `viewer`   | Read-only across the control plane.                       |
| `service`  | Machine identity (API key); scopes assigned per key.      |

### 5.2 Scope catalogue

Scopes follow `<domain>:<verb>` where verb is one of `read`, `write`,
`operate`, `admin`.

| Domain       | read | write | operate | admin |
|--------------|:----:|:-----:|:-------:|:-----:|
| `system`     | viewer+ | — | — | admin |
| `users`      | admin | — | — | admin |
| `roles`      | admin | — | — | admin |
| `audit`      | admin | — | — | — |
| `api_keys`   | self  | self  | — | admin |
| `inputs`     | viewer+ | operator+ | — | — |
| `pipelines`  | viewer+ | operator+ | operator+ | — |
| `detectors`  | viewer+ | operator+ | — | — |
| `calibration`| viewer+ | operator+ | — | — |
| `masks`      | viewer+ | operator+ | — | — |
| `outputs`    | viewer+ | operator+ | — | — |
| `power`      | viewer+ | operator+ | — | — |
| `stats`      | viewer+ | — | — | admin |
| `updates`    | viewer+ | admin | — | — |
| `tunnels`    | viewer+ | — | operator+ | admin |
| `license`    | viewer+ | — | — | admin |
| `events`     | viewer+ | — | — | — |

A 401 is returned for missing/invalid credentials. A 403 is returned
when authenticated but lacking the required scope; the problem body
carries `code: FORBIDDEN` and lists the missing scope in `detail`.

## 6. Errors (RFC 7807)

All 4xx/5xx responses use `application/problem+json` and the `Problem`
schema. Mandatory fields: `type`, `title`, `status`. Vendor extensions:

- `code` — canonical machine-readable code (see enum in `Problem.code`).
- `trace_id` — server-assigned trace identifier for log correlation.
- `errors[]` — present when `code=VALIDATION_FAILED`, one entry per
  failing field (`{field, message, rule}`).

Canonical codes and their typical HTTP status:

| Code                    | HTTP | Example cause                                              |
|-------------------------|:----:|------------------------------------------------------------|
| `AUTH_REQUIRED`         | 401  | Missing or expired access token.                           |
| `FORBIDDEN`             | 403  | Missing scope for this operation.                          |
| `VALIDATION_FAILED`     | 400  | Body or query parameters violate schema.                   |
| `NOT_FOUND`             | 404  | Resource id does not exist.                                |
| `CONFLICT`              | 409  | Duplicate name, delete blocked by references.              |
| `PRECONDITION_FAILED`   | 412  | `If-Match` ETag mismatch.                                  |
| `RATE_LIMITED`          | 429  | Client exceeded the rate limit.                            |
| `LICENSE_INVALID`       | 409  | License key not bound to this hardware, expired, tampered. |
| `FEATURE_DISABLED`      | 409  | Feature gated by the active license plan.                  |
| `HARDWARE_UNSUPPORTED`  | 409  | Feature not supported by the underlying SoC.               |
| `DETECTOR_UNAVAILABLE`  | 409  | Detector variant not shipped for this platform.            |
| `PIPELINE_BUSY`         | 409  | Pipeline is running; stop it first.                        |
| `DEPENDENCY_NOT_READY`  | 503  | Upstream subsystem (e.g. accelerator) is not ready.        |
| `INTERNAL`              | 500  | Unhandled server error.                                    |

Example:

```json
{
  "type": "https://docs.ai-camera-sdk.io/errors/detector-unavailable",
  "title": "Detector not available on this hardware",
  "status": 409,
  "code": "DETECTOR_UNAVAILABLE",
  "detail": "document detector requires NVIDIA accelerator; current hw: rpi-hailo",
  "instance": "/api/v1/pipelines/01HF8Z.../detectors/document",
  "trace_id": "01HF8Z8W9Q4J7K5N2V3X6M1T0B"
}
```

## 7. Pagination, filtering, sorting

- Cursor pagination: `?limit=<n>&cursor=<opaque>`; responses include
  `next_cursor` (null on last page). `total` is included only when it
  is cheap to compute.
- Sorting: `?sort=<field>` or `?sort=-<field>` for descending.
- Filtering: `?filter[field]=value`. Multi-value filters use repeated
  keys: `?filter[state]=running&filter[state]=starting`.
- Server-side max `limit` is 200; default 50.

## 8. Concurrency and idempotency

- Mutable resources return an `ETag` header on GET. Clients may send
  `If-Match: <etag>` on `PATCH`/`PUT`/`DELETE`; the server returns **412
  Precondition Failed** on mismatch.
- POST-creation endpoints accept `Idempotency-Key: <string>`. A replay
  with the same key within the idempotency window (24 h) returns the
  original response. Different keys with identical bodies are treated
  as independent requests.
- Long-running operations (`:start`, `:stop`, `:install`, `:connect`,
  `:reboot`, `:shutdown`) return **202 Accepted** immediately. Progress
  is available via the corresponding `/status` endpoint or the
  WebSocket channel.

## 9. Rate limiting

All authenticated endpoints are rate-limited per principal (user or API
key). Responses carry:

- `X-RateLimit-Limit` — quota for the current window.
- `X-RateLimit-Remaining` — requests left.
- `X-RateLimit-Reset` — seconds until the window resets.

A 429 response also includes `Retry-After`. The problem body uses
`code: RATE_LIMITED`. Default quota is 600 req/min/principal; this can
be tightened by operators. WebSocket connections count as 1 request each.

## 10. Request correlation

- Clients should send `X-Request-Id: <opaque>`. Servers echo it and,
  when absent, generate one.
- The same id appears in the `trace_id` of any error reply, making
  client/server log correlation straightforward.

## 11. Realtime (WebSocket `/ws`)

The spec's `x-websocket` extension describes the channel. Prose details:

- URL: `wss://<board>/api/v1/ws`.
- Authentication: either `?access_token=<jwt>` or, for browsers that
  cannot set arbitrary headers, `Sec-WebSocket-Protocol: bearer,<jwt>`.
  API keys may be supplied via `Sec-WebSocket-Protocol: apikey,<secret>`.
- After connection the client **must** send a subscribe frame within
  10 seconds, else the server closes the socket with code 4001.
- Frame shapes:
  ```json
  // client → server
  { "op": "subscribe",   "channels": ["pipeline.status", "power.metrics"] }
  { "op": "unsubscribe", "channels": ["power.metrics"] }
  { "op": "ping" }

  // server → client
  { "channel": "pipeline.status", "ts": "2026-04-18T09:02:39Z",
    "data": { "pipeline_id": "01HF...", "state": "running", "fps_in": 29.9 } }
  { "op": "pong" }
  { "op": "error", "code": "FORBIDDEN", "detail": "missing scope events:read" }
  ```
- Heartbeat: server sends a ping every 20 s; the server closes idle
  sockets after 60 s. Clients should answer with `{op:"pong"}`.
- Close codes: `4000` malformed frame, `4001` no subscription, `4003`
  unauthorized, `4008` rate limited, `4011` server restart.

OpenAPI 3.1's `webhooks` is **not** used here: webhooks describe
server-initiated HTTP callbacks to a URL owned by the caller, which is
the opposite of a persistent authenticated socket.

## 12. Resource model summary

| Resource          | Path prefix                               | Owner scope      |
|-------------------|-------------------------------------------|------------------|
| System            | `/system/*`, `/healthz`, `/readyz`        | `system`         |
| Auth & tokens     | `/auth/*`, `/me`                          | —                |
| Users & roles     | `/users`, `/roles`, `/audit-log`          | `users`, `roles` |
| Inputs            | `/inputs`                                 | `inputs`         |
| Pipelines         | `/pipelines`                              | `pipelines`      |
| Detectors         | `/pipelines/{id}/detectors/{type}`, `/detectors/models` | `detectors` |
| Calibration       | `/calibrations`                           | `calibration`    |
| Masks             | `/pipelines/{id}/masks`                   | `masks`          |
| Outputs           | `/pipelines/{id}/outputs`                 | `outputs`        |
| Power             | `/power/*`                                | `power`          |
| Stats             | `/stats/*`                                | `stats`          |
| Updates           | `/updates/*`                              | `updates`        |
| Tunnels           | `/tunnels`                                | `tunnels`        |
| License           | `/license`, `/license/features`           | `license`        |
| Events (history)  | `/events`                                 | `events`         |
| Events (realtime) | `WSS /ws` (see §11)                       | `events`         |

## 13. Sensitive data handling

- RTSP credentials on inputs are write-only (`credentials.password` is
  `writeOnly: true`) and are stored in an on-device secret store. Any
  password embedded in a response URI is masked as `***`.
- API key secrets are returned only on creation. `GET` responses
  expose `prefix` (first 8 chars) so the UI can disambiguate keys.
- License keys are `writeOnly` on the activation payload; `GET
  /license` returns status and hardware binding, never the raw key.
- Audit log entries record actor + action; they do **not** record
  request bodies.

## 14. Hardware-conditional behaviour

Detector availability and some calibration/output options vary per
platform. Endpoints that can fail on an otherwise correct request
because of the hardware return:

- `409 Conflict` with `code: DETECTOR_UNAVAILABLE` for detectors not
  shipped on the current platform (e.g. `document` on `rpi-hailo`).
- `409 Conflict` with `code: HARDWARE_UNSUPPORTED` for generic features
  (e.g. HDMI output on a board without HDMI).

`GET /detectors/models` lists the catalogue with `platforms: [...]` so
clients can hide or disable controls up front.

## 15. OpenAPI conventions used

- Every operation has `operationId` (camelCase, globally unique),
  `summary`, `tags`, and `security`.
- Documented 4xx responses: every authenticated endpoint lists `401`
  and `403`; write endpoints list `400`, `409` and `412` as applicable.
- `x-required-scopes` is the authoritative list of RBAC scopes; the
  `security` array stays generic (bearer or api-key).
- Shared parameters (`Cursor`, `Limit`, `Filter`, `Sort`, `IfMatch`,
  `IdempotencyKey`, `RequestId`) are declared under
  `components.parameters` and referenced by every operation that uses
  them.
- `components.responses` holds reusable error responses.
- Action-style endpoints use the `:verb` convention (e.g.
  `/pipelines/{id}:start`), following Google's AIP-136, because the
  action is **not** a sub-resource and reusing POST on a collection
  would be ambiguous.

## 16. Versioning of this document

Changes that materially affect the wire protocol bump `openapi.yaml`
`info.version`. Editorial changes to this document are tracked via Git
history only.
