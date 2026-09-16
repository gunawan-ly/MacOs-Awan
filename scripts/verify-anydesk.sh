#!/bin/bash
# verify-anydesk.sh — Phase 4.5/4.6: verify AnyDesk ID + online status.
# FAIL fast when no ID is issued (nothing downstream can work without it).
# A non-online status is WARN-only: the Android connection test is the real judge.
set -eo pipefail

echo "[INFO] Waiting for AnyDesk ID (max 60s)"
AD_BIN=$(cat /tmp/anydesk-bin)
ANYDESK_ID=""
for i in $(seq 1 12); do
  ANYDESK_ID=$("$AD_BIN" --get-id 2>/dev/null || true)
  if [ -n "$ANYDESK_ID" ]; then
    break
  fi
  echo "[INFO] Attempt $i: ID empty, retrying..."
  sleep 5
done
if [ -z "$ANYDESK_ID" ]; then
  echo "::error::FAIL - AnyDesk did not obtain an ID"
  exit 1
fi
echo "$ANYDESK_ID" > /tmp/anydesk-id
echo "[INFO] AnyDesk ID obtained: $ANYDESK_ID"

echo "[INFO] AnyDesk status diagnostics"
"$AD_BIN" --version || true
echo "--- online status (max 60s) ---"
AD_STATUS=""
for i in $(seq 1 12); do
  AD_STATUS=$("$AD_BIN" --get-status 2>/dev/null || true)
  echo "[INFO] Attempt $i status: ${AD_STATUS:-empty}"
  echo "$AD_STATUS" | grep -qi "online" && break
  sleep 5
done
echo "$AD_STATUS" > /tmp/anydesk-status
echo "--- processes ---"
ps aux | grep -i "[A]nyDesk" || echo "no AnyDesk process"
echo "--- service presence (full install indicator) ---"
ls /Library/LaunchDaemons/ 2>/dev/null | grep -i anydesk || echo "no AnyDesk LaunchDaemon (portable install)"
echo "--- session context ---"
stat -f %Su /dev/console || true
echo "[INFO] AnyDesk status diagnostics completed"
