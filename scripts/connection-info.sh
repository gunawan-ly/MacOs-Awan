#!/bin/bash
# connection-info.sh — Phase 4.8: print the remote-access banner.
# Prints the AnyDesk ID (required to connect) and non-sensitive status.
# NEVER prints passwords, auth keys, or other secrets.
set -eo pipefail

ANYDESK_ID=$(cat /tmp/anydesk-id)
AD_STATUS=$(cat /tmp/anydesk-status 2>/dev/null || echo "unknown")
TS_IP=$(tailscale ip -4 2>/dev/null | head -1 || echo "unknown")
echo "================================"
echo "ANYDESK REMOTE ACCESS"
echo "================================"
echo ""
echo "AnyDesk ID:"
echo "$ANYDESK_ID"
echo ""
echo "Status:"
echo "$AD_STATUS"
echo ""
echo "Runner:"
sw_vers | head -2
uname -m
echo ""
echo "Tailscale IP (diagnostic layer):"
echo "$TS_IP"
echo ""
echo "Keep-alive:"
echo "ACTIVE"
echo ""
echo "Connect from Android using AnyDesk + unattended password."
echo "[INFO] Connection information available"
