#!/bin/bash

# Real-time log monitoring script for debugging
echo "=== Real-time Log Monitor for HelperPOC ==="
echo "Monitoring app and daemon logs..."
echo "Press Ctrl+C to stop"
echo ""

PROJECT_DIR="$(pwd)"
APP_LOG="${PROJECT_DIR}/logs/helperpoc-app.log"
DAEMON_LOG="/tmp/helperpoc-daemon.log"

# Ensure log files exist
mkdir -p "${PROJECT_DIR}/logs"
touch "$APP_LOG"
touch "$DAEMON_LOG"

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${BLUE}App Log: $APP_LOG${NC}"
echo -e "${GREEN}Daemon Log: $DAEMON_LOG${NC}"
echo ""

# Monitor both logs simultaneously with prefixes
(
    tail -f "$APP_LOG" | sed 's/^/[APP] /' &
    APP_PID=$!
    
    tail -f "$DAEMON_LOG" | sed 's/^/[DAEMON] /' &
    DAEMON_PID=$!
    
    # Wait for Ctrl+C
    trap "kill $APP_PID $DAEMON_PID 2>/dev/null; exit" INT
    wait
)