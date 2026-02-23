from supabase import create_client
import os
from dotenv import load_dotenv
from datetime import datetime
import uuid

load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY")

supabase = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)


class AISRiAutonomousDecisionAgent:

    def get_aisri_score(self, athlete_id):

        response = supabase.table("AISRI_assessments") \
            .select("aisri_score") \
            .eq("athlete_id", athlete_id) \
            .order("created_at", desc=True) \
            .limit(1) \
            .execute()

        if not response.data:
            return 50

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


    def get_training_load(self, athlete_id):

        response = supabase.table("training_load_metrics") \
            .select("load_score") \
            .eq("athlete_id", athlete_id) \
            .order("created_at", desc=True) \
            .limit(7) \
            .execute()

        if not response.data:
            return 0

        loads = [l["load_score"] for l in response.data if l["load_score"]]

        return sum(loads) / len(loads) if loads else 0


    def decide_action(self, aisri_score, injury_risk, training_load):

        # Critical safety override
        if injury_risk["risk_level"] == "HIGH":
            return {
                "decision": "REST",
                "reason": "High injury risk detected"
            }

        if aisri_score < 40:
            return {
                "decision": "REST",
                "reason": "AISRi score critically low"
            }

        if training_load > 80:
            return {
                "decision": "RECOVERY",
                "reason": "Training load too high"
            }

        if aisri_score >= 85 and injury_risk["risk_level"] == "LOW":
            return {
                "decision": "INTENSIFY",
                "reason": "Athlete ready for high intensity"
            }

        if aisri_score >= 70:
            return {
                "decision": "TRAIN",
                "reason": "Safe to train at moderate intensity"
            }

        return {
            "decision": "LIGHT_TRAIN",
            "reason": "Limited training recommended"
        }


    def save_decision(self, athlete_id, decision, reason):

        supabase.table("ai_decisions").insert({
            "athlete_id": athlete_id,
            "decision": decision,
            "reason": reason,
            "created_at": datetime.utcnow().isoformat()
        }).execute()


    def run_decision_cycle(self, athlete_id):

        aisri_score = self.get_aisri_score(athlete_id)

        injury_risk = self.get_injury_risk(athlete_id)

        training_load = self.get_training_load(athlete_id)

        decision = self.decide_action(
            aisri_score,
            injury_risk,
            training_load
        )

        self.save_decision(
            athlete_id,
            decision["decision"],
            decision["reason"]
        )

        return {
            "status": "success",
            "athlete_id": athlete_id,
            "aisri_score": aisri_score,
            "injury_risk": injury_risk,
            "training_load": training_load,
            "decision": decision
        }


