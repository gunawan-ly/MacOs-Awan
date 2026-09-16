#!/bin/bash
# keep-alive.sh — keep the runner alive while the remote session is in use.
# Runs ONLY after the full setup succeeded. Cancel the workflow to stop.
# GitHub caps the job at 6h (timeout-minutes in the workflow).
set -eo pipefail

echo "[INFO] Keep-alive started - cancel workflow manually to stop (max 6h GitHub limit)"
echo "[INFO] AnyDesk + Tailscale remain running during keep-alive"
while true; do
  echo "[INFO] Alive at $(date -u '+%Y-%m-%d %H:%M:%S UTC') - workflow ready"
  sleep 60
done
