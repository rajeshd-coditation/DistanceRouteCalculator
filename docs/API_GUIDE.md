# 🚚 OSRM Route Calculator - API Guide

Complete guide for testing and using the OSRM Route Calculator API with Postman collections and Python examples.

## 🚀 Quick Start

### Postman Setup
1. **Import Environment**: `docs/postman/OSRM_Postman_Environment.json`
2. **Import Collection**: `docs/postman/OSRM_API_Postman_Collection.json`
3. **Select Environment**: "OSRM Route Calculator Environment" in dropdown
4. **Test**: Run "Health Check" request

### Python Setup
```bash
# Install dependencies
pip install -r requirements.txt

# Test basic functionality
python3 examples/test_routes.py
```

## 📁 API Endpoints

### Core Routing
- **Health Check**: Verify server status
- **Single Route**: Basic point-to-point routing
- **Multiple Routes**: Get 3 alternative routes
- **Route with Geometry**: Detailed coordinate data
- **Turn-by-Turn Steps**: Navigation instructions

### Distance Matrices
- **2x2 Matrix**: 2 locations
- **3x3 Matrix**: 3 locations  
- **4x4 Matrix**: 4 locations
- **Partial Matrix**: Specific source-destination pairs

### Utilities
- **Nearest Road**: Snap coordinates to road network
- **Map Matching**: Match GPS tracks to roads

## 🧪 Test Scenarios

### California Routes
- SF Financial District → North Beach
- SF → Oakland (Bay Bridge)
- LA Downtown → Hollywood
- Beverly Hills → Santa Monica
- San Diego Downtown → La Jolla

### Error Testing
- Invalid coordinates (outside coverage)
- Malformed requests
- Server connectivity issues

## 📊 Response Format

### Route Response
```json
{
  "code": "Ok",
  "routes": [{
    "distance": 2353.8,
    "duration": 267.7,
    "legs": [{
      "distance": 2353.8,
      "duration": 267.7,
      "annotation": {
        "distance": [13.6, 11.2, ...],
        "duration": [0.8, 0.6, ...]
      }
    }]
  }],
  "waypoints": [...]
}
```

### Distance Matrix Response
```json
{
  "code": "Ok",
  "durations": [[0.0, 1176.0], [1176.0, 0.0]],
  "distances": [[0.0, 2353.8], [2353.8, 0.0]],
  "sources": [...],
  "destinations": [...]
}
```

## 🔧 Troubleshooting

### Common Issues
1. **Connection Refused**: Check OSRM server is running (`docker ps`)
2. **No Routes Found**: Verify coordinates are within map coverage
3. **Slow Responses**: First request may take 2-3 seconds (server warmup)

### Server Status
```bash
# Check OSRM container
docker ps | grep osrm

# Test connectivity
curl "http://localhost:5001/route/v1/driving/-122.4194,37.7749;-122.4091,37.7849?overview=false"
```

## 📈 Performance
- **First Request**: 2-3 seconds (server warmup)
- **Subsequent Requests**: 100-500ms
- **Distance Matrix**: Faster than individual routes
- **Geometry Requests**: Slower due to coordinate data

## 🎯 Success Criteria
✅ Health Check returns 200 OK  
✅ All California routes work  
✅ Distance matrices calculate correctly  
✅ Error handling works properly  

---

**Files**: `docs/postman/OSRM_*.json` | **Examples**: `examples/` | **Server**: `http://localhost:5001`

