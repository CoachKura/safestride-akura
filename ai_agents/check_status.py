"""Check database status after daily_runner.py execution"""
import os
from datetime import datetime
from dotenv import load_dotenv
from supabase import create_client

# Load environment
load_dotenv()
load_dotenv('../.env')

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_KEY") or os.getenv("SUPABASE_ANON_KEY")

supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

print("\n" + "="*60)
print("📊 DATABASE STATUS CHECK")
print("="*60)

# AI Decisions
decisions = supabase.table('ai_decisions').select('*').order('created_at', desc=True).limit(10).execute()
print(f"\n✅ AI Decisions: {len(decisions.data)} total records")
if decisions.data:
    print("\n   Latest 5:")
    for d in decisions.data[:5]:
        created = d['created_at'][:19].replace('T', ' ')
        print(f"   [{created}] {d.get('decision', 'N/A'):12} AISRI: {d.get('aisri_score', 'N/A')}")

# Injury Predictions
injuries = supabase.table('injury_risk_predictions').select('*').order('created_at', desc=True).limit(10).execute()
print(f"\n🏥 Injury Predictions: {len(injuries.data)} total records")
if injuries.data:
    print("\n   Latest 5:")
    for i in injuries.data[:5]:
        created = i['created_at'][:19].replace('T', ' ')
        print(f"   [{created}] Risk: {i.get('risk_level', 'N/A')}")

# Workouts
workouts = supabase.table('workouts').select('*').order('created_at', desc=True).limit(10).execute()
print(f"\n💪 Workouts: {len(workouts.data)} total records")
if workouts.data:
    print("\n   Latest 5:")
    for w in workouts.data[:5]:
        created = w['created_at'][:19].replace('T', ' ')
        workout_type = w.get('workout_type', 'N/A')
        duration = w.get('duration_minutes', 0)
        print(f"   [{created}] {workout_type} ({duration}min)")

print("\n" + "="*60)
print("✅ Status check complete!")
print("="*60 + "\n")
