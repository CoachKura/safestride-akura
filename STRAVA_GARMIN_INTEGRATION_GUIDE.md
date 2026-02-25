# Strava & Garmin Integration Setup Guide

Complete guide for setting up real-time activity sync with SafeStride AI.

---

## Architecture Overview

```
Strava/Garmin Activity
         ↓
    Webhook Listener
         ↓
  Activity Parser
         ↓
 Match to Assignment
         ↓
Performance Analysis (GIVEN vs RESULT)
         ↓
  Ability Update
         ↓
Generate Next Workout
```

**3 Services Running:**

1. **Main API** (port 8000): Core athlete & workout management
2. **Activity Integration** (port 8001): Webhook listeners for Strava/Garmin
3. **Strava OAuth** (port 8002): Athlete authorization flow

---

## Prerequisites

### 1. Strava Developer Account

1. Go to [Strava API Settings](https://www.strava.com/settings/api)
2. Create new application:
   - **Application Name**: SafeStride AI
   - **Category**: Training
   - **Website**: https://safestride.ai
   - **Authorization Callback Domain**: Your domain (e.g., `api.safestride.ai`)
3. Note down:
   - **Client ID**
   - **Client Secret**

### 2. Garmin Developer Account

1. Go to [Garmin Health API](https://developer.garmin.com/health-api/overview/)
2. Create application
3. Request API access (requires approval)
4. Note down:
   - **Consumer Key**
   - **Consumer Secret**

---

## Environment Configuration

Add to `.env` file in `ai_agents/` directory:

```bash
# Strava OAuth
STRAVA_CLIENT_ID=your_client_id_here
STRAVA_CLIENT_SECRET=your_client_secret_here
STRAVA_REDIRECT_URI=https://api.safestride.ai/strava/callback
STRAVA_VERIFY_TOKEN=SAFESTRIDE_VERIFY_12345

# Garmin API
GARMIN_CONSUMER_KEY=your_consumer_key_here
GARMIN_CONSUMER_SECRET=your_consumer_secret_here

# Webhook URLs (for your reference)
STRAVA_WEBHOOK_URL=https://api.safestride.ai/webhooks/strava
GARMIN_WEBHOOK_URL=https://api.safestride.ai/webhooks/garmin
```

---

## Service Deployment

### Option 1: Local Development

```bash
# Terminal 1: Main API
cd ai_agents
python api_endpoints.py
# Running on http://localhost:8000

# Terminal 2: Activity Integration (Webhooks)
python activity_integration.py
# Running on http://localhost:8001

# Terminal 3: Strava OAuth
python strava_oauth.py
# Running on http://localhost:8002
```

### Option 2: Production Deployment (Railway/Render)

**Procfile:**

```
web: python ai_agents/api_endpoints.py
webhooks: python ai_agents/activity_integration.py
auth: python ai_agents/strava_oauth.py
```

**Railway Configuration:**

- Add all 3 services as separate deployments
- Set environment variables in Railway dashboard
- Enable public URL for webhook service

---

## Strava Integration Setup

### Step 1: Register Webhook Subscription

```bash
# One-time setup - register webhook with Strava
curl -X POST https://www.strava.com/api/v3/push_subscriptions \
  -F client_id=YOUR_CLIENT_ID \
  -F client_secret=YOUR_CLIENT_SECRET \
  -F callback_url=https://api.safestride.ai/webhooks/strava \
  -F verify_token=SAFESTRIDE_VERIFY_12345
```

**Expected Response:**

```json
{
  "id": 12345,
  "resource_state": 2,
  "application_id": YOUR_APP_ID,
  "callback_url": "https://api.safestride.ai/webhooks/strava"
}
```

### Step 2: Verify Webhook

Strava will send GET request to verify:

```
GET /webhooks/strava?hub.mode=subscribe&hub.verify_token=SAFESTRIDE_VERIFY_12345&hub.challenge=abc123
```

Your endpoint responds with:

```json
{ "hub.challenge": "abc123" }
```

### Step 3: List Active Subscriptions

```bash
curl -G https://www.strava.com/api/v3/push_subscriptions \
  -d client_id=YOUR_CLIENT_ID \
  -d client_secret=YOUR_CLIENT_SECRET
```

### Step 4: Test Webhook (Manual)

```bash
# Simulate Strava webhook callback
curl -X POST https://api.safestride.ai/webhooks/strava \
  -H "Content-Type: application/json" \
  -d '{
    "aspect_type": "create",
    "object_type": "activity",
    "object_id": 12345678,
    "owner_id": 987654,
    "subscription_id": 12345,
    "event_time": 1234567890
  }'
```

---

## Garmin Integration Setup

### Step 1: Register Webhook

In Garmin Developer Portal:

1. Go to Application Settings
2. Add Push Notification URL: `https://api.safestride.ai/webhooks/garmin`
3. Enable "Activity Summaries" notifications

### Step 2: Test Webhook

```bash
# Simulate Garmin webhook (format varies based on API version)
curl -X POST https://api.safestride.ai/webhooks/garmin \
  -H "Content-Type: application/json" \
  -d '{
    "activitySummaries": [{
      "activityId": "12345",
      "userId": "user_123",
      "activityType": "running",
      "startTimeGMT": "2026-02-25T10:00:00Z",
      "duration": 3600,
      "distance": 10000,
      "averageHR": 155,
      "maxHR": 175
    }]
  }'
```

---

## Athlete Connection Flow

### Connect Strava to Athlete Account

**1. Generate Authorization Link:**

```python
# In your mobile app or web dashboard
auth_url = f"https://api.safestride.ai/strava/connect?athlete_id={athlete_id}"
# Redirect athlete to this URL
```

**2. Athlete Authorizes:**

- Athlete clicks "Connect with Strava"
- Redirects to Strava authorization page
- Athlete approves (grants read + activity permissions)

**3. Callback Handling:**

- Strava redirects to: `/strava/callback?code=ABC123&state=athlete_123`
- System exchanges code for access token
- Tokens stored in database
- Athlete profile updated with `strava_connected=true`

**4. Verify Connection:**

```bash
curl https://api.safestride.ai/strava/status/athlete_123
```

**Response:**

```json
{
  "athlete_id": "athlete_123",
  "strava_connected": true,
  "strava_athlete_id": 987654,
  "connected_at": "2026-02-25T10:00:00Z",
  "scopes": "read,activity:read,activity:write"
}
```

---

## Activity Sync Workflow

### Automatic Sync (Production)

**When athlete completes workout on Strava:**

1. **Strava sends webhook:**

   ```json
   {
     "aspect_type": "create",
     "object_type": "activity",
     "object_id": 12345678,
     "owner_id": 987654
   }
   ```

2. **System processes (background task):**
   - Fetch full activity from Strava API
   - Parse activity data (distance, pace, HR, splits)
   - Infer workout type (easy, tempo, intervals, long)
   - Find matching assignment (same day, similar distance)
   - **If match found:**
     - Analyze performance (GIVEN vs RESULT)
     - Calculate performance score (0-100)
     - Determine ability change (+/- adjustment)
     - Update athlete progression
     - Generate next workout
   - **If no match:**
     - Log as ad-hoc workout
     - Store in workout_results table

3. **Athlete sees in app:**
   - Performance label (BEST/GREAT/GOOD/FAIR/POOR)
   - Overall score (e.g., 92/100)
   - Ability change (e.g., +1.5)
   - Next workout recommendation

### Manual Sync (Development/Testing)

```python
# Fetch recent activities from Strava
import httpx

athlete_id = "athlete_123"
access_token = "YOUR_ACCESS_TOKEN"

async with httpx.AsyncClient() as client:
    response = await client.get(
        "https://www.strava.com/api/v3/athlete/activities",
        headers={"Authorization": f"Bearer {access_token}"},
        params={"per_page": 10}
    )
    activities = response.json()

    # Process each activity
    for activity in activities:
        # Convert to workout result format
        workout_result = {
            "workout_id": f"STRAVA_{activity['id']}",
            "completed_date": activity['start_date'],
            "distance_km": activity['distance'] / 1000,
            "total_time_seconds": activity['moving_time'],
            "avg_pace_seconds": int(activity['moving_time'] / (activity['distance'] / 1000)),
            "avg_hr": activity.get('average_heartrate'),
            "max_hr": activity.get('max_heartrate'),
            "completed_full": True
        }

        # Process through database integration
        # (find assignment, analyze, update ability)
```

---

## Workout Type Inference

System automatically detects workout type from activity data:

**Detection Rules:**

1. **Keywords in Activity Name:**
   - "easy", "recovery", "shake" → **Easy**
   - "tempo", "threshold", "marathon pace" → **Tempo**
   - "interval", "repeat", "speed", "track" → **Intervals**
   - "long", "LSD", "endurance" → **Long**

2. **Distance-Based:**
   - > 16 km → **Long**

3. **Pace Variance (from splits):**
   - High variance (>15%) → **Intervals**

4. **Default:** Easy run

**Override:** Athletes can manually adjust workout type in the app.

---

## Monitoring & Debugging

### Check Webhook Subscriptions

```bash
# Strava
curl -G https://www.strava.com/api/v3/push_subscriptions \
  -d client_id=$STRAVA_CLIENT_ID \
  -d client_secret=$STRAVA_CLIENT_SECRET

# Expected: List of active subscriptions
```

### View Recent Webhook Events

```bash
# Check application logs
tail -f logs/activity_integration.log

# Look for:
# ✅ Processed Strava activity 12345678
# ❌ Error processing activity: ...
```

### Test Individual Components

**1. Test Webhook Listener:**

```bash
curl -X POST http://localhost:8001/webhooks/strava \
  -H "Content-Type: application/json" \
  -d '{"aspect_type":"create","object_type":"activity","object_id":12345678,"owner_id":987654}'
```

**2. Test OAuth Flow:**

```bash
# Open in browser
http://localhost:8002/strava/connect?athlete_id=test_123
```

**3. Test Activity Fetch:**

```python
# Python script
import httpx
import asyncio

async def test_fetch():
    client = httpx.AsyncClient()
    response = await client.get(
        "https://www.strava.com/api/v3/activities/12345678",
        headers={"Authorization": "Bearer YOUR_ACCESS_TOKEN"}
    )
    print(response.json())

asyncio.run(test_fetch())
```

---

## Troubleshooting

### Issue: Webhook not receiving events

**Symptoms:** No POST requests to `/webhooks/strava`

**Solutions:**

1. Verify subscription is active:
   ```bash
   curl -G https://www.strava.com/api/v3/push_subscriptions \
     -d client_id=$STRAVA_CLIENT_ID \
     -d client_secret=$STRAVA_CLIENT_SECRET
   ```
2. Check webhook URL is publicly accessible
3. Verify SSL certificate (Strava requires HTTPS)
4. Check firewall/security group settings

### Issue: Token expired errors

**Symptoms:** `401 Unauthorized` from Strava API

**Solutions:**

1. System should auto-refresh tokens (check `strava_oauth.py`)
2. Manually refresh:
   ```python
   await strava_oauth.refresh_access_token(athlete_id)
   ```
3. If refresh fails, athlete needs to re-authorize

### Issue: Activities not matched to assignments

**Symptoms:** All activities logged as "ad-hoc"

**Solutions:**

1. Check date matching (activity within 24 hours of assignment)
2. Verify distance tolerance (15% default)
3. Ensure assignment status is "assigned" not "completed"
4. Check athlete_id mapping (Strava ID → SafeStride ID)

### Issue: Performance scores incorrect

**Symptoms:** All workouts showing BEST/POOR incorrectly

**Solutions:**

1. Verify workout type inference is correct
2. Check assignment target pace/HR values
3. Review performance_tracker.py scoring logic
4. Validate activity data quality (missing HR, pace)

---

## Security Considerations

### Webhook Signature Verification

**Strava:** Uses verify_token (validated on subscription creation)

**Garmin:** Uses OAuth 1.0 signatures

- Implement signature verification in `_verify_garmin_signature()`
- Reject requests with invalid signatures

### Token Storage

- Access tokens stored encrypted in database
- Refresh tokens only accessible server-side
- Never expose tokens in client responses
- Rotate tokens on security incidents

### Rate Limiting

Strava API limits:

- 100 requests per 15 minutes
- 1000 requests per day

Implement retry logic with exponential backoff.

---

## Production Checklist

- [ ] Strava app created and approved
- [ ] Garmin app created and approved
- [ ] Webhook subscriptions registered
- [ ] Environment variables set in production
- [ ] Services deployed and running
- [ ] SSL certificates configured
- [ ] Webhook signature verification enabled
- [ ] Token refresh automation tested
- [ ] Rate limiting implemented
- [ ] Monitoring/alerting configured
- [ ] Error handling and logging
- [ ] Activity sync tested end-to-end
- [ ] Performance analysis validated
- [ ] Ability progression working correctly

---

## API Endpoints Reference

### Strava OAuth

| Endpoint                      | Method | Description                |
| ----------------------------- | ------ | -------------------------- |
| `/strava/connect`             | GET    | Initiate Strava connection |
| `/strava/callback`            | GET    | OAuth callback handler     |
| `/strava/disconnect`          | POST   | Disconnect Strava          |
| `/strava/status/{athlete_id}` | GET    | Check connection status    |

### Activity Webhooks

| Endpoint           | Method | Description             |
| ------------------ | ------ | ----------------------- |
| `/webhooks/strava` | POST   | Strava activity webhook |
| `/webhooks/strava` | GET    | Webhook verification    |
| `/webhooks/garmin` | POST   | Garmin activity webhook |

### Main API (port 8000)

See `api_endpoints.py` for full list (13 endpoints).

---

## Next Steps

1. **Development:**
   - Test locally with ngrok for webhook testing
   - Use Strava's webhook test events
   - Validate all edge cases (missing data, failed matches)

2. **Staging:**
   - Deploy to staging environment
   - Connect test athlete accounts
   - Monitor webhook processing logs
   - Verify token refresh automation

3. **Production:**
   - Submit apps for Strava/Garmin review
   - Configure production domains
   - Set up monitoring and alerting
   - Launch with pilot athletes
   - Monitor performance and errors
   - Iterate based on feedback

---

## Support & Resources

- **Strava API Docs**: https://developers.strava.com/docs/
- **Garmin Health API**: https://developer.garmin.com/health-api/
- **SafeStride Docs**: See `PRODUCTION_ROADMAP.md`

**Questions?** Check logs or contact the development team.

---

**Last Updated:** February 25, 2026
**Version:** 1.0.0
