#!/usr/bin/env python3
"""
Intra-City Route Examples for Movers and Packers

This script demonstrates how to use the route calculator for
intra-city moves within major US metropolitan areas.
Perfect for local moving companies that work within a single city.
"""

import sys
from route_calculator import create_movers_route_analyzer


def test_nyc_routes():
    """Test routes within New York City"""
    print("🗽 Testing NYC Intra-City Routes")
    print("=" * 40)
    
    calculator = create_movers_route_analyzer('http://localhost:5001')
    
    # NYC intra-city routes
    nyc_routes = [
        {
            "name": "Times Square to Central Park",
            "origin": (-73.9857, 40.7589),
            "destination": (-73.9654, 40.7829),
            "description": "Short distance, high traffic area"
        },
        {
            "name": "Financial District to Upper East Side",
            "origin": (-74.0088, 40.7074),
            "destination": (-73.9581, 40.7736),
            "description": "Longer distance, multiple route options"
        },
        {
            "name": "Brooklyn Heights to Williamsburg",
            "origin": (-73.9969, 40.6962),
            "destination": (-73.9571, 40.7081),
            "description": "Brooklyn intra-borough move"
        },
        {
            "name": "Queens Plaza to Astoria",
            "origin": (-73.9370, 40.7505),
            "destination": (-73.9219, 40.7701),
            "description": "Queens intra-borough move"
        }
    ]
    
    for route in nyc_routes:
        print(f"\n📍 {route['name']}")
        print(f"   {route['description']}")
        
        try:
            result = calculator.get_routes(
                route['origin'], 
                route['destination'], 
                alternatives=3
            )
            
            print(f"   Found {len(result.routes)} route options:")
            for i, route_option in enumerate(result.routes, 1):
                print(f"     Route {i}: {route_option.distance_km:.2f} km, "
                      f"{route_option.duration_minutes:.1f} min, "
                      f"${route_option.estimated_fuel_cost:.2f} fuel")
            
            print(f"   Best for trucks: Route {result.routes.index(result.best_truck_route) + 1}")
            print(f"   Most efficient: Route {result.routes.index(result.most_efficient_route) + 1}")
            
        except Exception as e:
            print(f"   ❌ Error: {e}")


def test_la_routes():
    """Test routes within Los Angeles"""
    print("\n🌴 Testing LA Intra-City Routes")
    print("=" * 40)
    
    calculator = create_movers_route_analyzer('http://localhost:5001')
    
    # LA intra-city routes
    la_routes = [
        {
            "name": "Downtown LA to Hollywood",
            "origin": (-118.2437, 34.0522),
            "destination": (-118.3287, 34.0928),
            "description": "Classic LA route, multiple freeway options"
        },
        {
            "name": "Beverly Hills to Santa Monica",
            "origin": (-118.4004, 34.0736),
            "destination": (-118.4912, 34.0195),
            "description": "Westside LA, beach access considerations"
        },
        {
            "name": "Pasadena to Glendale",
            "origin": (-118.1445, 34.1478),
            "destination": (-118.2551, 34.1425),
            "description": "Northeast LA, suburban areas"
        },
        {
            "name": "Venice to Marina del Rey",
            "origin": (-118.4912, 33.9850),
            "destination": (-118.4517, 33.9727),
            "description": "Coastal LA, beach communities"
        }
    ]
    
    for route in la_routes:
        print(f"\n📍 {route['name']}")
        print(f"   {route['description']}")
        
        try:
            result = calculator.get_routes(
                route['origin'], 
                route['destination'], 
                alternatives=3
            )
            
            print(f"   Found {len(result.routes)} route options:")
            for i, route_option in enumerate(result.routes, 1):
                print(f"     Route {i}: {route_option.distance_km:.2f} km, "
                      f"{route_option.duration_minutes:.1f} min, "
                      f"${route_option.estimated_fuel_cost:.2f} fuel")
            
            print(f"   Best for trucks: Route {result.routes.index(result.best_truck_route) + 1}")
            print(f"   Most efficient: Route {result.routes.index(result.most_efficient_route) + 1}")
            
        except Exception as e:
            print(f"   ❌ Error: {e}")


