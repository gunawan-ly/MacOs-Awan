#!/bin/bash
# prepare-macos.sh — Phase 1/4.1: verify macOS runner environment.
# Read-only checks + shell execution test. No secrets involved.
set -eo pipefail

echo "[INFO] macOS setup started"
echo "--- Runner context ---"
echo "RUNNER_OS=${RUNNER_OS:-unknown}"
echo "RUNNER_ARCH=${RUNNER_ARCH:-unknown}"
echo "ImageOS=${ImageOS:-unknown}"
echo "ImageVersion=${ImageVersion:-unknown}"
echo ""
echo "--- macOS version ---"
sw_vers
echo ""
echo "--- CPU architecture ---"
uname -a
uname -m
arch || true
echo ""
echo "--- Active user ---"
whoami
id
echo "SHELL=${SHELL:-unknown}"
echo ""
echo "--- Hostname ---"
hostname
scutil --get ComputerName || true
scutil --get LocalHostName || true
echo ""
echo "--- Disk info ---"
df -h
echo ""
echo "[INFO] macOS verification completed"

echo "[INFO] shell script test started"
cat > /tmp/phase1-test.sh <<'EOF'
#!/bin/bash
echo "[INFO] hello from shell script on macOS"
echo "date: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
echo "bash: $BASH_VERSION"
EOF
chmod +x /tmp/phase1-test.sh
/tmp/phase1-test.sh
bash /tmp/phase1-test.sh
echo "[INFO] shell script test completed"
