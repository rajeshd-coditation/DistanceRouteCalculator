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
            print_status "Latest log entries:"
            tail -5 "$LATEST_LOG"
        fi
    else
        print_error "Setup process (PID: $PID) is not running"
        print_status "Check logs for errors: tail -f logs/osrm_setup_*.log"
    fi
else
    print_warning "No background setup process found"
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
