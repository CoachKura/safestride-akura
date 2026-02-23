from supabase import create_client
import os
from dotenv import load_dotenv
from datetime import datetime, timedelta
import uuid

load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY")

supabase = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)


class AISRiAdaptiveTrainingPlanAgent:

    def get_latest_aisri(self, athlete_id):

        response = supabase.table("AISRI_assessments") \
            .select("aisri_score") \
            .eq("athlete_id", athlete_id) \
            .order("created_at", desc=True) \
            .limit(1) \
            .execute()

        if not response.data:
            return None

        return response.data[0]["aisri_score"]


    def get_injury_risk(self, athlete_id):

        response = supabase.table("injury_risk_predictions") \
            .select("risk_score, risk_level") \
            .eq("athlete_id", athlete_id) \
            .order("created_at", desc=True) \
            .limit(1) \
            .execute()

        if not response.data:
            return {"risk_score": 0, "risk_level": "LOW"}

        return response.data[0]


    def determine_week_structure(self, aisri_score, risk_level):

        # Safety-first logic
        if risk_level == "HIGH":
            return ["AR", "REST", "AR", "REST", "F", "REST", "REST"]

        if aisri_score < 40:
            return ["AR", "REST", "AR", "REST", "AR", "REST", "REST"]

        elif aisri_score < 55:
            return ["AR", "F", "REST", "F", "REST", "F", "REST"]

        elif aisri_score < 70:
            return ["AR", "EN", "REST", "EN", "REST", "F", "REST"]

        elif aisri_score < 85:
            return ["AR", "EN", "REST", "TH", "REST", "EN", "REST"]

        else:
            return ["AR", "EN", "REST", "TH", "REST", "P", "REST"]


    def get_workout_details(self, zone):

        mapping = {
            "AR": ("Active Recovery", 30),
            "F": ("Foundation Run", 45),
            "EN": ("Endurance Run", 60),
            "TH": ("Threshold Run", 50),
            "P": ("Power Intervals", 45),
            "REST": ("Rest Day", 0)
        }

        name, duration = mapping.get(zone, ("Rest Day", 0))

        return {
            "zone": zone,
            "name": name,
            "duration": duration
        }


    def create_plan_record(self, athlete_id):

        plan_id = str(uuid.uuid4())

        supabase.table("ai_workout_plans").insert({
            "id": plan_id,
            "athlete_id": athlete_id,
            "created_at": datetime.utcnow().isoformat(),
            "status": "active"
        }).execute()

        return plan_id


    def create_workout(self, athlete_id, plan_id, workout, date):

        if workout["zone"] == "REST":
            return

        workout_id = str(uuid.uuid4())

        supabase.table("ai_workouts").insert({
            "id": workout_id,
            "athlete_id": athlete_id,
            "name": workout["name"],
            "duration_minutes": workout["duration"],
            "zone": workout["zone"],
            "created_at": datetime.utcnow().isoformat()
        }).execute()

        supabase.table("workout_assignments").insert({
            "athlete_id": athlete_id,
            "workout_id": workout_id,
            "plan_id": plan_id,
            "scheduled_date": date.isoformat(),
            "status": "scheduled"
        }).execute()


    def generate_plan(self, athlete_id):

        aisri_score = self.get_latest_aisri(athlete_id)

        if aisri_score is None:
            return {"status": "error", "message": "No AISRi score"}

        injury = self.get_injury_risk(athlete_id)

        structure = self.determine_week_structure(
            aisri_score,
            injury["risk_level"]
        )

        plan_id = self.create_plan_record(athlete_id)

        start_date = datetime.utcnow().date()

        plan = []

        for i, zone in enumerate(structure):

            workout = self.get_workout_details(zone)

            date = start_date + timedelta(days=i)

            self.create_workout(
                athlete_id,
                plan_id,
                workout,
                date
            )

            plan.append({
                "date": date.isoformat(),
                "zone": zone,
                "name": workout["name"],
                "duration": workout["duration"]
            })

        return {
            "status": "success",
            "plan_id": plan_id,
            "athlete_id": athlete_id,
            "aisri_score": aisri_score,
            "injury_risk": injury,
            "weekly_plan": plan
        }


if __name__ == "__main__":

    agent = AISRiAdaptiveTrainingPlanAgent()

    result = agent.generate_plan("TEST-ATHLETE-ID")

    print(result)
