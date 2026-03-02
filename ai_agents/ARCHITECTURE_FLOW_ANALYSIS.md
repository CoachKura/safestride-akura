================================================================================
📊 AISRI ARCHITECTURE ANALYSIS - MESSAGE FLOW
================================================================================

## 🔍 CURRENT FLOW (Discovered)

\\\
Telegram/WhatsApp
       ↓
[Communication Agent V2]
   (communication_agent_v2.py)
       ↓
   classify_message()
       ↓
Route to AISRi API:
   • /agent/injury
   • /agent/performance  
   • /agent/training
   • /agent/autonomous
       ↓
[AISRi API Handler V2]
   (aisri_api_handler_v2.py)
       ↓
Database Queries
       ↓
Format Response
       ↓
Telegram Reply
\\\

**Missing Components:**
- ❌ Orchestrator not integrated
- ❌ Safety gates not enforced
- ❌ Token auto-refresh not used
- ❌ GenSpark (AI generation layer) not found

---

## 🎯 DESIRED FLOW (Your Diagram)

\\\
Chat Channel
       ↓
Communication Agent
       ↓
   Orchestrator  ← NEW: Central coordinator
       ↓
     AISRi       ← Score calculation + safety gates
       ↓
   GenSpark      ← AI response generation (needs clarification)
       ↓
    Response
\\\

---

## 🏗️ RECOMMENDED ARCHITECTURE

\\\
Telegram Webhook (/telegram/webhook)
       ↓
[Communication Agent V2]
   • Extract message
   • Classify intent (faq/injury/performance/training/autonomous)
   • Get athlete data
       ↓
[AISRi Orchestrator] ← **INTEGRATE HERE**
   • get_latest_aisri(athlete_id)
   • check_workout_safety(athlete_id, workout_type)
   • get_valid_strava_token(athlete_id) [auto-refresh]
   • calculate_aisri_from_strava(athlete_id)
       ↓
[Safety Gate Enforcement]
   • Check AISRi score thresholds
   • Validate injury risk
   • Verify recovery status
   • Block unsafe recommendations
       ↓
[Response Generation Layer]
   Option A: Existing AISRi API endpoints
   Option B: New GenSpark AI layer (OpenAI/Claude)
   Option C: Hybrid (AISRi logic + AI formatting)
       ↓
[Format & Send]
   • Telegram markdown formatting
   • Add coaching cues
   • Include safety warnings
       ↓
Athlete receives message
\\\

---

## 📝 INTEGRATION POINTS

### 1. Add Orchestrator to Communication Agent

**File**: \communication_agent_v2.py\

\\\python
from orchestrator import AISRiOrchestrator

# Initialize on startup
orchestrator = AISRiOrchestrator()

@app.post('/telegram/webhook')
async def telegram_webhook(request: Request):
    # ... existing message extraction ...
    
    # Use orchestrator instead of direct API calls
    aisri_data = await orchestrator.get_latest_aisri(athlete['id'])
    
    # Check safety before workout recommendations
    if route == 'training':
        safety_check = await orchestrator.check_workout_safety(
            athlete_id=athlete['id'],
            workout_type='moderate',
            intensity='moderate',
            duration_minutes=60
        )
        
        if not safety_check['safe']:
            response_text = f\"\"\"⚠️ *Safety Alert*
            
{safety_check['reason']}

*Recommendation:*
{safety_check['recommendation']}\"\"\"
            send_telegram_message(chat_id, response_text)
            return {'status': 'success'}
    
    # Continue with existing flow...
\\\

### 2. Add Strava Token Auto-Refresh

**File**: \communication_agent_v2.py\

\\\python
# Before any Strava API calls
if athlete['strava_connected']:
    token = await orchestrator.get_valid_strava_token(athlete['id'])
    # Token is guaranteed fresh (auto-refreshed if needed)
\\\

### 3. Integrate Safety Gates

**File**: \isri_api_handler_v2.py\ OR new middleware

\\\python
# Before generating workout recommendation
safety_result = await orchestrator.check_workout_safety(
    athlete_id=athlete_id,
    workout_type=requested_type,
    intensity=intensity,
    duration_minutes=duration
)

if not safety_result['safe']:
    return {
        'blocked': True,
        'reason': safety_result['reason'],
        'recommendation': safety_result['recommendation'],
        'alternative': safety_result.get('alternative_workout')
    }
\\\

---

## ❓ QUESTION: What is GenSpark?

**Not found in codebase.** Possible interpretations:

### Option A: New AI Response Generation Layer
\\\python
class GenSparkAI:
    '''AI-powered response generation using OpenAI/Claude'''
    
    async def generate_response(self, context: Dict) -> str:
        '''
        Takes AISRi data + athlete context
        Returns personalized, coach-like response
        '''
        prompt = f\"\"\"
        You are AISRi, a running coach AI.
        
        Athlete: {context['name']}
        AISRi Score: {context['aisri_score']}
        Recent workouts: {context['recent_activities']}
        
        Generate a motivational, personalized response...
        \"\"\"
        
        response = await openai.chat.completions.create(
            model='gpt-4',
            messages=[{'role': 'system', 'content': prompt}]
        )
        
        return response.choices[0].message.content
\\\

### Option B: Existing AI Engine Components
- \daptive_workout_generator.py\
- \i_engine_agent/workout_generator_agent.py\
- \itness_analyzer.py\

### Option C: Planned Feature
Need clarification on:
- Is GenSpark a new AI layer to add?
- Should it use OpenAI/Claude?
- Or is it a rename of existing components?

---

## ✅ NEXT STEPS

### Immediate (Required for Orchestrator Integration):

1. **Add orchestrator to communication_agent_v2.py**
   - Import and initialize
   - Replace direct API calls
   - Add safety gate checks

2. **Create GenSpark layer** (if it's new AI generation)
   - Define interface
   - Integrate with orchestrator
   - Use OpenAI API (OPENAI_API_KEY already in .env)

3. **Test complete flow**
   - Send test message via Telegram
   - Verify orchestrator coordination
   - Check safety gates trigger
   - Confirm token auto-refresh

### Optional Enhancements:

4. **Add AI-powered responses**
   - Use GPT-4 for personalized coaching cues
   - Format responses with context awareness
   - Include motivational elements

5. **Implement webhook integration**
   - Real-time Strava activity updates
   - Automatic AISRi recalculation
   - Push notifications for training adjustments

---

## 📊 COMPARISON

| Component | Current Status | After Integration |
|-----------|---------------|-------------------|
| Orchestrator | ❌ Not used | ✅ Central coordinator |
| Safety Gates | ❌ Not enforced | ✅ Automatic blocking |
| Token Refresh | ⚠️ Manual | ✅ Automatic (5-min buffer) |
| Strava OAuth | ⚠️ Test code | ✅ Production-ready |
| GenSpark | ❓ Unknown | ❓ Needs clarification |

---

**Do you want me to:**
1. ✅ Integrate orchestrator into communication_agent_v2.py?
2. ✅ Add safety gate enforcement to message flow?
3. ❓ Create GenSpark AI layer (need specs)?
4. ❓ Other modifications?

================================================================================
