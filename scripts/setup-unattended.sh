#!/bin/bash
# setup-unattended.sh — Phase 4.4: configure AnyDesk Unattended Access.
# Password comes ONLY from the ANYDESK_PASSWORD environment variable
# (mapped from the GitHub Secret in the workflow). Never hardcoded,
# never printed: only its length is logged. Unset immediately after use.
set -eo pipefail

echo "[INFO] Unattended access configuration started"
if [ -z "${ANYDESK_PASSWORD:-}" ]; then
  echo "::error::FAIL - ANYDESK_PASSWORD secret is missing. Create it in repo Settings > Secrets > Actions."
  exit 1
fi
PWLEN=${#ANYDESK_PASSWORD}
echo "[INFO] Password length check: ${PWLEN} chars (value never printed)"
if [ "$PWLEN" -lt 8 ]; then
  echo "::error::FAIL - ANYDESK_PASSWORD must be at least 8 characters (12+ recommended)."
  exit 1
fi
  AD_BIN=$(cat /tmp/anydesk-bin)
  echo "[INFO] Setting password (backend may need time after resume, max 60s)"
  SET_OK=0
  for i in $(seq 1 6); do
    if printf '%s' "$ANYDESK_PASSWORD" | sudo "$AD_BIN" --set-password 2>/tmp/anydesk-setpw.err; then
      SET_OK=1
      break
    fi
    echo "[INFO] Attempt $i: backend not ready ($(cat /tmp/anydesk-setpw.err 2>/dev/null || echo unknown)), retrying..."
    sleep 10
  done
  unset ANYDESK_PASSWORD
  if [ "$SET_OK" -ne 1 ]; then
    echo "::error::FAIL - AnyDesk backend never became ready: $(cat /tmp/anydesk-setpw.err 2>/dev/null || echo unknown)"
    exit 1
  fi
echo "[INFO] Unattended access password configured"
