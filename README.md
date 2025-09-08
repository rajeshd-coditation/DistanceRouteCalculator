# Distance Route Calculator for Movers and Packers AI Model

A Python wrapper around OSRM (Open Source Routing Machine) to calculate multiple driving routes between locations and their distances. Perfect for AI models that need to consider different route options for movers and packers.

## 🚀 Quick Start

### AWS Deployment (Recommended)
```bash
# On Ubuntu AWS instance (64GB+ RAM)
git clone <repository-url>
cd Distance-RouteCalculator
chmod +x run.sh
./run.sh
```

**AWS Requirements:**
- **Instance**: `r5.4xlarge` (16 vCPU, 128GB RAM) - ~$1.20/hour
- **Storage**: 100GB+ SSD
- **OS**: Ubuntu 20.04/22.04 LTS
- **Timeline**: 3-5 hours total setup

### Local Development
```bash
# Set up Python environment
python3.11 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Set up OSRM server
chmod +x scripts/setup_osrm.sh
./scripts/setup_osrm.sh

# Test the setup
python3 examples/test_routes.py
```

## 📁 Project Structure

```
Distance-RouteCalculator/
├── run.sh                          # Complete AWS setup script
├── route_calculator.py             # Main Python API
├── requirements.txt                 # Python dependencies
├── truck.lua                       # OSRM truck profile
├── .gitignore                      # Git ignore rules
├── README.md                       # This file
├── docs/                          # Documentation
│   ├── API_GUIDE.md               # Complete API testing guide
│   └── postman/                    # API testing
│       ├── OSRM_API_Postman_Collection.json
│       └── OSRM_Postman_Environment.json
├── examples/                       # Usage examples
│   ├── ai_model_example.py         # AI model integration
│   ├── intra_city_example.py       # Intra-city routing
│   └── test_routes.py              # Comprehensive tests
├── scripts/                        # Setup and utility scripts
│   ├── setup_osrm.sh               # OSRM server setup
│   ├── monitor_osrm_progress.sh     # Progress monitoring
│   └── continue_osrm_setup.sh      # Continue setup
└── osrm-data/                      # OSRM map data (created by setup)
```

## 🎯 Features

- **Multiple Route Options**: Get up to 3 alternative routes between two points
- **Distance & Duration**: Calculate precise distances and travel times
- **Fuel Cost Estimation**: Estimate fuel costs for moving trucks
- **Truck Suitability Scoring**: Rate routes based on truck-friendliness
- **Route Quality Analysis**: Analyze route efficiency and quality
- **AI Model Ready**: Clean data structures perfect for machine learning
- **OSRM Integration**: Uses OSRM for accurate, real-world routing
- **US Coverage**: Full United States routing coverage

## 💻 Usage

### Basic Usage

```python
from route_calculator import create_movers_route_analyzer

# Create analyzer instance
analyzer = create_movers_route_analyzer('http://localhost:5001')

# Define source and destination (longitude, latitude)
source = (-122.4194, 37.7749)  # San Francisco
destination = (-122.2711, 37.8044)  # Oakland

# Get multiple route options
routes = analyzer.get_routes(source, destination, alternatives=3)

# Print route information
for i, route in enumerate(routes.routes, 1):
    print(f"Route {i}:")
    print(f"  Distance: {route.distance_km:.2f} km")
    print(f"  Duration: {route.duration_minutes:.1f} min")
    print(f"  Fuel Cost: ${route.estimated_fuel_cost:.2f}")
    print(f"  Truck Score: {route.truck_suitability_score:.2f}")
```

### AI Model Integration

```python
from route_calculator import create_movers_route_analyzer

# Create analyzer for AI model
analyzer = create_movers_route_analyzer('http://localhost:5001')

# Get route data for machine learning
source = (-122.4194, 37.7749)
destination = (-122.2711, 37.8044)

routes = analyzer.get_routes(source, destination, alternatives=3)

# Extract features for ML model
features = []
for route in routes.routes:
    features.append({
        'distance_km': route.distance_km,
        'duration_minutes': route.duration_minutes,
        'fuel_cost': route.estimated_fuel_cost,
        'truck_score': route.truck_suitability_score,
        'quality_score': route.route_quality_score,
        'avg_speed_kmh': route.avg_speed_kmh
    })

print(f"Extracted {len(features)} route features for ML model")
```

## 🔧 API Reference

### RouteCalculator Class

#### `get_routes(origin, destination, alternatives=3, include_geometry=False, include_steps=False)`

Get multiple route options between two points.

**Parameters:**
- `origin`: Tuple of (longitude, latitude) for starting point
- `destination`: Tuple of (longitude, latitude) for ending point
- `alternatives`: Number of alternative routes to return (default: 3)
- `include_geometry`: Whether to include detailed route geometry (default: False)
- `include_steps`: Whether to include turn-by-turn steps (default: False)

**Returns:**
- `RouteResult` object containing multiple route options

#### `get_distance_matrix(origins, destinations)`

Calculate distance matrix between multiple origins and destinations.

**Parameters:**
- `origins`: List of (longitude, latitude) tuples for starting points
- `destinations`: List of (longitude, latitude) tuples for ending points

**Returns:**
- `DistanceMatrixResult` object with distance and duration matrices

### RouteOption Class

Each route option contains:

- `distance_km`: Distance in kilometers
- `duration_minutes`: Duration in minutes
- `estimated_fuel_cost`: Estimated fuel cost in USD
- `truck_suitability_score`: Score from 0-1 for truck suitability
- `route_quality_score`: Score from 0-1 for route quality
- `avg_speed_kmh`: Average speed in km/h

## 🏗️ Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Python App   │───▶│   OSRM Server    │───▶│   Map Data      │
│                 │    │   (Docker)       │    │   (OSM)         │
│ route_calculator│    │   Port: 5001     │    │   US Coverage   │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## 📚 Documentation

- **[AWS Deployment Guide](docs/AWS_DEPLOYMENT_README.md)** - Complete AWS setup instructions
- **[Technical Approach](docs/approach.md)** - Technical implementation details
- **[Postman Setup](docs/postman/Postman_Setup_Guide.md)** - API testing with Postman

## 🧪 Examples

See the `examples/` directory for:
- `ai_model_example.py`: AI model integration example
- `intra_city_example.py`: Intra-city routing example
- `test_routes.py`: Comprehensive testing suite

## 🛠️ Configuration

### OSRM Server Configuration

The OSRM server runs on port 5001 by default. To change this:

```python
analyzer = create_movers_route_analyzer('http://localhost:YOUR_PORT')
```

### Map Data

The system uses US map data by default. To use different regions:

1. Download OSM data from [Geofabrik](https://download.geofabrik.de/)
2. Update `scripts/setup_osrm.sh` with your region
3. Re-run the setup script

## 🚨 Troubleshooting

### Common Issues

1. **OSRM Server Not Running**
   ```bash
   docker ps | grep osrm
   # If not running, restart with:
   ./scripts/setup_osrm.sh
   ```

2. **Connection Refused**
   - Check if OSRM server is running on port 5001
   - Verify Docker container is active

3. **No Routes Found**
   - Ensure coordinates are within the loaded map data
   - Check coordinate format (longitude, latitude)

### Performance Tips

- Use `include_geometry=False` for faster responses
- Limit `alternatives` to 1-3 for better performance
- Cache results for repeated queries

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For issues and questions:
1. Check the troubleshooting section
2. Review the examples
3. Open an issue on GitHub

---

**Built for Movers and Packers AI Models** 🚚📦