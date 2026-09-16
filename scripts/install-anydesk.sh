#!/bin/bash
# install-anydesk.sh — Phase 4.2: install official AnyDesk via Homebrew cask.
# Detects CPU architecture dynamically (no Intel/ARM assumption).
# Writes the resolved CLI path to /tmp/anydesk-bin for later steps.
set -eo pipefail

echo "[INFO] AnyDesk installation started"
echo "[INFO] Architecture detected:"
uname -m
export HOMEBREW_NO_AUTO_UPDATE=1
brew install --cask anydesk
echo "[INFO] Verifying installation"
ls -la /Applications/AnyDesk.app || { echo "::error::FAIL - /Applications/AnyDesk.app missing after install"; exit 1; }
AD_BIN="/Applications/AnyDesk.app/Contents/MacOS/AnyDesk"
if [ ! -x "$AD_BIN" ]; then
  echo "[INFO] Default CLI path missing, searching bundle"
  AD_BIN=$(find /Applications/AnyDesk.app -name AnyDesk -type f -perm +111 2>/dev/null | head -1)
fi
if [ -z "$AD_BIN" ] || [ ! -x "$AD_BIN" ]; then
  echo "::error::FAIL - AnyDesk executable not found in bundle"
  exit 1
fi
echo "$AD_BIN" > /tmp/anydesk-bin
  echo "[INFO] CLI path: $AD_BIN"
  "$AD_BIN" --version || { echo "::error::FAIL - AnyDesk binary will not run"; exit 1; }
  echo "--- CLI capabilities probe (looking for service install options) ---"
  "$AD_BIN" --help 2>&1 || true
  echo "[INFO] AnyDesk installation completed"
