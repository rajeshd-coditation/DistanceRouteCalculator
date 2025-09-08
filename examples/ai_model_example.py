"""
AI Model Integration Example for Movers and Packers

This example shows how to integrate the Distance Route Calculator
with your AI scheduling model for movers and packers services.
"""

import json
from typing import List, Dict, Any
from route_calculator import create_movers_route_analyzer, RouteResult


class MoversSchedulingAI:
    """
    AI model for scheduling movers and packers with truck-optimized routing.
    
    This class demonstrates how to use multiple route options
    to make intelligent scheduling decisions for moving trucks.
    """
    
    def __init__(self, osrm_url: str = "http://localhost:5001"):
        self.route_calculator = create_movers_route_analyzer(osrm_url)
        
    def analyze_route_options(self, 
                            pickup: tuple, 
                            delivery: tuple, 
                            max_alternatives: int = 3) -> Dict[str, Any]:
        """
        Analyze multiple route options for a pickup-delivery pair.
        
        Returns structured data that can be used by your AI model
        for scheduling decisions.
        """
        try:
            result = self.route_calculator.get_routes(
                pickup, delivery, 
                alternatives=max_alternatives
            )
            
            # Calculate route diversity metrics
            distance_variance = result.distance_range[1] - result.distance_range[0]
            duration_variance = result.duration_range[1] - result.duration_range[0]
            
            # Calculate efficiency metrics
            efficiency_score = self._calculate_efficiency_score(result)
            
            # Prepare AI model input optimized for movers and packers
            analysis = {
                "pickup_location": pickup,
                "delivery_location": delivery,
                "route_count": len(result.routes),
                "route_options": [
                    {
                        "route_id": i + 1,
                        "distance_km": route.distance_km,
                        "duration_minutes": route.duration_minutes,
                        "estimated_fuel_cost_usd": route.estimated_fuel_cost,
                        "truck_suitability_score": route.truck_suitability_score,
                        "efficiency_ratio": route.distance_km / route.duration_minutes if route.duration_minutes > 0 else 0,
                        "is_fastest": route == result.fastest_route,
                        "is_shortest": route == result.shortest_route,
                        "is_best_for_truck": route == result.best_truck_route,
                        "is_most_efficient": route == result.most_efficient_route,
                        "recommendation_score": self._calculate_recommendation_score(route, result)
                    }
                    for i, route in enumerate(result.routes)
                ],
                "truck_optimized_metrics": {
                    "best_truck_route": {
                        "route_id": result.routes.index(result.best_truck_route) + 1,
                        "suitability_score": result.best_truck_route.truck_suitability_score,
                        "distance_km": result.best_truck_route.distance_km,
                        "duration_minutes": result.best_truck_route.duration_minutes
                    },
                    "most_efficient_route": {
                        "route_id": result.routes.index(result.most_efficient_route) + 1,
                        "fuel_cost_usd": result.most_efficient_route.estimated_fuel_cost,
                        "distance_km": result.most_efficient_route.distance_km
                    },
                    "fuel_cost_range_usd": result.total_fuel_cost_range
                },
                "diversity_metrics": {
                    "distance_variance_km": distance_variance,
                    "duration_variance_minutes": duration_variance,
                    "fuel_cost_variance_usd": result.total_fuel_cost_range[1] - result.total_fuel_cost_range[0],
                    "route_diversity_score": min(distance_variance / 10.0, 1.0)  # Normalized
                },
                "efficiency_score": efficiency_score,
                "recommended_route": self._get_recommended_route(result),
                "scheduling_insights": self._generate_scheduling_insights(result)
            }
            
            return analysis
            
        except Exception as e:
            return {
                "error": str(e),
                "pickup_location": pickup,
                "delivery_location": delivery
            }
    
    def _calculate_efficiency_score(self, result: RouteResult) -> float:
        """Calculate overall efficiency score for route options"""
        if not result.routes:
            return 0.0
        
        # Weighted average of distance and time efficiency
        distances = [r.distance_km for r in result.routes]
        durations = [r.duration_minutes for r in result.routes]
        
        min_distance = min(distances)
        min_duration = min(durations)
        
        efficiency_scores = []
        for route in result.routes:
            distance_efficiency = min_distance / route.distance_km if route.distance_km > 0 else 0
            time_efficiency = min_duration / route.duration_minutes if route.duration_minutes > 0 else 0
            efficiency_scores.append((distance_efficiency + time_efficiency) / 2)
        
        return sum(efficiency_scores) / len(efficiency_scores)
    
    def _calculate_recommendation_score(self, route, result: RouteResult) -> float:
        """Calculate recommendation score for a specific route - optimized for movers and packers"""
        score = 0.0
        
        # Bonus for being best for trucks
        if route == result.best_truck_route:
            score += 0.4
        
        # Bonus for being most fuel efficient
        if route == result.most_efficient_route:
            score += 0.3
        
        # Bonus for being fastest (still important for scheduling)
        if route == result.fastest_route:
            score += 0.2
        
        # Bonus for being shortest (fuel savings)
        if route == result.shortest_route:
            score += 0.1
        
        return min(score, 1.0)
    
    def _get_recommended_route(self, result: RouteResult) -> Dict[str, Any]:
        """Get the recommended route based on multiple factors"""
        if not result.routes:
            return {}
        
        # Find route with highest recommendation score
        best_route = max(result.routes, 
                        key=lambda r: self._calculate_recommendation_score(r, result))
        
        return {
            "route_id": result.routes.index(best_route) + 1,
            "distance_km": best_route.distance_km,
            "duration_minutes": best_route.duration_minutes,
            "reason": self._get_recommendation_reason(best_route, result)
        }
    
    def _get_recommendation_reason(self, route, result: RouteResult) -> str:
        """Get human-readable reason for route recommendation - optimized for movers and packers"""
        reasons = []
        
        if route == result.best_truck_route:
            reasons.append("best for trucks")
        if route == result.most_efficient_route:
            reasons.append("most fuel efficient")
        if route == result.fastest_route:
            reasons.append("fastest")
        if route == result.shortest_route:
            reasons.append("shortest distance")
        
        if not reasons:
            reasons.append("balanced for moving operations")
        
        return f"Recommended for movers because it's {', '.join(reasons)}"
    
    def _generate_scheduling_insights(self, result: RouteResult) -> List[str]:
        """Generate insights for scheduling decisions - optimized for movers and packers"""
        insights = []
        
        if len(result.routes) > 1:
            distance_diff = result.distance_range[1] - result.distance_range[0]
            time_diff = result.duration_range[1] - result.duration_range[0]
            fuel_diff = result.total_fuel_cost_range[1] - result.total_fuel_cost_range[0]
            
            if distance_diff > 5:  # More than 5km difference
                insights.append(f"Significant distance variation ({distance_diff:.1f}km) - consider fuel costs and driver time")
            
            if time_diff > 15:  # More than 15 minutes difference
                insights.append(f"Significant time variation ({time_diff:.1f}min) - schedule extra buffer time for moving operations")
            
            if fuel_diff > 5:  # More than $5 fuel cost difference
                insights.append(f"Significant fuel cost variation (${fuel_diff:.2f}) - consider cost optimization")
            
            if distance_diff < 1 and time_diff < 5:
                insights.append("Routes are very similar - choose based on truck accessibility and driver preference")
        
        # Truck-specific insights
        if result.best_truck_route != result.fastest_route:
            insights.append("Best truck route differs from fastest route - prioritize truck suitability for moving operations")
        
        if result.most_efficient_route != result.shortest_route:
            insights.append("Most fuel-efficient route differs from shortest route - consider fuel costs vs distance")
        
        # Check if any route has very low truck suitability
        low_suitability_routes = [r for r in result.routes if r.truck_suitability_score < 0.7]
        if low_suitability_routes:
            insights.append(f"{len(low_suitability_routes)} route(s) may be challenging for moving trucks - consider alternatives")
        
        return insights
    
    def batch_analyze_routes(self, 
                           pickup_delivery_pairs: List[tuple]) -> List[Dict[str, Any]]:
        """
        Analyze multiple pickup-delivery pairs in batch.
        
        This is useful for processing multiple jobs at once
        in your AI scheduling model.
        """
        results = []
        
        for i, (pickup, delivery) in enumerate(pickup_delivery_pairs):
            print(f"Analyzing route {i+1}/{len(pickup_delivery_pairs)}...")
            analysis = self.analyze_route_options(pickup, delivery)
            analysis["job_id"] = i + 1
            results.append(analysis)
        
        return results


