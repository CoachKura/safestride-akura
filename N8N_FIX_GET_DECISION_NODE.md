# 🔧 Fix "Get Decision" Node in n8n

## Problem
The n8n workflow is showing **422 Unprocessable Content** errors because the request body format is incorrect.

## Solution: Fix the "Get Decision" Node Configuration

### Step-by-Step Instructions:

#### 1. Click on the "Get Decision" node in your n8n workflow

#### 2. Configure the HTTP Request Settings:

**Method:** `POST`

**URL:** `http://127.0.0.1:8001/agent/autonomous-decision`

#### 3. Configure the Body:

**Option A - Using "JSON/RAW Parameters":**
- Click on "Body" section
- Select "Body Content Type": **JSON**
- Select: **"JSON/RAW Parameters"**
- In the JSON field, paste:
```json
{
  "athlete_id": "{{ $json.id }}"
}
```

**Option B - Using "keyvalue":**
- Click on "Body" section
- Select "Body Content Type": **JSON**
- Select: **"keyvalue"**
- Click "Add Field"
- Name: `athlete_id`
- Value: `={{ $json.id }}`

**Option C - Using Expression (Simplest):**
- In the body field, switch to "Expression" mode
- Enter:
```javascript
{ "athlete_id": "{{ $json.id }}" }
```

### 4. Important Notes:

✅ **Correct formats:**
- `{{ $json.id }}` (with spaces)
- `{{ $json["id"] }}` (bracket notation)

❌ **Wrong formats:**
- `{{$json.id}}` (no spaces - might not work)
- `{{$json['id']}}` (single quotes - won't work)

### 5. Test the Node

- Click **"Test step"** or **"Execute node"** 
- You should see a successful response:
```json
{
  "status": "success",
  "decision": "LIGHT_TRAIN",
  "reason": "...",
  "aisri_score": 68,
  "injury_risk": {...},
  "training_load": 60.94
}
```

### 6. After Successful Test

- Click **"Execute workflow"** to run the full workflow
- All nodes should now show green checkmarks! ✅

---

## Quick Reference: What the Server Expects

The `/agent/autonomous-decision` endpoint expects:

```json
{
  "athlete_id": "33308fc1-3545-431d-a5e7-648b52e1866c"
}
```

**Not:**
- `{"id": "..."}` ❌
- `{"athlete": "..."}` ❌
- No body at all ❌

The field name **MUST** be `athlete_id` (not just `id`).

---

## What You'll See When It Works

In the PowerShell window running FastAPI, you'll see:
```
INFO:     127.0.0.1:xxxxx - "POST /agent/autonomous-decision HTTP/1.1" 200 OK
```

Instead of:
```
INFO:     127.0.0.1:xxxxx - "POST /agent/autonomous-decision HTTP/1.1" 422 Unprocessable Content
```

---

## Still Having Issues?

Check:
1. FastAPI server is running (PowerShell shows "Uvicorn running on http://127.0.0.1:8001")
2. The "Split Athletes" node is providing the `id` field
3. The expression references `$json.id` (from the previous node)
4. Body Content Type is set to JSON