if __name__ == "__main__":

    agent = AISRiAutonomousDecisionAgent()

    result = agent.run_decision_cycle("athlete_1771670436116")

    print(result)

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


    def get_injury_risk(self, athlete_id):

        response = supabase.table("injury_risk_predictions") \
            .select("risk_level, risk_score") \
            .eq("athlete_id", athlete_id) \
            .order("created_at", desc=True) \
            .limit(1) \
            .execute()

        if not response.data:
            return {"risk_level": "MODERATE", "risk_score": 50}

        return response.data[0]


    def get_recent_workouts(self, athlete_id, days=7):

        cutoff_date = (datetime.now() - timedelta(days=days)).isoformat()

        response = supabase.table("workouts") \
            .select("*") \
            .eq("athlete_id", athlete_id) \
            .gte("created_at", cutoff_date) \
            .order("created_at", desc=True) \
            .execute()

        return response.data if response.data else []


    def get_active_training_plan(self, athlete_id):

        response = supabase.table("ai_workout_plans") \
            .select("*") \
            .eq("athlete_id", athlete_id) \
            .eq("status", "active") \
            .order("created_at", desc=True) \
            .limit(1) \
            .execute()

        if not response.data:
            return None

        plan_id = response.data[0]["id"]

        assignments = supabase.table("workout_assignments") \
            .select("*") \
            .eq("plan_id", plan_id) \
            .gte("scheduled_date", datetime.now().date().isoformat()) \
            .order("scheduled_date", asc=True) \
            .execute()

        return {
            "plan": response.data[0],
            "upcoming_workouts": assignments.data if assignments.data else []
        }


    def calculate_training_load(self, workouts):

        if not workouts:
            return 0

        total_load = 0

        for workout in workouts:
            duration = workout.get("duration_minutes", 0)
            distance = workout.get("distance", 0)

            load = (duration * 0.6) + (distance * 0.4)
            total_load += load

        return round(total_load, 1)


    def should_modify_workout(self, aisri_score, risk_level, recent_load):

        if risk_level == "HIGH":
            return True, "High injury risk detected"

        if aisri_score < 40:
            return True, "Low AISRI score - needs recovery"

        if recent_load > 300:
            return True, "High training load - risk of overtraining"

        return False, "Continue as planned"


    def recommend_workout_adjustment(self, aisri_score, risk_level):

        if risk_level == "HIGH":
            return {
                "action": "SKIP",
                "recommendation": "Skip today's workout. Focus on recovery.",
                "alternative": "Light stretching or yoga"
            }

        if aisri_score < 40:
            return {
                "action": "REDUCE",
                "recommendation": "Reduce intensity by 30-40%.",
                "alternative": "Active recovery: 20-30 min easy pace"
            }

        if aisri_score < 55:
            return {
                "action": "MODERATE",
                "recommendation": "Reduce intensity by 10-20%.",
                "alternative": "Foundation run: maintain easy conversational pace"
            }

        if aisri_score > 85:
            return {
                "action": "INCREASE",
                "recommendation": "You're ready for harder efforts.",
                "alternative": "Consider adding intervals or tempo work"
            }

        return {
            "action": "CONTINUE",
            "recommendation": "Proceed as planned.",
            "alternative": None
        }


    def make_decision(self, athlete_id):

        aisri_score = self.get_latest_aisri(athlete_id)

        injury_risk = self.get_injury_risk(athlete_id)
        risk_level = injury_risk.get("risk_level", "MODERATE")
        risk_score = injury_risk.get("risk_score", 50)

        recent_workouts = self.get_recent_workouts(athlete_id, days=7)
        training_load = self.calculate_training_load(recent_workouts)

        active_plan = self.get_active_training_plan(athlete_id)

        should_modify, reason = self.should_modify_workout(
            aisri_score,
            risk_level,
            training_load
        )

        adjustment = self.recommend_workout_adjustment(aisri_score, risk_level)

        next_workout = None
        if active_plan and active_plan["upcoming_workouts"]:
            next_workout = active_plan["upcoming_workouts"][0]

        decision = {
            "status": "success",
            "athlete_id": athlete_id,
            "timestamp": datetime.now().isoformat(),
            "data_summary": {
                "aisri_score": aisri_score,
                "injury_risk_level": risk_level,
                "injury_risk_score": risk_score,
                "recent_training_load_7d": training_load,
                "workouts_completed_7d": len(recent_workouts)
            },
            "decision": {
                "should_modify": should_modify,
                "reason": reason,
                "action": adjustment["action"],
                "recommendation": adjustment["recommendation"],
                "alternative": adjustment["alternative"]
            },
            "next_scheduled_workout": next_workout
        }

        self.save_decision(athlete_id, decision)

        return decision


    def save_decision(self, athlete_id, decision):

        try:
            supabase.table("autonomous_decisions").insert({
                "athlete_id": athlete_id,
                "aisri_score": decision["data_summary"]["aisri_score"],
                "injury_risk_level": decision["data_summary"]["injury_risk_level"],
                "training_load": decision["data_summary"]["recent_training_load_7d"],
                "decision_action": decision["decision"]["action"],
                "recommendation": decision["decision"]["recommendation"],
                "created_at": datetime.utcnow().isoformat()
            }).execute()
        except Exception as e:
            print(f"Could not save decision: {str(e)}")


if __name__ == "__main__":

    agent = AISRiAutonomousDecisionAgent()

    result = agent.make_decision("athlete_1771670436116")

    print(f"Decision for Athlete: {result['athlete_id']}")
    print(f"AISRI: {result['data_summary']['aisri_score']}")
    print(f"Risk Level: {result['data_summary']['injury_risk_level']}")
    print(f"Should Modify: {result['decision']['should_modify']}")
    print(f"Action: {result['decision']['action']}")
    print(f"Recommendation: {result['decision']['recommendation']}")
