"""
Distance Route Calculator for Movers and Packers AI Model

This module provides a Python wrapper around OSRM (Open Source Routing Machine)
to calculate multiple driving routes between locations and their distances.
Perfect for AI models that need to consider different route options.
"""

import requests
import json
from typing import List, Dict, Tuple, Optional, Union
from dataclasses import dataclass
from enum import Enum
import time


class RouteProfile(Enum):
    """OSRM routing profiles - optimized for movers and packers"""
    DRIVING = "driving"  # Default car profile (suitable for trucks)
    TRUCK = "truck"      # Truck-specific profile (if available)


@dataclass
class RouteOption:
    """Represents a single route option with its metrics - optimized for movers and packers"""
    distance_meters: float
    duration_seconds: float
    weight: float
    weight_name: str
    geometry: Optional[List[List[float]]] = None
    steps: Optional[List[Dict]] = None
    
    @property
    def distance_km(self) -> float:
        """Distance in kilometers"""
        return self.distance_meters / 1000.0
    
    @property
    def duration_minutes(self) -> float:
        """Duration in minutes"""
        return self.duration_seconds / 60.0
    
    @property
    def estimated_fuel_cost(self) -> float:
        """Estimated fuel cost for moving truck (rough estimate)"""
        # Assuming 8 MPG for moving truck and $3.50/gallon
        gallons_used = self.distance_km * 0.621371 / 8.0  # Convert km to miles, then to gallons
        return gallons_used * 3.50
    
    @property
    def truck_suitability_score(self) -> float:
        """Score from 0-1 indicating how suitable this route is for trucks"""
        # This is a simplified scoring - in practice, you'd analyze road types, restrictions, etc.
        if self.duration_seconds < 300:  # Less than 5 minutes
            return 0.9  # Very suitable for trucks
        elif self.duration_seconds < 900:  # Less than 15 minutes
            return 0.8  # Good for trucks
        elif self.duration_seconds < 1800:  # Less than 30 minutes
            return 0.7  # Acceptable for trucks
        else:
            return 0.6  # Less ideal for trucks


@dataclass
class RouteResult:
    """Result containing multiple route options between two points - optimized for movers and packers"""
    origin: Tuple[float, float]
    destination: Tuple[float, float]
    routes: List[RouteOption]
    fastest_route: RouteOption
    shortest_route: Optional[RouteOption] = None
    
    @property
    def distance_range(self) -> Tuple[float, float]:
        """Returns (min_distance_km, max_distance_km)"""
        distances = [route.distance_km for route in self.routes]
        return (min(distances), max(distances))
    
    @property
    def duration_range(self) -> Tuple[float, float]:
        """Returns (min_duration_minutes, max_duration_minutes)"""
        durations = [route.duration_minutes for route in self.routes]
        return (min(durations), max(durations))
    
    @property
    def total_fuel_cost_range(self) -> Tuple[float, float]:
        """Returns (min_fuel_cost, max_fuel_cost) in USD"""
        costs = [route.estimated_fuel_cost for route in self.routes]
        return (min(costs), max(costs))
    
    @property
    def best_truck_route(self) -> RouteOption:
        """Returns the route best suited for moving trucks"""
        return max(self.routes, key=lambda r: r.truck_suitability_score)
    
    @property
    def most_efficient_route(self) -> RouteOption:
        """Returns the most fuel-efficient route"""
        return min(self.routes, key=lambda r: r.estimated_fuel_cost)


