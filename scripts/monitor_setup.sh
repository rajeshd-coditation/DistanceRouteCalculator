#!/bin/bash

# Monitor OSRM setup progress
# Usage: ./scripts/monitor_setup.sh

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if PID file exists
PID_FILE="logs/osrm_setup.pid"
if [ ! -f "$PID_FILE" ]; then
    print_error "No background setup process found (PID file missing)"
    print_status "Start setup with: ./scripts/run_background.sh"
    exit 1
fi

# Read PID
PID=$(cat "$PID_FILE")

# Check if process is running
if ! ps -p $PID > /dev/null 2>&1; then
    print_error "Setup process (PID: $PID) is not running"
    print_status "Check logs for errors: tail -f logs/osrm_setup_*.log"
    exit 1
fi

print_success "Setup process is running (PID: $PID)"

# Find the latest log file
LATEST_LOG=$(ls -t logs/osrm_setup_*.log 2>/dev/null | head -1)
if [ -z "$LATEST_LOG" ]; then
    print_error "No log files found"
    exit 1
fi

# Show log file info
LOG_SIZE=$(du -h "$LATEST_LOG" | cut -f1)
LOG_LINES=$(wc -l < "$LATEST_LOG")

print_status "Monitoring log: $LATEST_LOG"
print_status "Log size: $LOG_SIZE, Lines: $LOG_LINES"
print_status "Press Ctrl+C to stop monitoring"
echo ""

# Show last few lines before tailing
print_status "=== Last 10 lines ==="
tail -10 "$LATEST_LOG"
echo ""
print_status "=== Live monitoring (new lines will appear below) ==="
echo ""

# Monitor the log file
tail -f "$LATEST_LOG"
