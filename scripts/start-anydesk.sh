#!/bin/bash
# start-anydesk.sh — Phase 4.3: launch AnyDesk with bounded attempts.
# - Direct-path launch (LaunchServices name lookup is unreliable fresh install)
# - lsregister fallback + retry
# - Resumes the process if macOS leaves it suspended (state T)
# - Direct-binary fallback if it stays suspended
# - FAIL fast if no running process (no silent cascade)
# Every wait is bounded; nothing here blocks forever.
set -eo pipefail

launch_ad() {
  open "/Applications/AnyDesk.app" > /tmp/anydesk-open.log 2>&1 &
  OPENPID=$!
  OELAPSED=0
  while kill -0 $OPENPID 2>/dev/null; do
    pgrep -x AnyDesk >/dev/null && break
    if [ "$OELAPSED" -ge 60 ]; then
      echo "[WARN] open blocked over 60s, detaching (launched app is unaffected)"
      kill -KILL $OPENPID 2>/dev/null || true
      break
    fi
    sleep 5
    OELAPSED=$((OELAPSED + 5))
  done
  if kill -0 $OPENPID 2>/dev/null; then
    kill -KILL $OPENPID 2>/dev/null || true
  fi
  wait $OPENPID 2>/dev/null || true
  cat /tmp/anydesk-open.log || true
}

echo "[INFO] Starting AnyDesk via direct path (bounded launch, max 60s per attempt)"
launch_ad
if ! pgrep -x AnyDesk >/dev/null; then
  echo "[WARN] Direct launch not detected, fallback: lsregister + retry"
  /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "/Applications/AnyDesk.app" || true
  launch_ad
fi
sleep 5
ps aux | grep -i "[A]nyDesk" || true
if ! pgrep -x AnyDesk >/dev/null; then
  echo "::error::FAIL - AnyDesk process not running after launch attempts"
  exit 1
fi
AD_BIN=$(cat /tmp/anydesk-bin)
AD_PID=$(pgrep -x AnyDesk | head -1)
AD_STAT=$(ps -o stat= -p "$AD_PID" 2>/dev/null | tr -d ' ' || echo "?")
echo "[INFO] AnyDesk pid=$AD_PID state=$AD_STAT (T means stopped/suspended)"
case "$AD_STAT" in
  *T*)
    echo "[INFO] Process is stopped, sending CONT to resume"
    kill -CONT "$AD_PID" 2>/dev/null || true
    sleep 3
    AD_STAT=$(ps -o stat= -p "$AD_PID" 2>/dev/null | tr -d ' ' || echo "?")
    echo "[INFO] State after CONT: $AD_STAT"
    ;;
esac
case "$AD_STAT" in
  *T*)
    echo "[WARN] Still stopped after CONT, fallback: relaunch binary directly"
    kill -KILL "$AD_PID" 2>/dev/null || true
    sleep 2
    nohup "$AD_BIN" > /tmp/anydesk-app.log 2>&1 &
    for i in $(seq 1 12); do
      pgrep -x AnyDesk >/dev/null && break
      sleep 5
    done
    AD_PID=$(pgrep -x AnyDesk | head -1 || true)
    if [ -z "$AD_PID" ]; then
      echo "::error::FAIL - AnyDesk will not stay running (stopped state, no backend)"
      exit 1
    fi
    AD_STAT=$(ps -o stat= -p "$AD_PID" 2>/dev/null | tr -d ' ' || echo "?")
    echo "[INFO] Relaunched pid=$AD_PID state=$AD_STAT"
    case "$AD_STAT" in
      *T*) echo "::error::FAIL - AnyDesk process stays suspended, backend cannot start"; exit 1;;
    esac
    ;;
esac
echo "[INFO] AnyDesk start phase completed"
