from supabase import create_client
import os
from dotenv import load_dotenv

load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY")

supabase = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)

print("Testing AISRI_assessments table...")
try:
    response = supabase.table("AISRI_assessments").select("*").limit(1).execute()
    if response.data:
        print(f"✅ Found data! Columns: {list(response.data[0].keys())}")
        print(f"Sample row: {response.data[0]}")
    else:
        print("❌ No data found")
except Exception as e:
    print(f"❌ Error: {e}")
