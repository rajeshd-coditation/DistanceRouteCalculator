#!/bin/bash

# OSRM Diagnostic Script
# Usage: ./scripts/diagnose_osrm.sh

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

echo "🔍 OSRM Diagnostic Report"
echo "========================="

# Check if we're in the right directory
if [ ! -f "run.sh" ]; then
    print_error "run.sh not found. Please run from project root directory."
    exit 1
fi

# Check Docker
print_status "Checking Docker..."
if docker ps > /dev/null 2>&1; then
    DOCKER_CMD="docker"
    print_success "Docker is working"
else
    DOCKER_CMD="sudo docker"
    print_warning "Using sudo docker"
fi

# Check OSRM data directory
print_status "Checking OSRM data directory..."
if [ -d "osrm-data" ]; then
    print_success "osrm-data directory exists"
    
    # List all files
    print_status "Files in osrm-data directory:"
    ls -la osrm-data/
    
    # Check for main OSRM files
    print_status "Checking for main OSRM files..."
    if [ -f "osrm-data/us-latest.osrm" ]; then
        print_success "Main OSRM file found: us-latest.osrm"
        FILE_SIZE=$(du -h osrm-data/us-latest.osrm | cut -f1)
        print_status "Size: $FILE_SIZE"
    else
        print_error "Main OSRM file missing: us-latest.osrm"
    fi
    
    if [ -f "osrm-data/us-latest.osrm.hsgr" ]; then
        print_success "HSGR file found: us-latest.osrm.hsgr"
        FILE_SIZE=$(du -h osrm-data/us-latest.osrm.hsgr | cut -f1)
        print_status "Size: $FILE_SIZE"
    else
        print_warning "HSGR file missing: us-latest.osrm.hsgr"
    fi
    
    if [ -f "osrm-data/us-latest.osrm.edges" ]; then
        print_success "Edges file found: us-latest.osrm.edges"
        FILE_SIZE=$(du -h osrm-data/us-latest.osrm.edges | cut -f1)
        print_status "Size: $FILE_SIZE"
    else
        print_warning "Edges file missing: us-latest.osrm.edges"
    fi
    
    # Check file permissions
    print_status "Checking file permissions..."
    ls -la osrm-data/us-latest.osrm* 2>/dev/null | head -5
    
else
    print_error "osrm-data directory not found"
    exit 1
fi

# Check Docker containers
print_status "Checking Docker containers..."
CONTAINERS=$($DOCKER_CMD ps -a --filter "name=osrm" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}")
if [ -n "$CONTAINERS" ]; then
    print_status "OSRM containers:"
    echo "$CONTAINERS"
else
    print_warning "No OSRM containers found"
fi

# Check if port 5001 is in use
print_status "Checking port 5001..."
if netstat -tlnp 2>/dev/null | grep -q ":5001"; then
    print_warning "Port 5001 is in use"
    netstat -tlnp 2>/dev/null | grep ":5001"
else
    print_status "Port 5001 is available"
fi

# Try to start OSRM server manually for testing
print_status "Testing OSRM server startup..."
cd osrm-data

print_status "Starting OSRM server for testing..."
$DOCKER_CMD run -d --name osrm-test-server -p 5002:5000 -v "$PWD:/data" ghcr.io/project-osrm/osrm-backend osrm-routed --algorithm mld /data/us-latest.osrm

sleep 5

# Check if server started
if $DOCKER_CMD ps | grep -q "osrm-test-server"; then
    print_success "Test server started successfully"
    
    # Test the server
    print_status "Testing server response..."
    sleep 5
    RESPONSE=$(curl -s --max-time 10 "http://localhost:5002/health" 2>/dev/null || echo "FAILED")
    
    if [ "$RESPONSE" = "FAILED" ]; then
        print_error "Server health check failed"
        
        # Check server logs
        print_status "Server logs:"
        $DOCKER_CMD logs osrm-test-server 2>&1 | tail -20
    else
        print_success "Server is responding: $RESPONSE"
    fi
    
    # Clean up test server
    print_status "Cleaning up test server..."
    $DOCKER_CMD stop osrm-test-server 2>/dev/null || true
    $DOCKER_CMD rm osrm-test-server 2>/dev/null || true
    
else
    print_error "Test server failed to start"
    
    # Check why it failed
    print_status "Docker logs:"
    $DOCKER_CMD logs osrm-test-server 2>&1 | tail -20
    
    # Clean up
    $DOCKER_CMD rm osrm-test-server 2>/dev/null || true
fi

cd ..

echo ""
print_status "Diagnostic complete!"
