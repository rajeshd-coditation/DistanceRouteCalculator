#!/bin/bash

# Background runner for OSRM setup with monitoring
# Usage: ./scripts/run_background.sh

set -e

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

# Check if run.sh exists
if [ ! -f "run.sh" ]; then
    print_error "run.sh not found. Please run from project root directory."
    exit 1
fi

# Create logs directory
mkdir -p logs

# Clean up old logs and PID files
print_status "Cleaning up old logs and PID files..."
rm -f logs/osrm_setup_*.log 2>/dev/null || true
rm -f logs/osrm_setup.pid 2>/dev/null || true
print_success "Old logs cleaned up"

# Generate timestamp for this run
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="logs/osrm_setup_${TIMESTAMP}.log"
PID_FILE="logs/osrm_setup.pid"

print_status "Starting OSRM setup in background..."
print_status "Log file: $LOG_FILE"
print_status "PID file: $PID_FILE"

# Make run.sh executable
chmod +x run.sh

# Start the process in background
nohup ./run.sh > "$LOG_FILE" 2>&1 &
PID=$!

# Save PID
echo $PID > "$PID_FILE"

print_success "OSRM setup started in background (PID: $PID)"
print_status "Monitor progress with: ./scripts/monitor_setup.sh"
print_status "Check logs with: tail -f $LOG_FILE"
print_status "Stop setup with: ./scripts/stop_setup.sh"

echo ""
echo "📋 Quick Commands:"
echo "  Monitor:    ./scripts/monitor_setup.sh"
echo "  Stop:       ./scripts/stop_setup.sh"
echo "  Logs:       tail -f $LOG_FILE"
echo "  Status:     ps -p $PID"
echo ""
