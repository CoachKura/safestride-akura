# Schedule Daily Runner with Windows Task Scheduler

## Quick Setup

**Option 1: PowerShell Command**
```powershell
# Create a scheduled task to run daily at 4:00 AM
$action = New-ScheduledTaskAction -Execute "python" -Argument "C:\safestride\ai_agents\daily_runner.py" -WorkingDirectory "C:\safestride\ai_agents"
$trigger = New-ScheduledTaskTrigger -Daily -At 4:00AM
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable
Register-ScheduledTask -TaskName "SafeStrideAICoaching" -Action $action -Trigger $trigger -Settings $settings -Description "Daily AI coaching decisions for all athletes"
```

**Option 2: GUI Setup**
1. Open Task Scheduler (search "Task Scheduler" in Windows)
2. Click "Create Basic Task"
3. Name: `SafeStride AI Coaching`
4. Trigger: Daily at 4:00 AM
5. Action: Start a program
   - Program: `python`
   - Arguments: `C:\safestride\ai_agents\daily_runner.py`
   - Start in: `C:\safestride\ai_agents`
6. Finish!

## Testing

**Test it now (instead of waiting until 4 AM):**
```powershell
cd C:\safestride\ai_agents
python daily_runner.py
```

You'll see output like:
```
[2026-02-22 10:30:00] ======================================
[2026-02-22 10:30:00] 🚀 Starting Daily Coaching Run
[2026-02-22 10:30:00] ======================================
[2026-02-22 10:30:00] Fetching all athletes...
[2026-02-22 10:30:01] Found 7 athletes
[2026-02-22 10:30:01] 
[2026-02-22 10:30:01] 👤 Processing: Muthulakshmi (33308fc1-3545-431d-a5e7-648b52e1866c)
[2026-02-22 10:30:01] --------------------------------------------------
[2026-02-22 10:30:02] Getting decision for athlete...
[2026-02-22 10:30:03]   Decision: LIGHT_TRAIN
[2026-02-22 10:30:03]   Reason: Limited training recommended
[2026-02-22 10:30:03]   AISRI Score: 68
[2026-02-22 10:30:03]   Injury Risk: LOW
[2026-02-22 10:30:03] Saving decision to database...
[2026-02-22 10:30:04] ✅ Decision saved to database
...
[2026-02-22 10:30:45] ======================================
[2026-02-22 10:30:45] 📊 SUMMARY
[2026-02-22 10:30:45] ======================================
[2026-02-22 10:30:45] Total Athletes: 7
[2026-02-22 10:30:45] Successful: 7
[2026-02-22 10:30:45] Failed: 0
[2026-02-22 10:30:45] 
[2026-02-22 10:30:45] Decisions by type:
[2026-02-22 10:30:45]   LIGHT_TRAIN: 4
[2026-02-22 10:30:45]   REST: 2
[2026-02-22 10:30:45]   TRAIN: 1
```

## Prerequisites

**Make sure FastAPI server is running:**
```powershell
# In a separate PowerShell window (keep it open):
cd C:\safestride\ai_agents
python main.py
```

You should see:
```
INFO:     Uvicorn running on http://127.0.0.1:8001 (Press CTRL+C to quit)
```

## Auto-Start FastAPI Server (Optional)

If you want the FastAPI server to start automatically with Windows:

1. Create `C:\safestride\ai_agents\start-fastapi.bat`:
```bat
@echo off
cd C:\safestride\ai_agents
python main.py
pause
```

2. Add to Windows Startup:
   - Press `Win+R`, type `shell:startup`, press Enter
   - Create shortcut to `start-fastapi.bat`
   - Server will start on boot!

## Benefits Over n8n

✅ **Simpler**: Just pure Python, no complex workflow configuration
✅ **Faster**: Direct API calls,no middleware
✅ **Easier to debug**: Just read the Python code
✅ **Better logging**: Timestamped console output
✅ **No dependencies**: Doesn't require n8nrunning
✅ **Easy to customize**: Modify the Python script directly

## Logs

Output will be in the console. To save logs:

```powershell
python daily_runner.py > C:\safestride\logs\coaching_$(Get-Date -Format 'yyyy-MM-dd').log 2>&1
```

Or redirect in Task Scheduler:
- Edit the task
- Actions → Edit
- Add to Arguments: `C:\safestride\ai_agents\daily_runner.py > C:\safestride\logs\daily.log 2>&1`

## Troubleshooting

**"Cannot connect to FastAPI server"**
- Make sure `python main.py` is running in another window
- Check if port 8001 is accessible: `Invoke-WebRequest http://127.0.0.1:8001`

**"Supabase not configured"**
- Decisions still work, but won't be saved to database
- Check `.env` file has `SUPABASE_URL` and `SUPABASE_SERVICE_KEY`

**"No athletes found"**
- Check database has athletes in `profiles` table
- Verify Supabase connection

## Monitoring

Check decisions in Supabase:
```sql
SELECT 
    created_at,
    athlete_id,
    decision,
    aisri_score,
    injury_risk->'risk_level' as risk_level
FROM ai_decisions
ORDER BY created_at DESC
LIMIT 20;
```