def test_chicago_routes():
    """Test routes within Chicago"""
    print("\n🏙️ Testing Chicago Intra-City Routes")
    print("=" * 40)
    
    calculator = create_movers_route_analyzer('http://localhost:5001')
    
    # Chicago intra-city routes
    chicago_routes = [
        {
            "name": "Loop to Lincoln Park",
            "origin": (-87.6298, 41.8781),
            "destination": (-87.6446, 41.9253),
            "description": "Downtown to North Side, lakefront route"
        },
        {
            "name": "Wicker Park to Logan Square",
            "origin": (-87.6756, 41.9086),
            "destination": (-87.7081, 41.9236),
            "description": "Northwest Side, hip neighborhoods"
        },
        {
            "name": "Hyde Park to South Loop",
            "origin": (-87.5927, 41.8015),
            "destination": (-87.6298, 41.8781),
            "description": "South Side to downtown"
        },
        {
            "name": "O'Hare to Downtown",
            "origin": (-87.9073, 41.9786),
            "destination": (-87.6298, 41.8781),
            "description": "Airport to downtown, long distance"
        }
    ]
    
    for route in chicago_routes:
        print(f"\n📍 {route['name']}")
        print(f"   {route['description']}")
        
        try:
            result = calculator.get_routes(
                route['origin'], 
                route['destination'], 
                alternatives=3
            )
            
            print(f"   Found {len(result.routes)} route options:")
            for i, route_option in enumerate(result.routes, 1):
                print(f"     Route {i}: {route_option.distance_km:.2f} km, "
                      f"{route_option.duration_minutes:.1f} min, "
                      f"${route_option.estimated_fuel_cost:.2f} fuel")
            
            print(f"   Best for trucks: Route {result.routes.index(result.best_truck_route) + 1}")
            print(f"   Most efficient: Route {result.routes.index(result.most_efficient_route) + 1}")
            
        except Exception as e:
            print(f"   ❌ Error: {e}")


def analyze_intra_city_patterns():
    """Analyze patterns in intra-city routes"""
    print("\n📊 Intra-City Route Analysis")
    print("=" * 40)
    
    calculator = create_movers_route_analyzer('http://localhost:5001')
    
    # Sample intra-city routes from different cities
    sample_routes = [
        # NYC
        ((-73.9857, 40.7589), (-73.9654, 40.7829), "NYC - Times Square to Central Park"),
        # LA
        ((-118.2437, 34.0522), (-118.3287, 34.0928), "LA - Downtown to Hollywood"),
        # Chicago
        ((-87.6298, 41.8781), (-87.6446, 41.9253), "Chicago - Loop to Lincoln Park"),
        # Miami
        ((-80.1918, 25.7617), (-80.1300, 25.7907), "Miami - Downtown to Miami Beach"),
        # San Francisco
        ((-122.4194, 37.7749), (-122.4091, 37.7849), "SF - Financial District to North Beach")
    ]
    
    total_routes = 0
    total_distance = 0
    total_duration = 0
    total_fuel_cost = 0
    
    for origin, destination, name in sample_routes:
        try:
            result = calculator.get_routes(origin, destination, alternatives=2)
            
            if result.routes:
                best_route = result.best_truck_route
                total_routes += 1
                total_distance += best_route.distance_km
                total_duration += best_route.duration_minutes
                total_fuel_cost += best_route.estimated_fuel_cost
                
                print(f"   {name}: {best_route.distance_km:.1f}km, "
                      f"{best_route.duration_minutes:.1f}min, "
                      f"${best_route.estimated_fuel_cost:.2f}")
            
        except Exception as e:
            print(f"   {name}: Error - {e}")
    
    if total_routes > 0:
        print(f"\n📈 Average Intra-City Move:")
        print(f"   Distance: {total_distance/total_routes:.1f} km")
        print(f"   Duration: {total_duration/total_routes:.1f} minutes")
        print(f"   Fuel Cost: ${total_fuel_cost/total_routes:.2f}")
        print(f"   Routes Analyzed: {total_routes}")


def main():
    """Run all intra-city route tests"""
    print("🚚 Intra-City Route Calculator for Movers and Packers")
    print("=" * 60)
    
    # Check if OSRM is running
    calculator = create_movers_route_analyzer('http://localhost:5001')
    if not calculator.is_healthy():
        print("❌ OSRM server is not running!")
        print("   Please start it with: docker-compose up -d")
        sys.exit(1)
    
    print("✅ OSRM server is healthy!")
    
    # Run tests for different cities
    test_nyc_routes()
    test_la_routes()
    test_chicago_routes()
    analyze_intra_city_patterns()
    
    print(f"\n🎉 Intra-city route analysis complete!")
    print("   This data is perfect for local movers and packers")
    print("   who work within specific metropolitan areas.")


if __name__ == "__main__":
    main()




