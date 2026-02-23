from supabase import create_client
import os
from dotenv import load_dotenv
from datetime import datetime, timedelta
import statistics

load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY")

supabase = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)


class AISRiInjuryPredictionAgent:

    def get_aisri_history(self, athlete_id):

        response = supabase.table("AISRI_assessments") \
            .select("aisri_score, created_at") \
            .eq("athlete_id", athlete_id) \
            .order("created_at", desc=True) \
            .limit(14) \
            .execute()

        return response.data


    def get_training_load(self, athlete_id):

        response = supabase.table("training_load_metrics") \
            .select("load_score, created_at") \
            .eq("athlete_id", athlete_id) \
            .order("created_at", desc=True) \
            .limit(14) \
            .execute()

        return response.data


    def calculate_load_ratio(self, loads):

        if len(loads) < 7:
            return 1.0

        acute = statistics.mean([l["load_score"] for l in loads[:7]])
        chronic = statistics.mean([l["load_score"] for l in loads])

        if chronic == 0:
            return 1.0

        return acute / chronic


    def calculate_aisri_trend(self, aisri_history):

        if len(aisri_history) < 2:
            return 0

        latest = aisri_history[0]["aisri_score"]
        older = aisri_history[-1]["aisri_score"]

        return latest - older


    def predict_injury_risk(self, athlete_id):

        aisri_history = self.get_aisri_history(athlete_id)
        loads = self.get_training_load(athlete_id)

        if not aisri_history:
            return {
                "status": "error",
                "message": "No AISRi data"
            }

        latest_score = aisri_history[0]["aisri_score"]

        load_ratio = self.calculate_load_ratio(loads) if loads else 1.0

        aisri_trend = self.calculate_aisri_trend(aisri_history)

        risk_score = 0

        # AISRi score contribution
        if latest_score < 40:
            risk_score += 40
        elif latest_score < 55:
            risk_score += 25
        elif latest_score < 70:
            risk_score += 15
        else:
            risk_score += 5

        # Load ratio contribution
        if load_ratio > 1.5:
            risk_score += 30
        elif load_ratio > 1.2:
            risk_score += 15

        # Trend contribution
        if aisri_trend < -10:
            risk_score += 25
        elif aisri_trend < -5:
            risk_score += 15

        risk_score = min(risk_score, 100)

        risk_level = self.get_risk_level(risk_score)

        self.save_prediction(athlete_id, risk_score, risk_level)

        return {
            "status": "success",
            "athlete_id": athlete_id,
            "risk_score": risk_score,
            "risk_level": risk_level,
            "load_ratio": load_ratio,
            "aisri_trend": aisri_trend,
            "latest_aisri_score": latest_score
        }


    def get_risk_level(self, risk_score):

        if risk_score >= 70:
            return "HIGH"
        elif risk_score >= 40:
            return "MODERATE"
        else:
            return "LOW"


    def save_prediction(self, athlete_id, risk_score, risk_level):

        supabase.table("injury_risk_predictions").insert({
            "athlete_id": athlete_id,
            "risk_score": risk_score,
            "risk_level": risk_level,
            "created_at": datetime.utcnow().isoformat()
        }).execute()


if __name__ == "__main__":

    agent = AISRiInjuryPredictionAgent()

    athlete_id = "TEST-ATHLETE-ID"

    result = agent.predict_injury_risk(athlete_id)

    print(result)
