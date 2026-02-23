"""
Simple Daily AISRi Cycle

Minimal script that runs all 3 AI agents for each athlete.
No database saving, no logging - just the core functionality.
"""
import requests

BASE = "https://aisri-ai-engine-production.up.railway.app"  # Production API

athletes = requests.post(
    f"{BASE}/agent/commander",
    json={"goal": "list_athletes"}
).json()["result"]

for athlete in athletes:

    athlete_id = athlete["id"]

    requests.post(
        f"{BASE}/agent/autonomous-decision",
        json={"athlete_id": athlete_id}
    )

    requests.post(
        f"{BASE}/agent/predict-injury-risk",
        json={"athlete_id": athlete_id}
    )

    requests.post(
        f"{BASE}/agent/generate-workout",
        json={"athlete_id": athlete_id}
    )

print("AISRi daily cycle complete")