class DistanceRouteCalculator:
    """
    Main class for calculating multiple driving routes and distances.
    
    This class provides methods to:
    - Get multiple route options between two points
    - Calculate distance matrices for multiple points
    - Handle different routing profiles
    - Provide clean data structures for AI model consumption
    """
    
    def __init__(self, 
                 osrm_url: str = "http://localhost:5000",
                 profile: RouteProfile = RouteProfile.DRIVING,
                 timeout: int = 60,  # Longer timeout for truck routing
                 max_retries: int = 3):
        """
        Initialize the route calculator.
        
        Args:
            osrm_url: URL of the OSRM server
            profile: Routing profile (driving, walking, cycling)
            timeout: Request timeout in seconds
            max_retries: Maximum number of retries for failed requests
        """
        self.osrm_url = osrm_url.rstrip('/')
        self.profile = profile
        self.timeout = timeout
        self.max_retries = max_retries
        self.session = requests.Session()
        
    def _make_request(self, endpoint: str, params: Dict) -> Dict:
        """Make a request to OSRM with retry logic"""
        url = f"{self.osrm_url}{endpoint}"
        
        for attempt in range(self.max_retries):
            try:
                response = self.session.get(url, params=params, timeout=self.timeout)
                response.raise_for_status()
                return response.json()
            except requests.exceptions.RequestException as e:
                if attempt == self.max_retries - 1:
                    raise Exception(f"Failed to connect to OSRM after {self.max_retries} attempts: {e}")
                time.sleep(2 ** attempt)  # Exponential backoff
    
    def get_routes(self, 
                   origin: Tuple[float, float], 
                   destination: Tuple[float, float],
                   alternatives: int = 3,
                   include_geometry: bool = False,
                   include_steps: bool = False) -> RouteResult:
        """
        Get multiple route options between two points.
        
        Args:
            origin: (longitude, latitude) of starting point
            destination: (longitude, latitude) of ending point
            alternatives: Number of alternative routes to request
            include_geometry: Whether to include detailed geometry
            include_steps: Whether to include turn-by-turn steps
            
        Returns:
            RouteResult containing multiple route options
        """
        # Format coordinates as "lon,lat;lon,lat"
        coordinates = f"{origin[0]},{origin[1]};{destination[0]},{destination[1]}"
        
        params = {
            'alternatives': alternatives,
            'overview': 'full' if include_geometry else 'false',
            'steps': 'true' if include_steps else 'false',
            'annotations': 'distance,duration'
        }
        
        endpoint = f"/route/v1/{self.profile.value}/{coordinates}"
        response = self._make_request(endpoint, params)
        
        if response.get('code') != 'Ok':
            raise Exception(f"OSRM routing failed: {response.get('message', 'Unknown error')}")
        
        routes = []
        for route_data in response.get('routes', []):
            route = RouteOption(
                distance_meters=route_data.get('distance', 0),
                duration_seconds=route_data.get('duration', 0),
                weight=route_data.get('weight', route_data.get('duration', 0)),  # Use duration as weight if not available
                weight_name=route_data.get('weight_name', 'routability'),
                geometry=route_data.get('geometry'),
                steps=route_data.get('legs', [{}])[0].get('steps', []) if include_steps else None
            )
            routes.append(route)
        
        if not routes:
            raise Exception("No routes found between the specified points")
        
        # Sort routes by distance (shortest first)
        routes_by_distance = sorted(routes, key=lambda r: r.distance_meters)
        
        # Find fastest route (by duration)
        fastest_route = min(routes, key=lambda r: r.duration_seconds)
        
        # Shortest route is the first in distance-sorted list
        shortest_route = routes_by_distance[0] if len(routes_by_distance) > 1 else None
        
        return RouteResult(
            origin=origin,
            destination=destination,
            routes=routes,
            fastest_route=fastest_route,
            shortest_route=shortest_route
        )
    
    def get_distance_matrix(self, 
                           coordinates: List[Tuple[float, float]],
                           sources: Optional[List[int]] = None,
                           destinations: Optional[List[int]] = None) -> Dict:
        """
        Get distance matrix for multiple coordinates.
        
        Args:
            coordinates: List of (longitude, latitude) tuples
            sources: Indices of source coordinates (default: all)
            destinations: Indices of destination coordinates (default: all)
            
        Returns:
            Dictionary with 'durations' and 'distances' matrices
        """
        # Format coordinates
        coord_string = ';'.join([f"{lon},{lat}" for lon, lat in coordinates])
        
        params = {
            'annotations': 'duration,distance'
        }
        
        if sources is not None:
            params['sources'] = ','.join(map(str, sources))
        if destinations is not None:
            params['destinations'] = ','.join(map(str, destinations))
        
        endpoint = f"/table/v1/{self.profile.value}/{coord_string}"
        response = self._make_request(endpoint, params)
        
        if response.get('code') != 'Ok':
            raise Exception(f"OSRM table request failed: {response.get('message', 'Unknown error')}")
        
        return {
            'durations': response.get('durations', []),
            'distances': response.get('distances', []),
            'sources': response.get('sources', []),
            'destinations': response.get('destinations', [])
        }
    
    def is_healthy(self) -> bool:
        """Check if OSRM server is healthy and responding"""
        try:
                # Test with a simple route request
            test_origin = (-74.0060, 40.7128)  # New York City coordinates
            test_destination = (-73.9352, 40.7306)
            self.get_routes(test_origin, test_destination, alternatives=1)
            return True
        except Exception:
            return False


def create_movers_route_analyzer(osrm_url: str = "http://localhost:5000") -> DistanceRouteCalculator:
    """
    Factory function to create a route calculator optimized for movers and packers.
    
    This creates a calculator with settings optimized for:
    - Truck/van routing for moving services
    - Multiple route options for scheduling
    - Distance and time analysis for AI models
    - Commercial vehicle considerations
    """
    return DistanceRouteCalculator(
        osrm_url=osrm_url,
        profile=RouteProfile.DRIVING,  # Car profile works well for trucks/vans
        timeout=90,  # Longer timeout for truck routing
        max_retries=5
    )


# Example usage and testing functions
if __name__ == "__main__":
    # Example usage
    calculator = create_movers_route_analyzer()
    
    # Check if OSRM is running
    if not calculator.is_healthy():
        print("❌ OSRM server is not running. Please start it with: docker-compose up -d")
        exit(1)
    
    print("✅ OSRM server is healthy!")
    
    # Example: Get multiple routes between two points
    origin = (-74.0060, 40.7128)  # New York City - Manhattan
    destination = (-73.9352, 40.7306)  # New York City - Brooklyn
    
    try:
        result = calculator.get_routes(origin, destination, alternatives=3)
        
        print(f"\n📍 Route Analysis:")
        print(f"   From: {origin}")
        print(f"   To: {destination}")
        print(f"   Found {len(result.routes)} route options")
        
        print(f"\n🚗 Route Options:")
        for i, route in enumerate(result.routes, 1):
            print(f"   Route {i}: {route.distance_km:.2f} km, {route.duration_minutes:.1f} min")
        
        print(f"\n📊 Summary:")
        print(f"   Distance range: {result.distance_range[0]:.2f} - {result.distance_range[1]:.2f} km")
        print(f"   Duration range: {result.duration_range[0]:.1f} - {result.duration_range[1]:.1f} min")
        print(f"   Fastest route: {result.fastest_route.distance_km:.2f} km, {result.fastest_route.duration_minutes:.1f} min")
        if result.shortest_route:
            print(f"   Shortest route: {result.shortest_route.distance_km:.2f} km, {result.shortest_route.duration_minutes:.1f} min")
    
    except Exception as e:
        print(f"❌ Error: {e}")
