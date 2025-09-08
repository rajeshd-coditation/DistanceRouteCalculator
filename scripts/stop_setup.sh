#!/bin/bash

# Stop OSRM setup process
# Usage: ./scripts/stop_setup.sh

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
    print_warning "No background setup process found (PID file missing)"
    exit 0
fi

# Read PID
PID=$(cat "$PID_FILE")

# Check if process is running
if ! ps -p $PID > /dev/null 2>&1; then
    print_warning "Setup process (PID: $PID) is not running"
    rm -f "$PID_FILE"
    exit 0
fi

print_status "Stopping setup process (PID: $PID)..."

# Try graceful termination first
kill -TERM $PID

# Wait for process to stop
sleep 5

# Check if still running
if ps -p $PID > /dev/null 2>&1; then
    print_warning "Process still running, forcing termination..."
    kill -KILL $PID
    sleep 2
fi

# Final check
if ps -p $PID > /dev/null 2>&1; then
    print_error "Failed to stop process (PID: $PID)"
    exit 1
else
    print_success "Setup process stopped successfully"
    rm -f "$PID_FILE"
fi

# Also stop any running Docker containers
print_status "Stopping any running Docker containers..."
docker stop $(docker ps -q) 2>/dev/null || true
docker rm $(docker ps -aq) 2>/dev/null || true

# Specifically clean up OSRM containers
print_status "Cleaning up OSRM containers..."
docker ps -q --filter "name=osrm" | xargs -r docker stop 2>/dev/null || true
docker ps -aq --filter "name=osrm" | xargs -r docker rm 2>/dev/null || true

# Clean up old logs (optional - ask user)
print_status "Cleaning up old logs..."
rm -f logs/osrm_setup_*.log 2>/dev/null || true
print_success "Old logs cleaned up"

print_success "Cleanup completed"
