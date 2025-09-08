#!/bin/bash

# Check OSRM setup status
# Usage: ./scripts/check_status.sh

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

echo "🔍 OSRM Setup Status Check"
echo "=========================="

# Check if PID file exists
PID_FILE="logs/osrm_setup.pid"
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if ps -p $PID > /dev/null 2>&1; then
        print_success "Setup process is running (PID: $PID)"
        
        # Show process info
        echo ""
        print_status "Process details:"
        ps -p $PID -o pid,ppid,cmd,etime,pcpu,pmem
        
        # Show latest log
        LATEST_LOG=$(ls -t logs/osrm_setup_*.log 2>/dev/null | head -1)
        if [ -n "$LATEST_LOG" ]; then
            echo ""
            print_status "Current progress:"
            
            # Check what step we're on
            if grep -q "Step 1/3: Extracting" "$LATEST_LOG"; then
                print_status "🔄 Currently: EXTRACTION (Step 1/3)"
                print_status "This typically takes 2-3 hours and uses 20-25GB RAM"
            elif grep -q "Step 2/3: Partitioning" "$LATEST_LOG"; then
                print_status "🔄 Currently: PARTITIONING (Step 2/3)"
                print_status "This typically takes 45-90 minutes and uses 10-15GB RAM"
            elif grep -q "Step 3/3: Customizing" "$LATEST_LOG"; then
                print_status "🔄 Currently: CUSTOMIZING (Step 3/3)"
                print_status "This typically takes 45-90 minutes and uses 10-15GB RAM"
            elif grep -q "Starting OSRM Server" "$LATEST_LOG"; then
                print_status "🔄 Currently: STARTING SERVER"
                print_status "This typically takes 1-2 minutes"
            else
                print_status "🔄 Currently: INITIALIZING"
            fi
            
            echo ""
            print_status "Recent activity (last 5 lines):"
            tail -5 "$LATEST_LOG" 2>/dev/null || print_warning "No recent activity found"
            
            # Check for errors
            echo ""
            print_status "Error check:"
            if tail -20 "$LATEST_LOG" 2>/dev/null | grep -q "Out of memory\|OOM\|killed\|terminate called"; then
                print_error "🚨 MEMORY ISSUE DETECTED!"
                print_status "The process is running out of memory."
                print_status "Check memory: free -h"
            elif tail -20 "$LATEST_LOG" 2>/dev/null | grep -q "no edges remaining\|Profile.*error"; then
                print_error "🚨 OSRM PROCESSING ERROR!"
                print_status "OSRM profile or extraction failed."
            elif tail -20 "$LATEST_LOG" 2>/dev/null | grep -q "No space left\|disk full"; then
                print_error "🚨 DISK SPACE ISSUE!"
                print_status "Running out of disk space."
                print_status "Check disk: df -h"
            else
                print_success "No errors detected in recent logs"
            fi
            
            # Show log file info
            LOG_SIZE=$(du -h "$LATEST_LOG" | cut -f1)
            LOG_LINES=$(wc -l < "$LATEST_LOG")
            print_status "Log file: $LATEST_LOG ($LOG_SIZE, $LOG_LINES lines)"
        fi
    else
        print_error "Setup process (PID: $PID) is not running"
        print_status "Check logs for errors: tail -f logs/osrm_setup_*.log"
        print_status "Run diagnostic: ./scripts/diagnose_osrm.sh"
    fi
else
    print_warning "No background setup process found"
    print_status "Start setup with: ./scripts/run_background.sh"
fi

echo ""

# Check Docker containers
print_status "Docker containers:"
if docker ps --filter "name=osrm" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -q osrm; then
    docker ps --filter "name=osrm" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
else
    print_warning "No OSRM Docker containers running"
fi

echo ""

# Check OSRM server
print_status "OSRM Server health:"
if curl -s http://localhost:5001/route/v1/driving/-74.0060,40.7128;-118.2437,34.0522?overview=false > /dev/null 2>&1; then
    print_success "OSRM server is responding"
    
    # Test with actual request
    RESPONSE=$(curl -s "http://localhost:5001/route/v1/driving/-74.0060,40.7128;-118.2437,34.0522?overview=false&annotations=distance,duration")
    if echo "$RESPONSE" | grep -q '"code":"Ok"'; then
        DISTANCE=$(echo "$RESPONSE" | jq -r '.routes[0].distance // "N/A"')
        DURATION=$(echo "$RESPONSE" | jq -r '.routes[0].duration // "N/A"')
        print_success "Test route successful: ${DISTANCE}m distance, ${DURATION}s duration"
    else
        print_warning "OSRM server responding but test route failed"
    fi
else
    print_warning "OSRM server not responding on port 5001"
fi

echo ""

# Check disk usage
print_status "Disk usage:"
if [ -d "osrm-data" ]; then
    du -sh osrm-data/ 2>/dev/null || print_warning "osrm-data directory not accessible"
else
    print_warning "osrm-data directory not found"
fi

echo ""

# Check memory usage
print_status "Memory usage:"
free -h | grep -E "Mem|Swap"

echo ""
print_status "Quick commands:"
echo "  Monitor:    ./scripts/monitor_setup.sh"
echo "  Stop:       ./scripts/stop_setup.sh"
echo "  Logs:       tail -f logs/osrm_setup_*.log"
echo "  Diagnose:   ./scripts/diagnose_osrm.sh"
