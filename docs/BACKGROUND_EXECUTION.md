# Background Execution Guide

This guide explains how to run the OSRM setup in the background with monitoring capabilities.

## 🚀 Quick Start

### Start Background Setup
```bash
./scripts/run_background.sh
```

### Monitor Progress
```bash
./scripts/monitor_setup.sh
```

### Check Status
```bash
./scripts/check_status.sh
```

### Stop Setup
```bash
./scripts/stop_setup.sh
```

## 📋 Available Scripts

### 1. `run_background.sh`
Starts the OSRM setup in the background with logging.

**Features:**
- Runs `run.sh` in background using `nohup`
- Creates timestamped log files in `logs/` directory
- Saves process ID for monitoring
- Provides quick command reference

**Output:**
- Log file: `logs/osrm_setup_YYYYMMDD_HHMMSS.log`
- PID file: `logs/osrm_setup.pid`

### 2. `monitor_setup.sh`
Real-time monitoring of the setup process.

**Features:**
- Shows live log output
- Verifies process is running
- Displays latest log entries
- Press Ctrl+C to stop monitoring

### 3. `check_status.sh`
Comprehensive status check of the entire setup.

**Features:**
- Process status and details
- Docker container status
- OSRM server health check
- Disk and memory usage
- Test route validation

### 4. `stop_setup.sh`
Gracefully stops the setup process.

**Features:**
- Terminates main process
- Stops OSRM Docker containers
- Cleans up PID files
- Handles both graceful and forced termination

## 📊 Monitoring Commands

### Check Process Status
```bash
# Check if process is running
ps -p $(cat logs/osrm_setup.pid)

# View process details
ps -p $(cat logs/osrm_setup.pid) -o pid,ppid,cmd,etime,pcpu,pmem
```

### View Logs
```bash
# View latest log
tail -f logs/osrm_setup_*.log

# View specific log
tail -f logs/osrm_setup_20241207_143022.log

# Search for errors
grep -i error logs/osrm_setup_*.log

# Search for progress
grep -i "step\|progress" logs/osrm_setup_*.log
```

### Check Docker Containers
```bash
# List OSRM containers
docker ps --filter "name=osrm"

# View container logs
docker logs osrm-us-server

# Check container stats
docker stats osrm-us-server
```

### Check OSRM Server
```bash
# Test server health
curl -s http://localhost:5001/route/v1/driving/-74.0060,40.7128;-118.2437,34.0522?overview=false

# Test with jq
curl -s "http://localhost:5001/route/v1/driving/-74.0060,40.7128;-118.2437,34.0522?overview=false&annotations=distance,duration" | jq '.routes[0] | {distance, duration}'
```

## 🔧 Troubleshooting

### Process Not Running
```bash
# Check if PID file exists
ls -la logs/osrm_setup.pid

# Check process
ps -p $(cat logs/osrm_setup.pid 2>/dev/null)

# Check logs for errors
tail -20 logs/osrm_setup_*.log
```

### Docker Issues
```bash
# Check Docker daemon
sudo systemctl status docker

# Restart Docker
sudo systemctl restart docker

# Check Docker permissions
groups $USER | grep docker
```

### Memory Issues
```bash
# Check available memory
free -h

# Check memory usage during processing
watch -n 5 'free -h && echo "---" && docker stats --no-stream'
```

### Disk Space Issues
```bash
# Check disk usage
df -h

# Check OSRM data size
du -sh osrm-data/

# Clean up if needed
docker system prune -a
```

## 📈 Progress Indicators

The setup process includes detailed progress indicators:

1. **Step 1/3: Extraction** - 1-2 hours, 25-35GB RAM
2. **Step 2/3: Partition** - 30-60 minutes
3. **Step 3/3: Customize** - 30-60 minutes
4. **Server Start** - 1-2 minutes
5. **Testing** - 1-2 minutes

## 🎯 Best Practices

### For Long-Running Setup
1. Use `screen` or `tmux` for additional session management
2. Monitor system resources regularly
3. Keep logs for troubleshooting
4. Test server functionality after completion

### For Development
1. Use existing files when possible (script will ask)
2. Monitor logs for any issues
3. Test with smaller datasets first
4. Keep backup of working configurations

## 📝 Log Files

Log files are stored in `logs/` directory with timestamps:
- `osrm_setup_20241207_143022.log` - Main setup log
- `osrm_setup.pid` - Process ID file
- `osrm_extract.log` - OSRM extraction log (if created)

## 🚨 Error Handling

The scripts include comprehensive error handling:
- Process monitoring and restart capabilities
- Docker container cleanup
- Graceful termination
- Detailed error logging
- Resource usage monitoring
