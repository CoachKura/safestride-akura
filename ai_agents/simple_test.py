import requests

BASE = "http://127.0.0.1:8001"

print("Starting simple 3-agent test...")
print()

athletes = requests.post(
    f"{BASE}/agent/commander",
    json={"goal": "list_athletes"}
).json()["result"]

print(f"Found {len(athletes)} athletes")
print()

for i, athlete in enumerate(athletes, 1):
    athlete_id = athlete["id"]
    name = athlete.get("full_name", "Unknown")
    
    print(f"{i}. {name}")
    print(f"   ID: {athlete_id}")
    
    try:
        # Decision
        r1 = requests.post(f"{BASE}/agent/autonomous-decision", json={"athlete_id": athlete_id})
        print(f"   ✓ Decision: {r1.status_code}")
        
        # Injury
        r2 = requests.post(f"{BASE}/agent/predict-injury-risk", json={"athlete_id": athlete_id})
        print(f"   ✓ Injury: {r2.status_code}")
        
        # Workout
        r3 = requests.post(f"{BASE}/agent/generate-workout", json={"athlete_id": athlete_id})
        print(f"   ✓ Workout: {r3.status_code}")
        print()
    except Exception as e:
        print(f"   ✗ ERROR: {e}")
        print()

print("AISRi daily cycle complete")
