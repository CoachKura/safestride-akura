# n8n Daily AI Coaching Workflow Setup

## ✅ Prerequisites Complete
- FastAPI server running on port 8001
- Database tables deployed
- All endpoints tested and working

## 🚀 Quick Setup

### Step 1: Start n8n
```powershell
n8n
```
- Opens at: http://localhost:5678
- Create account if first time

### Step 2: Create New Workflow

**Option A - Import JSON:**
1. Click **Workflows** → **Import from File**
2. Select `n8n-ai-coaching-workflow.json`
3. Done! Skip to Step 3.

**Option B - Manual Setup:**

#### Node 1: Schedule Trigger
- Type: **Schedule Trigger**
- Mode: **Cron**
- Expression: `0 4 * * *` (4:00 AM daily)

#### Node 2: HTTP Request - List Athletes
- Name: **List All Athletes**
- URL: `http://127.0.0.1:8001/agent/commander`
- Method: **POST**
- Body: JSON
```json
{
  "goal": "list_athletes"
}
```

#### Node 3: Split Out
- Name: **Split Athletes**
- Field to Split Out: `result`
- This loops through each athlete

#### Node 4: HTTP Request - Get Decision
- Name: **Get Decision**
- URL: `http://127.0.0.1:8001/agent/autonomous-decision`
- Method: **POST**
- Body: JSON
```json
{
  "athlete_id": "{{$json["id"]}}"
}
```

#### Node 5: IF - Check REST
- Name: **Check if REST needed**
- Condition: String
- Value1: `{{$json["decision"]["decision"]}}`
- Operation: **Equal**
- Value2: `REST`

#### Node 6: IF - Check HIGH Risk
- Name: **Check if HIGH risk**
- Condition: String
- Value1: `{{$json["injury_risk"]["risk_level"]}}`
- Operation: **Equal**
- Value2: `HIGH`

### Step 3: Test the Workflow

1. Click **Execute Workflow** button
2. Check execution results:
   - Should process 7 athletes
   - Each gets autonomous decision
   - Decisions saved to database

### Step 4: Activate

1. Click **Active** toggle in top right
2. Workflow will run daily at 4:00 AM

## 📊 Expected Results

For each athlete, the workflow will:
1. Get latest AISRI score
2. Get injury risk level
3. Calculate training load
4. Make decision: REST | RECOVERY | LIGHT_TRAIN | TRAIN | INTENSIFY
5. Save decision to `ai_decisions` table

## 🎯 Example Decisions

Based on current test data:
- **Athlete 33308fc1** (Muthulakshmi):
  - AISRI: 68
  - Risk: LOW
  - Decision: LIGHT_TRAIN

- **Athlete cf77e535** (KRISHNAKUMAR):
  - AISRI: 52
  - Risk: LOW  
  - Decision: LIGHT_TRAIN

## 🔧 Customization Options

### Add Email Notifications

After "Check if REST needed" or "Check if HIGH risk":
1. Add **Send Email** node
2. Configure SMTP settings
3. Template:
```
Subject: ⚠️ Training Alert for {{$json["full_name"]}}

Decision: {{$json["decision"]["decision"]}}
Reason: {{$json["decision"]["reason"]}}

AISRI Score: {{$json["aisri_score"]}}
Injury Risk: {{$json["injury_risk"]}} ({{$json["injury_risk"]["risk_level"]}})
Training Load: {{$json["training_load"]}}

Recommendation: Take a rest day or reduce training intensity.
```

### Add Slack/Discord Notifications

1. Add **Slack** or **Discord** node
2. Same message template as email

### Log to Spreadsheet

1. Add **Google Sheets** node
2. Append row with: Date, Athlete, Decision, AISRI, Risk, Load

## 🐛 Troubleshooting

### Workflow fails on "List Athletes"
- Check FastAPI server is running: http://localhost:8001
- Test endpoint manually in PowerShell

### "athlete_id not found"
- Check JSON path: `{{$json["id"]}}` 
- Verify Split Out is working correctly

### Database save fails
- Check Supabase credentials in n8n
- Verify `ai_decisions` table exists
- Check RLS policies allow insert

## 📈 Monitoring

View decisions in Supabase:
```sql
SELECT 
    athlete_id,
    decision,
    reason,
    created_at
FROM ai_decisions
ORDER BY created_at DESC
LIMIT 20;
```

## 🎨 Advanced Features

### Multi-decision Types
Add separate paths for:
- REST → Send urgent notification
- HIGH risk → Alert coach immediately
- INTENSIFY → Generate aggressive training plan
- LIGHT_TRAIN → Standard monitoring

### Integration with Training Plans
After decision, trigger:
- Generate Training Plan endpoint
- Update Flutter app via push notification
- Send workout to athlete's calendar

### Analytics Dashboard
Collect decisions over time:
- Track decision patterns
- Correlate with injury outcomes
- Optimize decision thresholds

## ✅ Success Criteria

- ✓ Workflow executes daily at 4:00 AM
- ✓ All 7 athletes processed
- ✓ Decisions saved to database
- ✓ Notifications sent for high-priority cases
- ✓ Zero errors in execution log
