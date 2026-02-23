from supabase import create_client
import os
from dotenv import load_dotenv
from datetime import datetime
import statistics

load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY")

supabase = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)


class AISRiPerformancePredictionAgent:

    def get_recent_paces(self, athlete_id):

        response = supabase.table("workouts") \
            .select("average_pace, distance") \
            .eq("athlete_id", athlete_id) \
            .order("created_at", desc=True) \
            .limit(20) \
            .execute()

        return response.data


    def get_latest_aisri(self, athlete_id):

        response = supabase.table("AISRI_assessments") \
            .select("aisri_score") \
            .eq("athlete_id", athlete_id) \
            .order("created_at", desc=True) \
            .limit(1) \
            .execute()

        if not response.data:
            return 50

        return response.data[0]["aisri_score"]


    def estimate_vo2max(self, avg_pace_sec):

        # Simple estimation model
        speed_mps = 1000 / avg_pace_sec
        vo2 = (speed_mps * 3.5 * 60) / 10

        return round(vo2, 1)


    def predict_race_time(self, pace_sec, distance_km):

        total_seconds = pace_sec * distance_km

        minutes = int(total_seconds // 60)
        seconds = int(total_seconds % 60)

        return f"{minutes}:{seconds:02d}"


    def adjust_for_aisri(self, pace, aisri_score):

        if aisri_score < 40:
            return pace * 1.10
        elif aisri_score < 55:
            return pace * 1.05
        elif aisri_score < 70:
            return pace * 1.02
        elif aisri_score < 85:
            return pace * 0.98
        else:
            return pace * 0.95


    def predict_performance(self, athlete_id):

        workouts = self.get_recent_paces(athlete_id)

        if not workouts:
            return {"status": "error", "message": "No workout data"}

        paces = [
            w["average_pace"]
            for w in workouts
            if w.get("average_pace") and w["average_pace"] > 0
        ]

        if not paces:
            return {"status": "error", "message": "No pace data"}

        avg_pace = statistics.mean(paces)

        aisri_score = self.get_latest_aisri(athlete_id)

        adjusted_pace = self.adjust_for_aisri(avg_pace, aisri_score)

        vo2max = self.estimate_vo2max(adjusted_pace)

        predictions = {
            "5K": self.predict_race_time(adjusted_pace, 5),
            "10K": self.predict_race_time(adjusted_pace, 10),
            "Half Marathon": self.predict_race_time(adjusted_pace, 21.1),
            "Marathon": self.predict_race_time(adjusted_pace, 42.2),
        }

        self.save_prediction(
            athlete_id,
            vo2max,
            predictions
        )

        return {
            "status": "success",
            "athlete_id": athlete_id,
            "vo2max": vo2max,
            "aisri_score": aisri_score,
            "predictions": predictions
        }


    def save_prediction(self, athlete_id, vo2max, predictions):

        supabase.table("race_predictions").insert({
            "athlete_id": athlete_id,
            "vo2max": vo2max,
            "predicted_5k": predictions["5K"],
            "predicted_10k": predictions["10K"],
            "predicted_half_marathon": predictions["Half Marathon"],
            "predicted_marathon": predictions["Marathon"],
            "created_at": datetime.utcnow().isoformat()
        }).execute()


if __name__ == "__main__":

    agent = AISRiPerformancePredictionAgent()

    result = agent.predict_performance("TEST-ATHLETE-ID")

    print(result)
