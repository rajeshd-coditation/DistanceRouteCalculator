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

# Start the process in background with real-time monitoring
print_status "Starting OSRM setup with real-time error detection..."

# Start the process and capture its output
nohup ./run.sh > "$LOG_FILE" 2>&1 &
PID=$!

# Save PID
echo $PID > "$PID_FILE"

print_success "OSRM setup started in background (PID: $PID)"

# Start background monitoring for errors
(
    while ps -p $PID > /dev/null 2>&1; do
        sleep 10
        
        # Check for common error patterns in the log
        if [ -f "$LOG_FILE" ]; then
            # Check for memory issues
            if tail -20 "$LOG_FILE" 2>/dev/null | grep -q "Out of memory\|OOM\|killed\|terminate called"; then
                echo ""
                echo "🚨 MEMORY ISSUE DETECTED!"
                echo "The OSRM processing is running out of memory."
                echo "Check memory usage: free -h"
                echo "Consider stopping other processes or restarting with more memory."
                echo ""
            fi
            
            # Check for Docker issues
            if tail -20 "$LOG_FILE" 2>/dev/null | grep -q "docker.*error\|container.*failed\|permission denied"; then
                echo ""
                echo "🚨 DOCKER ISSUE DETECTED!"
                echo "Docker container failed or permission denied."
                echo "Check Docker status: docker ps -a"
                echo ""
            fi
            
            # Check for OSRM processing errors
            if tail -20 "$LOG_FILE" 2>/dev/null | grep -q "no edges remaining\|Profile.*error\|extraction.*failed"; then
                echo ""
                echo "🚨 OSRM PROCESSING ERROR!"
                echo "OSRM profile or extraction failed."
                echo "This usually means the profile is too restrictive."
                echo ""
            fi
            
            # Check for disk space issues
            if tail -20 "$LOG_FILE" 2>/dev/null | grep -q "No space left\|disk full\|write error"; then
                echo ""
                echo "🚨 DISK SPACE ISSUE!"
                echo "Running out of disk space."
                echo "Check disk usage: df -h"
                echo ""
            fi
            
            # Check for process termination
            if tail -20 "$LOG_FILE" 2>/dev/null | grep -q "Process.*killed\|SIGKILL\|exit code 137"; then
                echo ""
                echo "🚨 PROCESS TERMINATED!"
                echo "The OSRM processing was killed (likely due to memory issues)."
                echo "Check system resources and restart if needed."
                echo ""
            fi
            
            # Show progress updates
            if tail -5 "$LOG_FILE" 2>/dev/null | grep -q "Step [0-9]/3\|completed successfully\|Memory:"; then
                echo "📊 Progress update:"
                tail -3 "$LOG_FILE" 2>/dev/null | grep -E "Step [0-9]/3|completed successfully|Memory:" || true
                echo ""
            fi
        fi
    done
) &

MONITOR_PID=$!

print_status "Real-time error monitoring started (PID: $MONITOR_PID)"
print_status "Monitor progress with: ./scripts/monitor_setup.sh"
print_status "Check logs with: tail -f $LOG_FILE"
print_status "Stop setup with: ./scripts/stop_setup.sh"

echo ""
echo "📋 Quick Commands:"
echo "  Monitor:    ./scripts/monitor_setup.sh"
echo "  Stop:       ./scripts/stop_setup.sh"
echo "  Logs:       tail -f $LOG_FILE"
echo "  Status:     ps -p $PID"
echo "  Diagnose:   ./scripts/diagnose_osrm.sh"
echo ""

# Show initial status
print_status "Initial system status:"
echo "Memory: $(free -h | awk '/^Mem:/{print $3"/"$2" ("$7" available)"}')"
echo "Disk: $(df -h . | tail -1 | awk '{print $3"/"$2" ("$5" used)"}')"
echo ""

# Wait a moment and show first few lines of log
sleep 5
if [ -f "$LOG_FILE" ] && [ -s "$LOG_FILE" ]; then
    print_status "First few lines of processing:"
    head -10 "$LOG_FILE"
    echo ""
fi

print_status "Background monitoring is active. Check back in a few minutes for progress updates."
