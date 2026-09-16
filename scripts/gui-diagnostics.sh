#!/bin/bash
# gui-diagnostics.sh — read-only macOS GUI/session context.
# Used for permission analysis (Screen Recording / Accessibility).
# Makes no system changes.
set -eo pipefail

echo "[INFO] GUI session diagnostics (read-only context for permission analysis)"
who || true
echo "--- console owner ---"
stat -f %Su /dev/console || true
echo "--- WindowServer ---"
ps aux | grep -i "[W]indowServer" || echo "no WindowServer process found"
echo "--- displays ---"
system_profiler SPDisplaysDataType 2>/dev/null | head -20 || echo "no displays detected"
echo "[INFO] GUI session diagnostics completed"
