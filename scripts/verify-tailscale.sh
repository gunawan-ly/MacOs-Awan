#!/bin/bash
# verify-tailscale.sh — Phase 2: print non-sensitive Tailscale identity.
# No secrets are read or printed here.
set -eo pipefail

echo "[INFO] Tailscale setup started"
tailscale ip -4
tailscale status --self=true || tailscale status
echo "[INFO] Tailscale connected"
