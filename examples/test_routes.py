#!/usr/bin/env python3
"""
Test script for Distance Route Calculator

This script demonstrates how to use the route calculator for your
movers and packers AI model. It shows various use cases and examples.
"""

import sys
import json
from route_calculator import DistanceRouteCalculator, create_movers_route_analyzer, RouteProfile


def test_basic_routing():
    """Test basic routing functionality"""
    print("🧪 Testing Basic Routing...")
    
    calculator = create_movers_route_analyzer('http://localhost:5001')
    
    # Test if OSRM is running
    if not calculator.is_healthy():
        print("❌ OSRM server is not running!")
        print("   Please start it with: docker-compose up -d")
        return False
    
    print("✅ OSRM server is healthy!")
    
    # Test coordinates (California cities - both inter and intra-city routes)
    test_routes = [
        {
            "name": "San Francisco Financial District to North Beach",
            "origin": (-122.4194, 37.7749),
            "destination": (-122.4091, 37.7849)
        },
        {
            "name": "Downtown LA to Hollywood",
            "origin": (-118.2437, 34.0522),
            "destination": (-118.3287, 34.0928)
        },
        {
            "name": "Beverly Hills to Santa Monica (LA)",
            "origin": (-118.4004, 34.0736),
            "destination": (-118.4912, 34.0195)
        },
        {
            "name": "San Diego Downtown to La Jolla",
            "origin": (-117.1611, 32.7157),
            "destination": (-117.2742, 32.8328)
        },
        {
            "name": "Sacramento to Davis",
            "origin": (-121.4944, 38.5816),
            "destination": (-121.7405, 38.5449)
        },
        {
            "name": "Oakland to Berkeley",
            "origin": (-122.2711, 37.8044),
            "destination": (-122.2585, 37.8715)
        }
    ]
    
    for test in test_routes:
        print(f"\n📍 {test['name']}")
        try:
            result = calculator.get_routes(
                test['origin'], 
                test['destination'], 
                alternatives=3
            )
            
            print(f"   Found {len(result.routes)} route options:")
            for i, route in enumerate(result.routes, 1):
                print(f"     Route {i}: {route.distance_km:.2f} km, {route.duration_minutes:.1f} min")
            
            print(f"   Distance range: {result.distance_range[0]:.2f} - {result.distance_range[1]:.2f} km")
            print(f"   Duration range: {result.duration_range[0]:.1f} - {result.duration_range[1]:.1f} min")
            
        except Exception as e:
            print(f"   ❌ Error: {e}")
            return False
    
    return True


def test_distance_matrix():
    """Test distance matrix functionality"""
    print("\n🧪 Testing Distance Matrix...")
    
    calculator = create_movers_route_analyzer('http://localhost:5001')
    
    # Test with multiple California locations (mix of cities)
    locations = [
        (-122.4194, 37.7749),  # San Francisco Financial District
        (-122.4091, 37.7849),  # San Francisco North Beach
        (-122.2711, 37.8044),  # Oakland
        (-118.2437, 34.0522),  # Downtown LA
        (-118.4004, 34.0736),  # Beverly Hills, LA
        (-117.1611, 32.7157),  # San Diego Downtown
        (-121.4944, 38.5816)   # Sacramento
    ]
    
    try:
        matrix = calculator.get_distance_matrix(locations)
        
        print(f"   Generated {len(matrix['distances'])}x{len(matrix['distances'][0])} distance matrix")
        print("   Distance matrix (km):")
        for i, row in enumerate(matrix['distances']):
            print(f"     From location {i}: {[round(d/1000, 2) for d in row]}")
        
        return True
        
    except Exception as e:
        print(f"   ❌ Error: {e}")
        return False


def test_ai_model_integration():
    """Test integration patterns for AI models"""
    print("\n🧪 Testing AI Model Integration...")
    
    calculator = create_movers_route_analyzer('http://localhost:5001')
    
    # Simulate a movers scenario in California cities (mix of intra and inter-city)
    pickup_locations = [
        (-122.4194, 37.7749),  # Customer 1 pickup - San Francisco Financial District
        (-122.4091, 37.7849),  # Customer 2 pickup - San Francisco North Beach (intra-city)
        (-118.2437, 34.0522),  # Customer 3 pickup - Downtown LA
        (-117.1611, 32.7157),  # Customer 4 pickup - San Diego Downtown
    ]
    
    delivery_locations = [
        (-122.2711, 37.8044),  # Customer 1 delivery - Oakland
        (-122.2585, 37.8715),  # Customer 2 delivery - Berkeley (intra-city)
        (-118.3287, 34.0928),  # Customer 3 delivery - Hollywood, LA
        (-117.2742, 32.8328),  # Customer 4 delivery - La Jolla, San Diego (intra-city)
    ]
    
    print("   Simulating movers scheduling scenario...")
    
    # Get route options for each pickup-delivery pair
    route_data = []
    
    for i, (pickup, delivery) in enumerate(zip(pickup_locations, delivery_locations)):
        try:
            result = calculator.get_routes(pickup, delivery, alternatives=2)
            
            # Prepare data for AI model
            route_info = {
                "customer_id": i + 1,
                "pickup": pickup,
                "delivery": delivery,
                "route_options": [
                    {
                        "route_id": j + 1,
                        "distance_km": route.distance_km,
                        "duration_minutes": route.duration_minutes,
                        "is_fastest": route == result.fastest_route,
                        "is_shortest": route == result.shortest_route
                    }
                    for j, route in enumerate(result.routes)
                ],
                "distance_variance_km": result.distance_range[1] - result.distance_range[0],
                "duration_variance_minutes": result.duration_range[1] - result.duration_range[0]
            }
            
            route_data.append(route_info)
            
            print(f"   Customer {i+1}: {len(result.routes)} routes, "
                  f"distance range {result.distance_range[0]:.1f}-{result.distance_range[1]:.1f} km")
            
        except Exception as e:
            print(f"   ❌ Error for customer {i+1}: {e}")
            return False
    
    # This is the kind of data your AI model would receive
    print(f"\n   Generated route data for {len(route_data)} customers")
    print("   Sample data structure:")
    print(json.dumps(route_data[0], indent=2))
    
    return True


def main():
    """Run all tests"""
    print("🚀 Distance Route Calculator Test Suite")
    print("=" * 50)
    
    tests = [
        test_basic_routing,
        test_distance_matrix,
        test_ai_model_integration
    ]
    
    passed = 0
    total = len(tests)
    
    for test in tests:
        try:
            if test():
                passed += 1
                print("✅ PASSED")
            else:
                print("❌ FAILED")
        except Exception as e:
            print(f"❌ FAILED with exception: {e}")
    
    print(f"\n📊 Test Results: {passed}/{total} tests passed")
    
    if passed == total:
        print("🎉 All tests passed! Your route calculator is ready for your AI model.")
    else:
        print("⚠️  Some tests failed. Please check the OSRM setup.")
        sys.exit(1)


if __name__ == "__main__":
    main()