# AI Camera SDK — curl examples

This directory walks through a single coherent end-to-end flow against
the control-plane API described in [`../openapi.yaml`](../openapi.yaml).

Run the scripts in numeric order; each one reuses values (`$BOARD`,
`$ACCESS_TOKEN`, resource IDs) exported by `00_env.sh` and the preceding
steps.

```
00_env.sh               # one-time: edit BOARD/USER/PASSWORD, then `source 00_env.sh`
01_login.sh             # POST /auth/login        → $ACCESS_TOKEN, $REFRESH_TOKEN
02_create_input.sh      # POST /inputs            → $INPUT_ID
03_create_pipeline.sh   # POST /pipelines         → $PIPELINE_ID
04_enable_face_detector.sh  # PUT  /pipelines/{id}/detectors/face
05_add_rectangle_mask.sh    # POST /pipelines/{id}/masks
06_add_rtsp_output.sh       # POST /pipelines/{id}/outputs → $OUTPUT_ID
07_start_pipeline.sh        # POST /pipelines/{id}:start
08_get_stats.sh             # GET  /stats/summary, /stats/pipelines/{id}
09_apply_license.sh         # POST /license
```

All scripts assume the board speaks HTTPS with a self-signed certificate
by default, hence `--insecure` in the curl invocations. Replace with
`--cacert /path/to/ca.pem` once the device has a proper certificate.

License: these examples are dedicated to the public domain under
CC0-1.0; copy freely.
