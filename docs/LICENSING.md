# Licensing

The AI Camera SDK ships as a small family of artifacts with deliberately
different licenses. This document explains what is licensed how, and why.
When in doubt, the `LICENSE` file next to each artifact is authoritative.

## 1. At a glance

| Artifact                                  | License                    | Where published                   |
|-------------------------------------------|----------------------------|-----------------------------------|
| Firmware / on-device services / SDK       | Proprietary (commercial EULA) | Not on GitHub; shipped with the device |
| Reference web portal                      | **AGPL-3.0-only**          | `github.com/robomotic/ai-camera-portal` |
| `openapi.yaml` (this spec) + `docs/`      | **CC-BY-4.0**              | `github.com/robomotic/ai-camera-sdk` (this repo) |
| `examples/`                               | **CC0-1.0** (public domain)| Same repo as the spec             |

These three tiers are intentional. They are explained below.

## 2. Firmware, SDK, on-device services — proprietary EULA

The binary that actually runs on the camera board — the control-plane
server implementing this API, the media pipeline glue, the vendor SDK
bindings (NVIDIA DeepStream, Ambarella, HAILO), model weights, and the
commercial feature gating — is **closed-source** and covered by the
commercial **AI Camera SDK End-User License Agreement** (EULA) that
accompanies the device.

Rationale:

- Model weights and parts of the vendor SDKs are themselves covered by
  third-party restrictive licenses that preclude redistribution under a
  permissive or copyleft license.
- Hardware-bound licensing (the `/license` resource) requires the
  on-device code path to be tamper-resistant.
- Support obligations and certification (EMC, safety, privacy) are tied
  to specific binary images.

The firmware source is not published to GitHub. Customers receive
signed firmware images and have the right to run them on their devices
under the terms of the EULA.

## 3. Web portal — AGPL-3.0-only

The reference **web portal** (the browser UI that consumes this API)
is the only end-user-facing open-source artifact, and it is licensed
under **GNU Affero General Public License v3.0 only** (AGPL-3.0-only,
SPDX: `AGPL-3.0-only`).

Rationale:

- The portal is a *control surface*. Customers have a legitimate
  interest in auditing the code that talks to their cameras,
  self-hosting it inside their network, and modifying it.
- The AGPL's network-use clause (§13) ensures that any party who
  operates a **hosted / SaaS fork** of the portal must release their
  modifications to the users of that service. Without §13 a competitor
  could host a proprietary managed version of the portal and keep
  improvements private.
- Strong precedent for this exact pattern: **GitLab CE**, **Nextcloud**,
  **Mastodon**, older **Grafana**, **Plausible Analytics**. All use
  AGPL-3.0 for the web UI / control surface and a separate commercial
  license for their SaaS / enterprise tier.

### Practical rules for portal contributors

- `LICENSE` in the portal repo is the verbatim AGPL-3.0 text.
- `NOTICE` lists third-party dependencies and their licenses.
  Pay particular attention to GPL-incompatible licenses (e.g. older CDDL
  components, SSPL); if added they must be isolated via network
  boundaries or vendored out.
- Contribution model: **Developer Certificate of Origin** (DCO) on
  commits (`Signed-off-by:`). A CLA is explicitly rejected to keep the
  barrier to contribution low and to make clear that Robomotic does not
  hold a unilateral right to relicense contributions.
- Downstream forks are welcome. If you redistribute, you must comply
  with AGPL §4–§6 (source availability) and §13 (network service
  modifications).

## 4. OpenAPI spec and docs — CC-BY-4.0

This file, `openapi.yaml`, and everything under `docs/` are licensed
under **Creative Commons Attribution 4.0 International** (CC-BY-4.0,
SPDX: `CC-BY-4.0`).

This choice is deliberate and, critically, **different** from the
portal's AGPL-3.0. The OpenAPI document must be usable by third-party
developers to generate compatible clients in Python, Go, TypeScript,
Rust, Swift, etc., without any obligation to release the resulting
client code under the AGPL.

- CC-BY-4.0 imposes only attribution; it does not touch the licensing
  of derived code. The output of an OpenAPI generator fed with this
  spec is **not** a derivative work of any AGPL software.
- Robomotic retains copyright. Attribution must be preserved.
- The same reasoning applies to `docs/API-DESIGN.md` so that its prose
  conventions can be quoted, translated, and referenced freely.

This is the pattern used by, among others, **Stripe**, **GitHub**,
**DigitalOcean**, and **OpenAI** for their public API references: the
service is proprietary, the SDKs are permissive, and the spec itself is
openly licensed so the ecosystem of clients can thrive.

The OpenAPI `info.license` field in `openapi.yaml` therefore advertises
**CC-BY-4.0**, not AGPL-3.0. This is *not* a contradiction with the
portal being AGPL — they are different artifacts.

## 5. Examples — CC0-1.0

Everything under `examples/` (shell scripts, curl flows, sample JSON) is
dedicated to the public domain under **CC0-1.0** so that integrators
can copy snippets into their own codebases with zero attribution
overhead. The snippets are small and have no creative threshold that
would benefit from stronger licensing.

## 6. The commercial license key (`/license` endpoints)

There is a second meaning of the word "license" in this product: the
**commercial license key** that unlocks paid features (extra detectors,
higher stream counts, SeLink tunnels, enterprise SSO). That key:

- Is hardware-bound: a key is valid only for the SoC serial it was
  issued against.
- Has an expiry and an offline grace period; `/license:refresh`
  performs an online refresh when the device can reach the licensing
  server.
- Is managed by the `/license` resource. Keys are accepted via
  `POST /license` and are **never** returned by GET.

This is entirely independent of the software licenses above. A customer
with an expired commercial key can still run, fork and audit the
AGPL portal, and can still build compatible clients from the CC-BY spec;
they just cannot enable the paid feature flags on the device.

## 7. Third-party components

Both the portal and the spec will list their third-party dependencies in
`NOTICE` files alongside the `LICENSE` text. Dependencies that are
**incompatible with AGPL-3.0** (e.g. proprietary-only, SSPL where it
matters, some older CC-NC content) must not be bundled into the portal.
Dependencies are reviewed during the PR process.

## 8. Changing the license

Relicensing any of these artifacts (in particular the portal) requires:

- Unanimous consent of the copyright holders, which — because the
  portal uses DCO and does not collect a CLA — means every contributor
  whose commits are still present in the codebase.
- In practice this is equivalent to committing to the current license
  for the life of the project. That is the intended effect.

## 9. Summary

- **Firmware**: closed, commercial EULA, hardware-bound.
- **Portal**: AGPL-3.0-only, network-use copyleft protects against
  proprietary SaaS forks.
- **Spec + docs**: CC-BY-4.0, so the ecosystem of compatible clients is
  unencumbered.
- **Examples**: CC0-1.0, copy freely.
- **Commercial license keys**: a separate product concept, managed via
  the `/license` API, orthogonal to all of the above.
