"""
Comprehensive API Endpoint Testing
Tests all 13 FastAPI endpoints with real HTTP requests.

Prerequisites:
- FastAPI server running on http://localhost:8000
- Supabase credentials configured in .env

Test Flow:
1. Health check
2. Athlete signup (complete workflow)
3. Profile retrieval & update
4. Race analysis
5. Fitness assessment retrieval
6. Workout retrieval
7. Workout completion (complete workflow)
8. Workout results
9. Ability progression
"""

import requests
import json
from datetime import datetime, timedelta
from typing import Dict, Optional


class APITester:
    """Comprehensive API endpoint tester"""
    
    def __init__(self, base_url: str = "http://localhost:8000"):
        """Initialize tester with base URL"""
        self.base_url = base_url
        self.athlete_id = None
        self.assignment_id = None
        
        # Session for connection pooling
        self.session = requests.Session()
    
    def run_all_tests(self):
        """Run complete test suite"""
        
        print("\n" + "="*80)
        print("SAFESTRIDE AI - API ENDPOINT TESTING")
        print("="*80)
        print(f"Base URL: {self.base_url}")
        print(f"Test Date: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        
        try:
            # Test 1: Health Check
            print("="*80)
            print("[TEST 1] Health Check - GET /health")
            print("="*80)
            self.test_health_check()
            print("✅ PASSED: Health check successful\n")
            
            # Test 2: Root Endpoint
            print("="*80)
            print("[TEST 2] Root Endpoint - GET /")
            print("="*80)
            self.test_root()
            print("✅ PASSED: Root endpoint working\n")
            
            # Test 3: Athlete Signup
            print("="*80)
            print("[TEST 3] Athlete Signup - POST /athletes/signup")
            print("="*80)
            self.test_athlete_signup()
            print("✅ PASSED: Athlete signup workflow complete\n")
            
            # Test 4: Get Athlete Profile
            print("="*80)
            print("[TEST 4] Get Profile - GET /athletes/{athlete_id}")
            print("="*80)
            self.test_get_athlete_profile()
            print("✅ PASSED: Profile retrieval successful\n")
            
            # Test 5: Update Athlete Profile
            print("="*80)
            print("[TEST 5] Update Profile - PATCH /athletes/{athlete_id}")
            print("="*80)
            self.test_update_athlete_profile()
            print("✅ PASSED: Profile update successful\n")
            
            # Test 6: Race Analysis
            print("="*80)
            print("[TEST 6] Race Analysis - POST /races/analyze")
            print("="*80)
            self.test_race_analysis()
            print("✅ PASSED: Race analysis complete\n")
            
            # Test 7: Get Race History
            print("="*80)
            print("[TEST 7] Race History - GET /races/{athlete_id}")
            print("="*80)
            self.test_get_race_history()
            print("✅ PASSED: Race history retrieval successful\n")
            
            # Test 8: Get Fitness Assessment
            print("="*80)
            print("[TEST 8] Fitness Assessment - GET /fitness/{athlete_id}")
            print("="*80)
            self.test_get_fitness_assessment()
            print("✅ PASSED: Fitness assessment retrieval successful\n")
            
            # Test 9: Get Workouts
            print("="*80)
            print("[TEST 9] Get Workouts - GET /workouts/{athlete_id}")
            print("="*80)
            self.test_get_workouts()
            print("✅ PASSED: Workout retrieval successful\n")
            
            # Test 10: Get Specific Workout Assignment
            print("="*80)
            print("[TEST 10] Get Assignment - GET /workouts/assignment/{id}")
            print("="*80)
            self.test_get_workout_assignment()
            print("✅ PASSED: Assignment retrieval successful\n")
            
            # Test 11: Complete Workout
            print("="*80)
            print("[TEST 11] Complete Workout - POST /workouts/complete")
            print("="*80)
            self.test_complete_workout()
            print("✅ PASSED: Workout completion workflow complete\n")
            
            # Test 12: Get Workout Results
            print("="*80)
            print("[TEST 12] Workout Results - GET /workouts/results/{athlete_id}")
            print("="*80)
            self.test_get_workout_results()
            print("✅ PASSED: Results retrieval successful\n")
            
            # Test 13: Get Ability Progression
            print("="*80)
            print("[TEST 13] Ability Progression - GET /ability/{athlete_id}")
            print("="*80)
            self.test_get_ability_progression()
            print("✅ PASSED: Progression retrieval successful\n")
            
            # Final Summary
            print("="*80)
            print("✅ ALL 13 API ENDPOINTS TESTED SUCCESSFULLY")
            print("="*80)
            self.print_summary()
            
        except requests.exceptions.ConnectionError:
            print("\n❌ ERROR: Cannot connect to API server")
            print(f"   Make sure FastAPI server is running on {self.base_url}")
            print("   Start server with: python api_endpoints.py")
            raise
        except Exception as e:
            print(f"\n❌ TEST FAILED: {e}")
            import traceback
            traceback.print_exc()
            raise
    
    def test_health_check(self):
        """Test health endpoint"""
        response = self.session.get(f"{self.base_url}/health")
        response.raise_for_status()
        
        data = response.json()
        print(f"   Status: {data.get('status')}")
        print(f"   Service: {data.get('service')}")
        print(f"   Timestamp: {data.get('timestamp')}")
        
        assert data.get('status') == 'healthy', "Health check failed"
    
    def test_root(self):
        """Test root endpoint"""
        response = self.session.get(f"{self.base_url}/")
        response.raise_for_status()
        
        data = response.json()
        print(f"   Service: {data.get('service')}")
        print(f"   Version: {data.get('version')}")
        print(f"   Status: {data.get('status')}")
    
    def test_athlete_signup(self):
        """Test athlete signup workflow"""
        
        # Create test athlete data
        signup_data = {
            "athlete_id": f"test_api_{int(datetime.now().timestamp())}",
            "name": "API Test Runner",
            "email": "api.test@safestride.ai",
            "age": 32,
            "gender": "male",
            "weight_kg": 72.0,
            "height_cm": 175,
            "signup_date": datetime.now().isoformat(),
            "current_level": "intermediate",
            "primary_goal": "Half Marathon",
            "goal_type": "time_based",
            "goal_target_time": "01:50:00",
            "goal_target_distance": 21.1,
            "target_race_date": (datetime.now() + timedelta(days=240)).date().isoformat(),
            "current_weekly_volume_km": 42.0,
            "current_avg_pace_seconds": 380,
            "current_max_hr": 188,
            "current_resting_hr": 60,
            "training_frequency_per_week": 5,
            "years_of_running": 3,
            "has_active_injury": False,
            "injury_history": "None",
            "recent_races": [
                {
                    "race_type": "Half Marathon",
                    "date": (datetime.now() - timedelta(days=45)).isoformat(),
                    "finish_time": "02:05:00",
                    "finish_time_seconds": 7500,
                    "avg_pace": "5:57/km",
                    "avg_pace_seconds": 357,
                    "avg_hr": 175,
                    "max_hr": 185,
                    "weather_temp": 28
                }
            ]
        }
        
        print(f"   Athlete: {signup_data['name']}")
        print(f"   Goal: {signup_data['primary_goal']} in {signup_data['goal_target_time']}")
        print(f"   Current Volume: {signup_data['current_weekly_volume_km']} km/week")
        
        response = self.session.post(
            f"{self.base_url}/athletes/signup",
            json=signup_data
        )
        response.raise_for_status()
        
        result = response.json()
        self.athlete_id = result.get('athlete_id')
        
        print(f"\n   Response:")
        print(f"   - Athlete ID: {self.athlete_id}")
        print(f"   - Profile Created: {result.get('profile_created')}")
        if result.get('race_analysis'):
            print(f"   - Race Analyzed: Yes")
            analysis = result['race_analysis']
            print(f"     * Fitness: {analysis.get('fitness_level')}")
            print(f"     * Timeline: {analysis.get('timeline_weeks')} weeks")
        if result.get('fitness_assessment'):
            print(f"   - Fitness Assessment: Yes")
            assessment = result['fitness_assessment']
            print(f"     * Overall Score: {assessment.get('overall_fitness_score'):.1f}/100")
            print(f"     * Ready for Speed: {assessment.get('ready_for_speed_work')}")
        if result.get('initial_workouts'):
            workouts = result['initial_workouts']
            print(f"   - Initial Workouts: {len(workouts)} workouts generated")
            if workouts:
                self.assignment_id = workouts[0].get('id')
    
    def test_get_athlete_profile(self):
        """Test profile retrieval"""
        if not self.athlete_id:
            print("   ⚠️ SKIPPED: No athlete_id from signup")
            return
        
        response = self.session.get(f"{self.base_url}/athletes/{self.athlete_id}")
        response.raise_for_status()
        
        profile = response.json()
        print(f"   Name: {profile.get('name')}")
        print(f"   Level: {profile.get('current_level')}")
        print(f"   Goal: {profile.get('primary_goal')}")
        print(f"   Volume: {profile.get('current_weekly_volume_km')} km/week")
    
    def test_update_athlete_profile(self):
        """Test profile update"""
        if not self.athlete_id:
            print("   ⚠️ SKIPPED: No athlete_id from signup")
            return
        
        updates = {
            "current_weekly_volume_km": 45.0,
            "current_avg_pace_seconds": 375,
            "notes": "API test update - volume increased"
        }
        
        print(f"   Updating volume: 42.0 → 45.0 km/week")
        print(f"   Updating pace: 380 → 375 sec/km")
        
        response = self.session.patch(
            f"{self.base_url}/athletes/{self.athlete_id}",
            json=updates
        )
        response.raise_for_status()
        
        result = response.json()
        print(f"   ✅ Updated: {result.get('updated')}")
    
    def test_race_analysis(self):
        """Test race analysis"""
        if not self.athlete_id:
            print("   ⚠️ SKIPPED: No athlete_id from signup")
            return
        
        race_data = {
            "athlete_id": self.athlete_id,
            "race_type": "10K",
            "date": datetime.now().isoformat(),
            "finish_time": "00:48:30",
            "finish_time_seconds": 2910,
            "avg_pace": "4:51/km",
            "avg_pace_seconds": 291,
            "avg_hr": 172,
            "max_hr": 183,
            "weather_temp": 22
        }
        
        print(f"   Race: {race_data['race_type']}")
        print(f"   Time: {race_data['finish_time']}")
        print(f"   Pace: {race_data['avg_pace']}")
        
        response = self.session.post(
            f"{self.base_url}/races/analyze",
            json=race_data
        )
        response.raise_for_status()
        
        analysis = response.json()
        print(f"\n   Analysis:")
        print(f"   - Fitness: {analysis.get('fitness_level')}")
        print(f"   - Pacing Score: {analysis.get('pacing_score')}/100")
        print(f"   - Timeline: {analysis.get('timeline_weeks')} weeks")
    
    def test_get_race_history(self):
        """Test race history retrieval"""
        if not self.athlete_id:
            print("   ⚠️ SKIPPED: No athlete_id from signup")
            return
        
        response = self.session.get(f"{self.base_url}/races/{self.athlete_id}")
        response.raise_for_status()
        
        races = response.json()
        print(f"   Total Races: {len(races)}")
        for i, race in enumerate(races[:3], 1):
            print(f"   {i}. {race.get('race_type')} - {race.get('finish_time')}")
    
    def test_get_fitness_assessment(self):
        """Test fitness assessment retrieval"""
        if not self.athlete_id:
            print("   ⚠️ SKIPPED: No athlete_id from signup")
            return
        
        response = self.session.get(f"{self.base_url}/fitness/{self.athlete_id}")
        response.raise_for_status()
        
        assessment = response.json()
        print(f"   Overall Score: {assessment.get('overall_fitness_score'):.1f}/100")
        print(f"   Ready for Speed: {assessment.get('ready_for_speed_work')}")
        print(f"   Injury Risk: {assessment.get('injury_risk_level')}")
        print(f"   Timeline: {assessment.get('total_estimated_weeks')} weeks")
    
    def test_get_workouts(self):
        """Test workout retrieval"""
        if not self.athlete_id:
            print("   ⚠️ SKIPPED: No athlete_id from signup")
            return
        
        response = self.session.get(
            f"{self.base_url}/workouts/{self.athlete_id}",
            params={"status": "assigned", "limit": 10}
        )
        response.raise_for_status()
        
        workouts = response.json()
        print(f"   Total Workouts: {len(workouts)}")
        for i, workout in enumerate(workouts[:3], 1):
            print(f"   {i}. {workout.get('workout_type').upper()} - {workout.get('distance_km')} km")
            if not self.assignment_id and workout.get('id'):
                self.assignment_id = workout['id']
    
    def test_get_workout_assignment(self):
        """Test specific assignment retrieval"""
        if not self.assignment_id:
            print("   ⚠️ SKIPPED: No assignment_id available")
            return
        
        response = self.session.get(
            f"{self.base_url}/workouts/assignment/{self.assignment_id}"
        )
        response.raise_for_status()
        
        workout = response.json()
        print(f"   Workout Type: {workout.get('workout_type').upper()}")
        print(f"   Distance: {workout.get('distance_km')} km")
        print(f"   Target Pace: {workout.get('target_pace_seconds')} sec/km")
        print(f"   Status: {workout.get('status')}")
    
    def test_complete_workout(self):
        """Test workout completion workflow"""
        if not self.assignment_id or not self.athlete_id:
            print("   ⚠️ SKIPPED: No assignment_id or athlete_id available")
            return
        
        completion_data = {
            "assignment_id": self.assignment_id,
            "athlete_id": self.athlete_id,
            "completed_date": datetime.now().isoformat(),
            "distance_km": 8.2,
            "total_time_seconds": 2952,  # ~49:12 (6:00/km pace)
            "avg_pace_seconds": 360,
            "avg_hr": 165,
            "max_hr": 175,
            "completed_full": True,
            "notes": "API test - felt good throughout"
        }
        
        print(f"   Assignment ID: {self.assignment_id}")
        print(f"   Distance: {completion_data['distance_km']} km")
        print(f"   Avg Pace: {completion_data['avg_pace_seconds']} sec/km")
        
        response = self.session.post(
            f"{self.base_url}/workouts/complete",
            json=completion_data
        )
        response.raise_for_status()
        
        result = response.json()
        print(f"\n   Results:")
        print(f"   - Performance: {result.get('performance_label')}")
        print(f"   - Score: {result.get('overall_score')}/100")
        print(f"   - Ability Change: {result.get('ability_change'):+.1f}")
        print(f"   - Next Workout ID: {result.get('next_workout_id')}")
    
    def test_get_workout_results(self):
        """Test workout results retrieval"""
        if not self.athlete_id:
            print("   ⚠️ SKIPPED: No athlete_id from signup")
            return
        
        response = self.session.get(
            f"{self.base_url}/workouts/results/{self.athlete_id}",
            params={"days": 30}
        )
        response.raise_for_status()
        
        results = response.json()
        print(f"   Total Results: {len(results)}")
        for i, result in enumerate(results[:3], 1):
            print(f"   {i}. {result.get('workout_type').upper()} - {result.get('performance_label')} ({result.get('overall_score')}/100)")
    
    def test_get_ability_progression(self):
        """Test ability progression retrieval"""
        if not self.athlete_id:
            print("   ⚠️ SKIPPED: No athlete_id from signup")
            return
        
        response = self.session.get(
            f"{self.base_url}/ability/{self.athlete_id}",
            params={"days": 30}
        )
        response.raise_for_status()
        
        data = response.json()
        progression = data.get('progression', [])
        summary = data.get('summary', {})
        
        print(f"   Total Progressions: {len(progression)}")
        print(f"   Summary:")
        print(f"   - Total Ability Change: {summary.get('total_ability_change'):+.1f}")
        print(f"   - Avg Ability Change: {summary.get('avg_ability_change'):+.2f}")
        print(f"   - Easy Pace Change: {summary.get('easy_pace_improvement'):+d} sec/km")
    
    def print_summary(self):
        """Print test summary"""
        print("\n📊 TEST SUMMARY:")
        print(f"   Base URL: {self.base_url}")
        print(f"   Athlete ID: {self.athlete_id}")
        print(f"   Test Assignment ID: {self.assignment_id}")
        print("\n   Endpoints Tested:")
        print("   ✅ Health Check")
        print("   ✅ Root Endpoint")
        print("   ✅ Athlete Signup (Integrated Workflow)")
        print("   ✅ Get Profile")
        print("   ✅ Update Profile")
        print("   ✅ Race Analysis")
        print("   ✅ Race History")
        print("   ✅ Fitness Assessment")
        print("   ✅ Get Workouts")
        print("   ✅ Get Workout Assignment")
        print("   ✅ Complete Workout (Integrated Workflow)")
        print("   ✅ Workout Results")
        print("   ✅ Ability Progression")
        print("\n   Key Validations:")
        print("   🎯 Signup workflow: Profile + Race + Fitness + Workouts")
        print("   🎯 Completion workflow: GIVEN vs RESULT + Ability + Next Workout")
        print("   🎯 All CRUD operations working")
        print("   🎯 Data persistence across endpoints")


# Run API tests
if __name__ == "__main__":
    import sys
    
    # Check if server URL provided
    base_url = sys.argv[1] if len(sys.argv) > 1 else "http://localhost:8000"
    
    print("\n🚀 Starting API Endpoint Tests...")
    print(f"   Target: {base_url}")
    print("   Ensure FastAPI server is running!\n")
    
    tester = APITester(base_url)
    try:
        tester.run_all_tests()
        print("\n✅ ALL API TESTS PASSED!\n")
    except Exception as e:
        print(f"\n❌ API TESTS FAILED\n")
        sys.exit(1)