def main():
    """Example usage of the AI model integration"""
    print("🤖 Movers and Packers AI Model Example")
    print("=" * 50)
    
    # Initialize the AI model
    ai_model = MoversSchedulingAI()
    
    # Example pickup and delivery locations (California cities - mix of intra and inter-city)
    jobs = [
        {
            "customer": "Customer A (Inter-city)",
            "pickup": (-122.4194, 37.7749),  # San Francisco Financial District
            "delivery": (-122.2711, 37.8044) # Oakland
        },
        {
            "customer": "Customer B (Intra-city)", 
            "pickup": (-122.4091, 37.7849),  # San Francisco North Beach
            "delivery": (-122.2585, 37.8715) # Berkeley
        },
        {
            "customer": "Customer C (Inter-city)",
            "pickup": (-118.2437, 34.0522),  # Downtown LA
            "delivery": (-118.3287, 34.0928) # Hollywood, LA
        },
        {
            "customer": "Customer D (Intra-city)",
            "pickup": (-117.1611, 32.7157),  # San Diego Downtown
            "delivery": (-117.2742, 32.8328) # La Jolla, San Diego
        }
    ]
    
    print("Analyzing routes for movers scheduling...")
    
    # Analyze each job
    for job in jobs:
        print(f"\n📦 {job['customer']}")
        analysis = ai_model.analyze_route_options(
            job['pickup'], 
            job['delivery']
        )
        
        if 'error' in analysis:
            print(f"   ❌ Error: {analysis['error']}")
            continue
        
        print(f"   Found {analysis['route_count']} route options")
        print(f"   Efficiency score: {analysis['efficiency_score']:.2f}")
        print(f"   Recommended route: {analysis['recommended_route']['reason']}")
        
        print("   Route options:")
        for route in analysis['route_options']:
            status = ""
            if route['is_fastest']:
                status += " (fastest)"
            if route['is_shortest']:
                status += " (shortest)"
            
            print(f"     Route {route['route_id']}: {route['distance_km']:.2f}km, "
                  f"{route['duration_minutes']:.1f}min, score: {route['recommendation_score']:.2f}{status}")
        
        print("   Scheduling insights:")
        for insight in analysis['scheduling_insights']:
            print(f"     • {insight}")
    
    print(f"\n✅ Analysis complete! This data can now be used by your AI model for scheduling decisions.")


if __name__ == "__main__":
    main()
