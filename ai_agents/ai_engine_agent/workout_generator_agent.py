from supabase import create_client
import os
from dotenv import load_dotenv
from datetime import datetime, timedelta
import uuid

load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY")

supabase = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)


class AISRiWorkoutGeneratorAgent:

    def get_latest_aisri_score(self, athlete_id):

        response = supabase.table("AISRI_assessments") \
            .select("*") \
            .eq("athlete_id", athlete_id) \
            .order("created_at", desc=True) \
            .limit(1) \
            .execute()

        if not response.data:
            return None

        return response.data[0]


    def determine_zone(self, aisri_score):

        # AISRi safety gates
        if aisri_score < 40:
            return "AR"   # Active Recovery
        elif aisri_score < 55:
            return "F"    # Foundation
        elif aisri_score < 70:
            return "EN"   # Endurance
        elif aisri_score < 85:
            return "TH"   # Threshold
        else:
            return "P"    # Power


    def generate_workout_structure(self, zone):

        workouts = {
            "AR": {
                "name": "Active Recovery Run",
                "duration": 30,
                "intensity": "Very Easy",
                "description": "Low intensity recovery run"
            },
            "F": {
                "name": "Foundation Run",
                "duration": 45,
                "intensity": "Easy Aerobic",
                "description": "Build aerobic base safely"
            },
            "EN": {
                "name": "Endurance Run",
                "duration": 60,
                "intensity": "Moderate Aerobic",
                "description": "Improve endurance capacity"
            },
            "TH": {
                "name": "Threshold Workout",
                "duration": 50,
                "intensity": "Lactate Threshold",
                "description": "Improve lactate threshold safely"
            },
            "P": {
                "name": "Power Intervals",
                "duration": 45,
                "intensity": "High Intensity",
                "description": "Improve speed and power"
            }
        }

        return workouts.get(zone)


    def save_workout(self, athlete_id, workout):

        workout_id = str(uuid.uuid4())

        # Save to ai_workouts table
        supabase.table("ai_workouts").insert({
            "id": workout_id,
            "athlete_id": athlete_id,
            "name": workout["name"],
            "description": workout["description"],
            "duration_minutes": workout["duration"],
            "intensity": workout["intensity"],
            "created_at": datetime.utcnow().isoformat()
        }).execute()

        # Assign workout
        supabase.table("workout_assignments").insert({
            "athlete_id": athlete_id,
            "workout_id": workout_id,
            "scheduled_date": (datetime.utcnow() + timedelta(days=1)).date().isoformat(),
            "status": "scheduled"
        }).execute()

        return workout_id


    def generate_workout(self, athlete_id):

        aisri_data = self.get_latest_aisri_score(athlete_id)

        if not aisri_data:
            return {
                "status": "error",
                "message": "No AISRi score found"
            }

        aisri_score = aisri_data["aisri_score"]

        zone = self.determine_zone(aisri_score)

        workout = self.generate_workout_structure(zone)

        # TODO: Implement save_workout after creating required tables
        # workout_id = self.save_workout(athlete_id, workout)
        workout_id = "generated-workout-" + str(aisri_score)

        return {
            "status": "success",
            "athlete_id": athlete_id,
            "aisri_score": aisri_score,
            "zone": zone,
            "workout": workout,
            "workout_id": workout_id
        }


if __name__ == "__main__":

    agent = AISRiWorkoutGeneratorAgent()

    # test athlete id
    athlete_id = "TEST-ATHLETE-ID"

    result = agent.generate_workout(athlete_id)

    print(result)
